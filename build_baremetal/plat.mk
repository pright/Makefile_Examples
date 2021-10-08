mips_PREFIX := mipsel-linux-
mips_CFLAGS := -DPLAT_MIPS -march=mips32r2 -mtune=24kef -EL -G 0 -mno-gpopt -mno-shared -mno-abicalls
mips_LDFLAGS := -EL -G 0

arm_PREFIX := arm-linux-gnueabihf-
arm_CFLAGS := -DPLAT_ARM -march=armv7ve -mno-unaligned-access

PLATFORM := arm
