
include build-config.mk

all:    targets
#all:   tests
#all:   objs
#all:   outputs

dir             := .
include         Rules.mk

.PHONY: targets clean distclean
 
clean:
	$(RM) $(CLEAN)

distclean: clean
