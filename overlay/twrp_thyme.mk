#
# OrangeFox Recovery Product Makefile for Xiaomi 10S (thyme)
# Based on the OrangeFox marble device tree format
#

# Define hardware platform
PRODUCT_RELEASE_NAME := thyme

# Device path for OEM device tree
DEVICE_PATH := device/xiaomi/$(PRODUCT_RELEASE_NAME)

# Inherit from hardware-specific part of the product configuration
$(call inherit-product, $(DEVICE_PATH)/device.mk)

# Inherit any OrangeFox-specific settings (optional, if fox_thyme.mk exists)
$(call inherit-product-if-exists, $(DEVICE_PATH)/fox_$(PRODUCT_RELEASE_NAME).mk)

# Inherit common TWRP/OrangeFox stuff
# Note: In the OrangeFox source tree, vendor/twrp/config/common.mk
# is replaced by OrangeFox's own version
$(call inherit-product, vendor/twrp/config/common.mk)

# Device identifier. This must come after all inclusions
PRODUCT_DEVICE := $(PRODUCT_RELEASE_NAME)
PRODUCT_NAME := twrp_$(PRODUCT_RELEASE_NAME)
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := M2102J2SC
PRODUCT_MANUFACTURER := xiaomi
