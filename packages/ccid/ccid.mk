include config.mk

LOCAL_PATH := $(DIR)/$(CCID)

include $(CLEAR_VARS)
LOCAL_MODULE := libusb1.0_static
LOCAL_SRC_FILES := $(LOCAL_PATH)/../usr/lib/$(TARGET_PLATFORM)/$(TARGET_ARCH_ABI)/libusb1.0_static.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := libpcsclite_static
LOCAL_SRC_FILES := $(LOCAL_PATH)/../usr/lib/$(TARGET_PLATFORM)/$(TARGET_ARCH_ABI)/libpcsclite_static.a
include $(PREBUILT_STATIC_LIBRARY)

local_c_includes := \
		$(LOCAL_PATH) \
		$(LOCAL_PATH)/src \
		$(LOCAL_PATH)/../../packages/ccid \
		$(LOCAL_PATH)/../usr/include/PCSC \
		$(LOCAL_PATH)/../usr/include/libusb-1.0

local_cflags := -DHAVE_CONFIG_H -DSIMCLIST_NO_DUMPRESTORE

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(local_c_includes)

LOCAL_SRC_FILES := \
		src/ccid.c \
		src/commands.c \
		src/ifdhandler.c \
		src/utils.c \
		src/ccid_usb.c \
		src/tokenparser.c \
		src/strlcpy.c \
		src/simclist.c \
		src/debug.c \
		src/towitoko/atr.c \
		src/towitoko/pps.c \
		src/openct/buffer.c \
		src/openct/checksum.c \
		src/openct/proto-t1.c 

LOCAL_MODULE := libccid
LOCAL_CFLAGS := $(local_cflags)
LOCAL_LDLIBS := -llog
LOCAL_STATIC_LIBRARIES := libusb1.0_static libpcsclite_static

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(local_c_includes)

LOCAL_SRC_FILES := \
		src/ccid.c \
		src/commands.c \
		src/ifdhandler.c \
		src/utils.c \
		src/ccid_serial.c \
		src/tokenparser.c \
		src/strlcpy.c \
		src/simclist.c \
		src/debug.c \
		src/towitoko/atr.c \
		src/towitoko/pps.c \
		src/openct/buffer.c \
		src/openct/checksum.c \
		src/openct/proto-t1.c

LOCAL_MODULE := libccidtwin
LOCAL_CFLAGS := $(local_cflags) -DTWIN_SERIAL -fvisibility=hidden
LOCAL_STATIC_LIBRARIES := libpcsclite_static

include $(BUILD_SHARED_LIBRARY)
