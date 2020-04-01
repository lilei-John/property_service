#
#    1.  Base on android-4.3.1_r1
#    2.  Compiled with NDK androideabi gcc 4.8 and platform/android-18
# 
#    platform/system/extras
#    platform/system/core
#    platform/external/libselinux 
#    platform/bionic

#NDK_CROSS_COMPILE ?= arm-linux-androideabi-
NDK_CROSS_COMPILE ?= arm-none-linux-gnueabihf-
GCC ?= $(NDK_CROSS_COMPILE)gcc
STRIP ?= $(NDK_CROSS_COMPILE)strip



LIBS := -ldl -lpthread
C_FLAGS := -O2 -march=armv7-a 
C_FLAGS += -DHAVE_SCHED_H=1 -DHAVE_SYS_SOCKET_H=1 -DHAVE_DIRENT_D_TYPE=0
#C_FLAGS += -Wshadow -Wwrite-strings -Wundef -Wstrict-prototypes -Wunused-function -Wno-format-security -Wdeclaration-after-statement -Wold-style-definition
C_FLAGS += -fomit-frame-pointer -fno-strict-aliasing -ffunction-sections -fdata-sections -fPIC -DPIC
#C_FLAGS += --sysroot=$(NDK_SYSROOT)


LDFLAGS := -static -Wl,--gc-sections 
LIB_LDFLAGS := -O2 -Bdirect -Wl,--hash-style=gnu
#LDFLAGS += --sysroot=$(NDK_SYSROOT) -DANDROID

#    The features here that are not enabled may need to fix compile error if they are enabled
MINIT_ENABLE_WATCHDOGD  ?= 0
MINIT_ENABLE_KEYCHORD   ?= 0
MINIT_ENABLE_SELINUX    ?= 0
MINIT_ENABLE_LOGO       ?= 0
MINIT_ENABLE_SIGNAL     ?= 1

C_SRCS := \
	core/init/builtins.c \
	core/init/init.c \
	core/init/property_service.c \
	core/init/util.c \
	core/init/parser.c \
	core/init/init_parser.c \
	core/init/dynarray.c \
	bionic/libc/system_properties.c

### signal
ifeq ($(MINIT_ENABLE_SIGNAL), 1)	
C_SRCS += \
	core/init/signal_handler.c \
	
C_FLAGS += -DMINIT_ENABLE_SIGNAL=1
endif

### libcutils	
C_SRCS += \
    core/libcutils/list.c \
    core/libcutils/multiuser.c \

libselinux_DISABLED_FILES :=\
	core/init/selinux_DISABLED.c \
	
ifeq ($(MINIT_ENABLE_SELINUX), 1)
C_SRCS +=  $(libselinux_SRC_FILES) $(libselinux_HOST_FILES)

C_FLAGS += -DMINIT_ENABLE_SELINUX=1 -DHOST	
else
C_SRCS +=  $(libselinux_DISABLED_FILES)
endif

SPS_LIB_C_SRCS += \
	core/libcutils/properties.c



SPS_LIB_C_SRCS += \
	bionic/libc/system_properties.c


SPS_C_SRCS := \
	core/toolbox.c \
	core/setprop.c \
	core/getprop.c \
	core/init/dynarray.c
	


C_OBJS := $(patsubst %.c, %.c.o,  $(C_SRCS))
S_OBJS := $(patsubst %.S, %.s.o,  $(S_SRCS))

SPS_LIB_C_OBJS := $(patsubst %.c, %.c.o,  $(SPS_LIB_C_SRCS))
SPS_LIB_S_OBJS := $(patsubst %.S, %.s.o,  $(SPS_LIB_S_SRCS))

SPS_C_OBJS := $(patsubst %.c, %.c.o,  $(SPS_C_SRCS))
SPS_S_OBJS := $(patsubst %.S, %.s.o,  $(SPS_S_SRCS))

INCLUDES := -Icore/include
INCLUDES += -Icore/init
INCLUDES += -Ibionic/libc/include




.PHONY: clean

all: property_service libsps.so sps


clean:
	@rm -Rf $(C_OBJS)
	@rm -Rf $(S_OBJS)
	@rm -Rf $(SPS_LIB_C_OBJS)
	@rm -Rf $(SPS_LIB_S_OBJS)
	@rm -Rf $(SPS_C_OBJS)
	@rm -Rf $(SPS_S_OBJS)
	@rm -Rf property_service property_service_unstrip libsps.so libsps.a sps

property_service_unstrip: $(C_OBJS) $(S_OBJS)
	$(GCC) $(LDFLAGS) -o property_service_unstrip $(C_OBJS) $(S_OBJS)
	
property_service: property_service_unstrip
	$(STRIP) -s -d --strip-unneeded property_service_unstrip -o property_service

%.c.o : %.c
	@mkdir -p $(dir $@)
	@echo "CC $<"
	@$(GCC) $(C_FLAGS) $(INCLUDES) -c $< -o $@
	
%.s.o : %.S
	@mkdir -p $(dir $@)
	@echo "AS $<"
	@$(GCC) $(C_FLAGS) $(INCLUDES) -c $< -o $@

libsps.so: $(SPS_LIB_C_OBJS)
	@echo "LIB     $@"
	@mkdir -p $(dir $@)
	@$(GCC) -shared $(LIB_LDFLAGS) -o $@ $(SPS_LIB_C_OBJS) ${LIBS}
	@$(AR) rcs libsps.a $(SPS_LIB_C_OBJS)
sps: libsps.so $(SPS_C_OBJS) 
	@echo "BIN     $@"
	@$(GCC) $(SPS_LDFLAGS) -o $@ $(SPS_C_OBJS) -L./ ${LIBS} -lsps	
