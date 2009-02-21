
# Keep track of where we are and where we've been.
sp              := $(sp).x
dirstack_$(sp)  := $(d)
d               := $(dir)

# Pull in rules for subdirectories
dir             := $(d)/search
include         $(dir)/Rules.mk
dir             := $(d)/update
include         $(dir)/Rules.mk
dir             := $(d)/depends
include         $(dir)/Rules.mk
dir             := $(d)/md5
include         $(dir)/Rules.mk


# Keep track of where we are and where we've been
d               := $(dirstack_$(sp))
sp              := $(basename $(sp))

