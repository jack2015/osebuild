include config.mk

LOCAL_PATH := $(DIR)/$(PCSC_LITE)

include $(CLEAR_VARS)
LOCAL_MODULE := libusb1.0_static
LOCAL_SRC_FILES := $(LOCAL_PATH)/../usr/lib/$(TARGET_PLATFORM)/$(TARGET_ARCH_ABI)/libusb1.0_static.a
include $(PREBUILT_STATIC_LIBRARY)

local_c_includes := \
		$(LOCAL_PATH) \
		$(LOCAL_PATH)/src \
		$(LOCAL_PATH)/src/PCSC \
		$(LOCAL_PATH)/../usr/include/libusb-1.0

local_cflags := -Wall -fno-common -g -O2 -DHAVE_CONFIG_H -DSIMCLIST_NO_DUMPRESTORE

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(local_c_includes)

LOCAL_SRC_FILES := \
		src/debug.c \
		src/error.c \
		src/winscard_clnt.c \
		src/simclist.c \
		src/sys_unix.c \
		src/utils.c \
		src/winscard_msg.c \
		src/spy/libpcscspy.c

LOCAL_MODULE := libpcsclite_static
LOCAL_CFLAGS := $(local_cflags) -DLIBPCSCLITE

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_C_INCLUDES := $(local_c_includes)

LOCAL_SRC_FILES := \
	src/auth.c \
	src/atrhandler.c \
	src/configfile.c \
	src/debuglog.c \
	src/dyn_hpux.c \
	src/dyn_macosx.c \
	src/dyn_unix.c \
	src/eventhandler.c \
	src/hotplug_generic.c \
	src/ifdwrapper.c \
	src/pcscdaemon.c \
	src/prothandler.c \
	src/readerfactory.c \
	src/simclist.c \
	src/sys_unix.c \
	src/tokenparser.c \
	src/hotplug_libudev.c \
	src/hotplug_libusb.c \
	src/hotplug_linux.c \
	src/hotplug_macosx.c \
	src/utils.c \
	src/winscard.c \
	src/winscard_msg.c \
	src/winscard_msg_srv.c \
	src/winscard_svc.c

LOCAL_MODULE := pcscd
LOCAL_LDLIBS := -lm -ldl
LOCAL_LDFLAGS := -llog
LOCAL_STATIC_LIBRARIES := libusb1.0_static
LOCAL_CFLAGS := $(local_cflags) -DPCSCD

include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

LOCAL_MODULE := testpcsc
LOCAL_SRC_FILES := src/testpcsc.c
LOCAL_C_INCLUDES := $(local_c_includes)
LOCAL_CFLAGS := $(local_cflags)
LOCAL_STATIC_LIBRARIES := libpcsclite_static

include $(BUILD_EXECUTABLE)
