# OrangeFox Recovery 构建项目 — 小米 10S (thyme)

> 会话交接文档 · 更新于 2026-09-07

## 项目目标

通过 GitHub Actions 为小米 10S（代号 `thyme`）构建 OrangeFox Recovery 镜像。

## 关键环境信息

| 项目 | 内容 |
|------|------|
| 设备 | Xiaomi 10S (thyme)，SM8250 (kona)，A/B 设备，boot header v3，预编译内核 |
| 源码 | OrangeFox fox_12.1 分支（GitLab），通过 `orangefox_sync.sh` 同步 |
| 设备树 | 基于 `Samuioto/twrp_device_thyme`（TWRP 树），用 overlay 方式适配 OrangeFox |
| 仓库 | `https://github.com/SWDaby/thyme-orangefox.git` |
| CI | GitHub Actions ubuntu-latest（16GB RAM + 24GB swap，`jlumbroso/free-disk-space` 清理后约 60GB 可用） |
| 本地路径 | `D:\YS\thyme-orangefox` |

### 重要注意事项

- **输出路径是双重嵌套的**：`out/target/product/thyme/target/product/thyme/`
- **thyme 无独立 recovery 分区**，recovery 镜像刷入 boot 分区：`fastboot flash boot_a OrangeFox-unofficial-thyme.img`
- **不能删 `prebuilts/` 目录**（会破坏 bionic/clang-builtins 依赖）
- **`FOX_BUILD_DEVICE=thyme` 必须在 `source build/envsetup.sh` 之前 export**，让 vendorsetup.sh 导出 FOX_* 构建变量
- **`BOARD_RECOVERYIMAGE_PARTITION_SIZE := 100663296`** 是让构建系统创建 recovery.img 的关键变量（之前被注释掉导致 `INSTALLED_RECOVERYIMAGE_TARGET` 为空）
- 构建日志中 `OUT_DIR=/home/runner/.../out/target/product/thyme`，实际产品目录是 `out/target/product/thyme/target/product/thyme/`

## 项目结构

```
thyme-orangefox/
├── .github/workflows/build.yml   # CI 主文件（构建命令在 145-164 行附近）
├── overlay/                       # OrangeFox 适配文件，覆盖到设备树
│   ├── AndroidProducts.mk         # lunch 目标定义
│   ├── twrp_thyme.mk              # OrangeFox 产品 makefile
│   ├── vendorsetup.sh             # FOX_* 构建变量
│   ├── recovery.fstab             # 恢复分区表（加了 dtbo）
│   └── BoardConfig.mk             # TARGET_SUPPORTS_64_BIT_APPS、kryo、分区大小
├── README.md
├── .gitignore
└── .gitattributes
```

## CI 流程（build.yml）

1. `jlumbroso/free-disk-space` 清理磁盘
2. `pierotofy/set-swap-space` 设置 24GB swap
3. 安装构建依赖（OrangeFox `setup/android_build_env.sh`）
4. 同步 OrangeFox 源码（fox_12.1）
5. 删 `.repo` 释放空间（保留 prebuilts）
6. 克隆 TWRP 设备树到 `device/xiaomi/thyme`
7. 应用 overlay（覆盖 TWRP 文件，删除 `omni_thyme.mk`）
8. 构建：`lunch twrp_thyme-eng && mka adbd bootimage recoveryimage`
9. 查找/打包 recovery 镜像 → 上传 artifact 和 release

## 修复历史（按时间顺序）

1. 创建完整项目结构（workflow、overlay、README 等）
2. 修复 32-bit apps 错误（`TARGET_SUPPORTS_64_BIT_APPS`）
3. 修复 prebuilts 依赖破坏（不再删除 prebuilts）
4. 修复磁盘空间不足
5. 修复 vendorsetup.sh lunch 冲突
6. 恢复 `BOARD_RECOVERYIMAGE_PARTITION_SIZE`（关键）
7. 尝试 `ramdisk` / 去掉 `make clean` / `bootimage` 前置 → 全部在同一处失败（`root` 缺失）
8. **定位根因**（2026-09-07，commit `5657bc5` 的 run）：TWRP-only 移植下 generic `root/` 目录为空且从不被创建

## 根因（已确认，非猜测）

- 全产物在双重嵌套路径下：本分支 `OUT_DIR` 解析为 `.../out/target/product/thyme`，
  故 `PRODUCT_OUT = .../out/target/product/thyme/target/product/thyme`。这**是正常的**
  （参考树 marble-OFRP 的 workflow 也从同样的双重路径取 artifact）。
- 失败规则是 AOSP 12.1 `build/make/core/Makefile:2196-2232` 的 `ramdisk_files-timestamp`
  （recoveryimage packaging）。它第一步 `rsync $(TARGET_ROOT_OUT) $(TARGET_RECOVERY_OUT)`，
  把 **generic boot ramdisk 的 `root/` 目录**当作 recovery ramdisk 的基底拷过来。
- 本移植把 recovery 内容全部装在 `recovery/root/` 下（日志里全是 `recovery/root/...` 的 Install），
  **generic `root/` 下没有任何模块安装**，因此该目录从未被创建 → rsync 报
  `link_stat ".../root" failed: No such file or directory`。
- `ramdisk.img`/`boot.img` 能构建成功只是因为它们用的是**空目录**（file-list 规则会先 `mkdir`），
  并不代表 `root/` 存在。`bootimage` 前置没有帮助（本次 run 即 `mka adbd bootimage recoveryimage`，同样失败）。

## 当前修复（新 fix，待推送）

`root/` 只需**存在且为空**即可 —— rsync 空源是 no-op，之后同一规则里的
res/fonts/设备 overlay/`OrangeFox_A12.sh` 步骤仍会正常组装 recovery ramdisk。故在 `lunch` 之后 `mka` 之前：

```bash
mkdir -p "${ANDROID_PRODUCT_OUT}/root"
mka adbd recoveryimage
```

（`ANDROID_PRODUCT_OUT` 由 `lunch` 导出，即上述双重嵌套的 PRODUCT_OUT。
同时去掉不再需要的 `bootimage` 目标，`recoveryimage` 自身会依赖并构建 `ramdisk.img`。）

### 不再采用的方案（已排除）

1. `BOARD_USES_RECOVERY_AS_BOOT := true` — 曾导致 `INSTALLED_RECOVERYIMAGE_TARGET` 为空
2. `bootimage` / `ramdisk` 前置 — 均不能创建空的 generic `root/`（本次 run 已证实）

## 下一步

1. 推送新 fix，跑一次 workflow_dispatch 验证
2. **若成功**：下载 artifact，刷入 `fastboot flash boot_a OrangeFox-unofficial-thyme.img`
3. **若仍失败**：贴日志，检查 recovery/root 是否在 `ramdisk_files-timestamp` 前被完整填充
   （重点确认 `recovery`/`twrp` 二进制确实进入 ramdisk）

## 相关链接

- 本仓库：https://github.com/SWDaby/thyme-orangefox.git
- 原 TWRP 设备树：https://github.com/Samuioto/twrp_device_thyme
- 参考的 OrangeFox 设备树（marble）：https://github.com/kinguser981/android_device_xiaomi_marble-OFRP
- OrangeFox GitLab：https://gitlab.com/OrangeFox
