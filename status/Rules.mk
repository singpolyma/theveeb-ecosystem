
# Keep track of where we are and where we've been.
sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Set up what goes into this target
SRCS_$(d)       := $(d)/status.c
SRCS_$(d)       := $(SRCS_$(d)) common/version_compare.c
SRCS_$(d)       := $(SRCS_$(d)) common/get_paths.c
ifeq ($(TARGET),win32)
SRCS_$(d)       := $(SRCS_$(d)) common/getopt.c
endif

OBJS_$(d)       := $(SRCS_$(d):%.c=%.o)
TGTS_$(d)       := $(d)/status$(BINSUFFIX)
CLEAN_$(d)      := $(OBJS_$(d)) $(TGTS_$(d))

$(TGTS_$(d)):   LL_TGT+=-lsqlite3

.PHONY:         targets_$(d) install_$(d)
$(TGTS_$(d)):   $(OBJS_$(d))
targets_$(d):   $(TGTS_$(d))
install_$(d):   $(TGTS_$(d))
	mkdir -p "$(prefix)/bin"
	@for BIN in $^; do cp -vp "$$BIN" "$(prefix)/bin/tve-`basename $$BIN`"; "$(STRIP)" "$(prefix)/bin/tve-`basename $$BIN`"; done

# Arrange for this target to be part of a global build
CLEAN           := $(CLEAN) $(CLEAN_$(d))
targets:        targets_$(d)
install:        install_$(d)

# Keep track of where we are and where we've been
d               := $(dirstack_$(sp))
sp              := $(basename $(sp))

