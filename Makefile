
include build-config.mk

all:    targets
#all:   tests
#all:   objs
#all:   outputs

dir             := .
include         Rules.mk

.PHONY: all targets clean distclean install install_sh

%$(BINSUFFIX): %.o
	$(CC) $(LDFLAGS) $^ $(LL_ALL) $(LL_TGT) -o $@

install_sh: *.sh
	@for SCRIPT in $^; do install -DTvpm755 "$$SCRIPT" "$(prefix)/bin/tve-`basename $$SCRIPT .sh`"; done
	mv "$(prefix)/bin/tve-undeb" "$(prefix)/bin/undeb"
	mv "$(prefix)/bin/tve-maybesudo" "$(prefix)/bin/maybesudo"
	$(RM) "$(prefix)/bin/tve-xdebuild"*

install: install_sh

clean:
	$(RM) $(CLEAN)

distclean: clean
