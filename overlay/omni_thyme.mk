#
# OrangeFox Recovery Product Makefile for Xiaomi 10S (thyme)
# Minimal Fox-style product (inherits Fox's TWRP common + device.mk only).
# Keeps the MinecraftVM tree's product NAME (omni_thyme) so lunch omni_thyme-eng works.
#

# Define hardware platform
PRODUCT_RELEASE_NAME := thyme

# Device path for OEM device tree
DEVICE_PATH := device/xiaomi/$(PRODUCT_RELEASE_NAME)

# Inherit from hardware-specific part of the product configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Inherit common TWRP/OrangeFox stuff
$(call inherit-product, vendor/twrp/config/common.mk)

# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := $(PRODUCT_RELEASE_NAME)
PRODUCT_NAME := omni_$(PRODUCT_RELEASE_NAME)
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := M2102J2SC
PRODUCT_MANUFACTURER := xiaomi
