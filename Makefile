
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
	$(RM) "$(prefix)/bin/tve-tve-setup" "$(prefix)/bin/tve-setup.sh"
	$(RM) "$(prefix)/bin/tve-xdebuild"*
	install -DTvpm644 tve-setup.sh "$(prefix)/lib/tve-setup.sh"

install: install_sh
	install -Dvpm755 gui.tcl "$(prefix)/bin/tve-gui"
# TODO: TCL includes to packages and such
# Also, tve-setup.sh needs better handling
# Also, gui.tcl needs to be able to find the utils locally
#       and after they have been installed.  Doable?
	install -Dvpm644 README  "$(prefix)/share/doc/theveeb"
	install -Dvpm644 COPYING "$(prefix)/share/doc/theveeb"

tve.deb:
	debuild --no-tgz-check
	mv ../tve-core_*.deb tve-core.deb
	$(RM) ../tve-core_*

tve.exe:
	$(MAKE) prefix=./nsis/dist/usr install
	makensis nsis/tve.nsi

clean:
	$(RM) $(CLEAN)

distclean: clean
	$(RM) -r tve-core.deb build-stamp debian/tve-core.debhelper.log debian/tve-core.substvars debian/tve-core tve.exe nsis/dist
