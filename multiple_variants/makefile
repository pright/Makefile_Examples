SRCDIR=src
debug_OBJDIR=build/debug
release_OBJDIR=build/release

SRC=$(wildcard $(SRCDIR)/*.c)
debug_OBJS=$(addprefix $(debug_OBJDIR)/, $(notdir $(SRC:%.c=%.o)))
release_OBJS=$(addprefix $(release_OBJDIR)/, $(notdir $(SRC:%.c=%.o)))
OBJS=$(debug_OBJS) $(release_OBJS)


.PHONY: all
all: debug release
	@echo "make all."

.SECONDEXPANSION:
.PHONY: debug release
debug: CFLAGS=-O0 -g
release: CFLAGS=-O2
debug release: $$($$@_OBJS)
	@$(AR) rcs lib$(shell echo $@ | tr '[A-Z]' '[a-z]' ).a $^
	@echo "make "$@"."

$(OBJS): %.o: $$(addprefix $(SRCDIR)/, $$(notdir %.c))
	$(CC) -c $(CFLAGS) -MMD -c -o $@ $<

.PHONY: clean
clean:
	@find . -name "*.[oad]" -delete

-include $(addprefix $(debug_OBJDIR)/, $(notdir $(SRC:%.c=%.d)))
-include $(addprefix $(release_OBJDIR)/, $(notdir $(SRC:%.c=%.d)))
