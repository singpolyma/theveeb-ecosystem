
# Keep track of where we are and where we've been.
sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Set up what goes into this target
SRCS_$(d)       := $(d)/md5.c
SRCS_$(d)       := $(SRCS_$(d)) $(d)/md5main.c

OBJS_$(d)       := $(SRCS_$(d):%.c=%.o)
TGTS_$(d)       := $(d)/md5$(BINSUFFIX)
CLEAN_$(d)      := $(OBJS_$(d)) $(TGTS_$(d))

.PHONY:         targets_$(d) install_$(d)
$(TGTS_$(d)):   $(OBJS_$(d))
targets_$(d):   $(TGTS_$(d))
install_$(d):   $(TGTS_$(d))
	mkdir -p "$(prefix)/bin"
	cp -vp "$^" "$(prefix)/bin/"

# Arrange for this target to be part of a global build
CLEAN           := $(CLEAN) $(CLEAN_$(d))
targets:        targets_$(d)
install:        install_$(d)

# Keep track of where we are and where we've been
d               := $(dirstack_$(sp))
sp              := $(basename $(sp))

