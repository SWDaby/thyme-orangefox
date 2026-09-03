# OrangeFox Recovery for Xiaomi 10S (thyme)

使用 GitHub Actions 为小米 10S (thyme) 构建 OrangeFox Recovery。

## 项目结构

```
.
├── .github/workflows/
│   └── build.yml              # GitHub Actions 构建工作流
├── overlay/                   # OrangeFox 适配的设备树文件（覆盖 TWRP 原版）
│   ├── AndroidProducts.mk     # 引用 twrp_thyme.mk（替代 omni_thyme.mk）
│   ├── twrp_thyme.mk         # OrangeFox 产品 makefile
│   ├── vendorsetup.sh         # OrangeFox 构建变量
│   └── recovery.fstab         # 添加了 dtbo 分区
└── README.md
```

## 工作原理

1. 工作流克隆 [Samuioto/twrp_device_thyme](https://github.com/Samuioto/twrp_device_thyme) 获取完整设备树（含预编译内核等二进制文件）
2. 用 `overlay/` 目录中的 OrangeFox 适配文件覆盖 TWRP 文本文件
3. 同步 OrangeFox 源码树（fox_12.1 分支）
4. 构建 recovery 镜像
5. 上传为 GitHub Release 和 Artifact

## 使用方法

### 1. 创建 GitHub 仓库

将此项目推送到你的 GitHub 仓库：

```bash
cd D:\YS\thyme-orangefox
git init
git add .
git commit -m "OrangeFox recovery build for Xiaomi 10S (thyme)"
git branch -M main
git remote add origin https://github.com/<你的用户名>/thyme-orangefox.git
git push -u origin main
```

### 2. 运行构建

1. 在 GitHub 仓库页面点击 **Actions** 标签
2. 选择 **Build OrangeFox for Xiaomi 10S (thyme)** 工作流
3. 点击 **Run workflow**
4. 选择参数：
   - **Manifest branch**: `12.1`（推荐）或 `11.0`
   - **Build target**: `recovery`（默认）
5. 点击 **Run workflow** 开始构建

### 3. 下载结果

构建完成后（约 2-4 小时）：

- **Artifact**: 在 Actions 运行页面下载（保留 30 天）
- **Release**: 在仓库 Releases 页面下载

文件名: `OrangeFox-unofficial-thyme.img`（重命名为 `recovery.img`）

## 刷入方法

```bash
# 进入 fastboot 模式
adb reboot bootloader

# 刷入两个槽位
fastboot flash recovery_a recovery.img
fastboot flash recovery_b recovery.img

# 重启到 recovery
fastboot reboot recovery
```

## 构建参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `manifest_branch` | OrangeFox 源码分支 | `12.1` |
| `build_target` | 构建目标分区 | `recovery` |

## thyme 设备特性

- **代号**: thyme
- **型号**: M2102J2SC (Xiaomi 10S)
- **平台**: SM8250 (kona)
- **架构**: arm64-v8a
- **A/B 设备**: 是
- **动态分区**: 是（super 分区）
- **Virtual A/B**: 是
- **Keymaster 版本**: 4.1
- **Boot header 版本**: 3
- **预编译内核**: 是

## OrangeFox 构建变量

在 `overlay/vendorsetup.sh` 中配置的 OrangeFox 变量：

| 变量 | 说明 |
|------|------|
| `FOX_AB_DEVICE=1` | A/B 设备 |
| `FOX_VIRTUAL_AB_DEVICE=1` | Virtual A/B 设备 |
| `OF_DEFAULT_KEYMASTER_VERSION=4.1` | Keymaster 版本 |
| `OF_FORCE_PREBUILT_KERNEL=1` | 使用预编译内核 |
| `FOX_USE_TWRP_RECOVERY_IMAGE_BUILDER=1` | 使用 TWRP 镜像构建器 |
| `FOX_USE_BASH_SHELL=1` | 使用 bash shell |
| `FOX_ASH_IS_BASH=1` | ash 链接到 bash |
| `FOX_REPLACE_BUSYBOX_PS=1` | 替换 busybox ps |
| `FOX_REPLACE_TOOLBOX_GETPROP=1` | 替换 toolbox getprop |
| `FOX_USE_TAR_BINARY=1` | 使用 tar 二进制 |
| `FOX_USE_XZ_UTILS=1` | 使用 xz 压缩 |
| `FOX_USE_SED_BINARY=1` | 使用 sed 二进制 |
| `FOX_USE_NANO_EDITOR=1` | 使用 nano 编辑器 |
| `FOX_ENABLE_APP_MANAGER=1` | 启用应用管理器 |
| `FOX_DELETE_AROMAFM=1` | 删除 AROMA FM |
| `FOX_DELETE_INITD_ADDON=1` | 删除 init.d 插件 |

## 系统要求 (GitHub Actions)

| 资源 | GitHub Actions Runner | 说明 |
|------|----------------------|------|
| 磁盘 | ~60GB（清理后） | fox_12.1 需 ~45GB |
| 内存 | 16GB + 24GB Swap | 勉强够用 |
| 超时 | 6 小时 | 构建约 2-4 小时 |
| 免费额度 | 2000 分钟/月 | 每次构建约 200-300 分钟 |

## 已知问题

- **磁盘空间紧张**: GitHub Actions runner 磁盘有限，已用 `slimhub_actions` 清理
- **首次构建较慢**: 无 ccache 缓存，首次构建可能接近超时
- **解密问题**: 如构建后 recovery 无法解密 data，可能需要调整设备树中的 keymaster 配置
- **内核问题**: 使用的是 Samuioto 仓库中的预编译内核，可能不适用于最新固件的解密

## 致谢

- [OrangeFox Recovery Project](https://gitlab.com/OrangeFox) - OrangeFox 源码
- [Samuioto](https://github.com/Samuioto/twrp_device_thyme) - thyme TWRP 设备树
- [kinguser981](https://github.com/kinguser981/OrangeFox-Recovery-Builder-2024) - GitHub Actions 构建模板

## GPL 许可

OrangeFox 基于 GPL v3 许可。如果你公开发布此构建，必须同时公开发布所有修改过的源码。
