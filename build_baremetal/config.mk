CONFIG_DEBUG := 1

ifeq ($(CONFIG_DEBUG), 1)
CFLAGS += -DDEBUG -g
else
CFLAGS += -g
endif
