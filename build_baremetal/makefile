-include build.mk
-include config.mk


INC_DIR := include/lib include/plat/$(PLATFORM)
LIB_SRC_DIR := lib plat/$(PLATFORM)
IMG_SRC_DIR := main
BUILD_DIR := out


.PHONY: all clean
all: test
	$(QUIET)$(ECHO) make $@ done.

clean: test_clean
	$(QUIET)$(RM) -rf $(BUILD_DIR)
	$(QUIET)$(ECHO) make $@ done.

libtest: CFLAGS += $(addprefix -I, $(INC_DIR))
$(call build-static-lib,libtest,$(LIB_SRC_DIR),$(BUILD_DIR))

$(call build-lds,lds-test,plat/$(PLATFORM)/link.lds.P,$(BUILD_DIR)/test/link.lds)

test: CFLAGS += $(addprefix -I, $(INC_DIR))
test: LDFLAGS += -T$(BUILD_DIR)/test/link.lds -L$(BUILD_DIR)/libtest -ltest
$(call build-image,test,$(IMG_SRC_DIR),$(BUILD_DIR),libtest lds-test)
