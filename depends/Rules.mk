
# Keep track of where we are and where we've been.
sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Set up what goes into this target
SRCS_$(d)       := $(d)/depends.c $(d)/version_compare.c
SRCS_$(d)       := $(SRCS_$(d)) common/get_paths.c
ifeq ($(TARGET),win32)
SRCS_$(d)       := $(SRCS_$(d)) common/getopt.c
endif

OBJS_$(d)       := $(SRCS_$(d):%.c=%.o)
TGTS_$(d)       := $(d)/depends
CLEAN_$(d)      := $(OBJS_$(d)) $(TGTS_$(d))

.PHONY:         targets_$(d)
$(TGTS_$(d)):   $(OBJS_$(d))
targets_$(d):   $(TGTS_$(d))

# Arrange for this target to be part of a global build
CLEAN           := $(CLEAN) $(CLEAN_$(d))
TOSTRIP         := $(TOSTRIP) $(TGTS_$(d))
targets:        targets_$(d)

# Keep track of where we are and where we've been
d               := $(dirstack_$(sp))
sp              := $(basename $(sp))
