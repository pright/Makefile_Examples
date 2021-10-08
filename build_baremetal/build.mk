-include plat.mk

CROSS_PREFIX := $($(PLATFORM)_PREFIX)
PLAT_CFLAGS := $($(PLATFORM)_CFLAGS)
PLAT_LDFLAGS := $($(PLATFORM)_LDFLAGS)

NO_STDINC := -nostdinc
NO_STDLIB := -nostdlib
NO_PIC := -fno-pic
FREESTANDING := -fno-builtin -ffreestanding
SPLIT_SECTIONS := -ffunction-sections -fdata-sections
GC_SECTIONS := --gc-sections
OPTIMISE := -Os
WARNING := -Werror -Wall -Wextra -Wfatal-errors -Wno-unused-function
#WARNING := -Wall -Wextra -Wfatal-errors
STACK_PROTECT := -fstack-protector-strong

CC := $(CROSS_PREFIX)gcc
LD := $(CROSS_PREFIX)ld
AR := $(CROSS_PREFIX)ar

OBJDUMP := $(CROSS_PREFIX)objdump
OBJCOPY := $(CROSS_PREFIX)objcopy
READELF := $(CROSS_PREFIX)readelf
NM := $(CROSS_PREFIX)nm
SIZE := $(CROSS_PREFIX)size

QUIET := @
ECHO := echo
CD := cd
RM := rm
CP := cp
CAT := cat
MKDIR := mkdir
MAKE := make

CFLAGS := $(PLAT_CFLAGS) $(NO_STDINC) $(FREESTANDING) $(SPLIT_SECTIONS) $(NO_PIC) $(OPTIMISE) $(WARNING) $(STACK_PROTECT)
ASFLAGS = $(CFLAGS)
LDFLAGS := $(PLAT_LDFLAGS) $(NO_STDLIB) $(GC_SECTIONS)

## Find all of the files under the named directories with the specified name.
# $(1): a list of directories.
# $(2): the file name pattern to be passed to find as "-name".
define all-named-files-under
$(sort $(patsubst ./%,%, \
	$(shell find -L $(1) -name $(2) -and -not -name ".*") \
	))
endef

## Find all of the c files under the named directories.
# $(1): a list of directories.
define all-c-files-under
$(call all-named-files-under,$(1),"*.c")
endef

## Find all of the S files under the named directories.
# $(1): a list of directories.
define all-S-files-under
$(call all-named-files-under,$(1),"*.S")
endef

## Find all of the directories under the named directories.
# $(1): a list of directories.
define all-dirs-under
$(sort $(patsubst ./%,%, \
	$(shell find -L $(1) -type d) \
	))
endef

## Generate rules to build image with specified parameters.
## Must be called with $(eval).
# $(1): the build target
# $(2): the source directories
# $(3): the output directory
# $(4): the dependencies (optional)
define _build-image
$(eval $(1)_out := $(3)/$(1))
$(eval $(1)_dirs := $(call all-dirs-under,$(2)))
$(eval $(1)_src-c := $(call all-c-files-under,$(2)))
$(eval $(1)_src-S := $(call all-S-files-under,$(2)))
$(eval $(1)_obj-c := $(subst .c,.o,$($(1)_src-c)))
$(eval $(1)_obj-S := $(subst .S,.o,$($(1)_src-S)))
$(eval $(1)_obj := $(addprefix $($(1)_out)/,$($(1)_obj-c) $($(1)_obj-S)))
$(eval $(1)_deps_build := $(4))
$(eval $(1)_deps_target := $(foreach target,$(addsuffix _target,$(4)),$($(target))))
$(eval $(1)_deps_clean := $(foreach target,$(addsuffix _clean,$(4)),$(target)))
$(eval $(1)_target := $($(1)_out)/$(1).elf)
$(eval $(1)_image := $($(1)_out)/$(1).bin)
.PHONY: $(1) $(1)_clean $(1)_prepare $(1)_prebuild $(1)_mainbuild $(1)_postbuild
$(1): $(1)_prepare $(1)_mainbuild
	$(QUIET)$(ECHO) make $$@ done.

$(1)_prepare:
	$(QUIET)$(MKDIR) -p $$($(1)_out)
	$(QUIET)$(CD) $$($(1)_out) && $(MKDIR) -p $(2) && $(MKDIR) -p $$($(1)_dirs)

$(1)_prebuild: $($(1)_deps_build)

$(1)_mainbuild: $(1)_prebuild $$($(1)_image)
	$(QUIET)$(MAKE) --no-print-directory $(1)_postbuild

$$($(1)_image): $$($(1)_target)
	$(QUIET)$(OBJDUMP) -dS $$^ > $$^-disass.txt
	$(QUIET)$(OBJDUMP) -s $$^ > $$^-section.txt
	$(QUIET)$(SIZE) $$^ > $$^-size.txt
	$(QUIET)$(OBJCOPY) -O binary $$^ $$@

$$($(1)_target): $$($(1)_deps_target) $$($(1)_obj)
	$(LD) $$($(1)_obj) $$(LDFLAGS) -Map=$$@.map -o $$@

$($(1)_out)/%.o: %.c
	$(CC) $$(CFLAGS) -MMD -c -o $$@ $$<

$($(1)_out)/%.o: %.S
	$(CC) $$(ASFLAGS) -MMD -c -o $$@ $$<

$(1)_clean: $($(1)_deps_clean)
	$(QUIET)$(RM) -rf $$($(1)_out)
	$(QUIET)$(ECHO) make $$@ done.

-include $($(1)_obj:%.o=%.d)
endef

## Generate rules to build image with specified parameters.
## Meant to be used like:
##     $(call build-image,target-name,src tests,out))
# $(1): the build target
# $(2): the source directories
# $(3): the output directory
# $(4): the dependencies (optional)
define build-image
$(eval $(call _build-image,$(1),$(2),$(3),$(4)))
endef

## Generate rules to build static library with specified parameters.
## Must be called with $(eval).
# $(1): the build target
# $(2): the source directories
# $(3): the output directory
define _build-static-lib
$(eval $(1)_out := $(3)/$(1))
$(eval $(1)_dirs := $(call all-dirs-under,$(2)))
$(eval $(1)_src-c := $(call all-c-files-under,$(2)))
$(eval $(1)_src-S := $(call all-S-files-under,$(2)))
$(eval $(1)_obj-c := $(subst .c,.o,$($(1)_src-c)))
$(eval $(1)_obj-S := $(subst .S,.o,$($(1)_src-S)))
$(eval $(1)_obj := $(addprefix $($(1)_out)/,$($(1)_obj-c) $($(1)_obj-S)))
$(eval $(1)_target := $($(1)_out)/$(1).a)
.PHONY: $(1) $(1)_clean $(1)_prepare $(1)_prebuild $(1)_mainbuild $(1)_postbuild
$(1): $(1)_prepare $(1)_mainbuild
	$(QUIET)$(ECHO) make $$@ done.

$(1)_prepare:
	$(QUIET)$(MKDIR) -p $$($(1)_out)
	$(QUIET)$(CD) $$($(1)_out) && $(MKDIR) -p $(2) && $(MKDIR) -p $$($(1)_dirs)

$(1)_mainbuild: $(1)_prebuild $$($(1)_target)
	$(QUIET)$(MAKE) --no-print-directory $(1)_postbuild

$$($(1)_target): $$($(1)_obj)
	$(AR) rcs $$@ $$^

$($(1)_out)/%.o: %.c
	$(CC) $$(CFLAGS) -MMD -c -o $$@ $$<

$($(1)_out)/%.o: %.S
	$(CC) $$(ASFLAGS) -MMD -c -o $$@ $$<

$(1)_clean:
	$(QUIET)$(RM) -rf $$($(1)_out)
	$(QUIET)$(ECHO) make $$@ done.

-include $($(1)_obj:%.o=%.d)
endef

## Generate rules to build static library with specified parameters.
## Meant to be used like:
##     $(call build-static-lib,target-name,src tests,out))
# $(1): the build target
# $(2): the source directories
# $(3): the output directory
define build-static-lib
$(eval $(call _build-static-lib,$(1),$(2),$(3)))
endef

## Generate rules to build linker script
## Must be called with $(eval).
# $(1): the build target
# $(2): the template file
# $(3): the output linker script
define _build-lds
$(eval $(1)_target := $(3))
.PHONY: $(1) $(1)_clean
$(1): $$($(1)_target)
	$(QUIET)$(ECHO) make $$@ done.
$$($(1)_target): $(2)
	$(CC) -E $$(CFLAGS) -Wp,-MMD,$$@.d -MT $$@ -x c -P -o $$@ $(2)

-include $($(1)_target:%=%.d)
endef

## Generate rules to build linker script
## Meant to be used like:
##     $(call build-lds,link.lds.P,link.lds))
# $(1): the build target
# $(2): the template file
# $(3): the output linker script
define build-lds
$(eval $(call _build-lds,$(1),$(2),$(3)))
endef

export CROSS_PREFIX CC LD AR OBJDUMP OBJCOPY READELF NM SIZE QUIET ECHO CD RM CP MKDIR MAKE
