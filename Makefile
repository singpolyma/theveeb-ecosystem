
include build-config.mk

all:    targets
#all:   tests
#all:   objs
#all:   outputs

dir             := .
include         Rules.mk

.PHONY: all static targets test clean distclean install install_sh

%$(BINSUFFIX): %.o
	$(CC) $^ $(LL_ALL) $(LL_TGT) $(LDFLAGS) -o $@

static:
	$(MAKE) LDFLAGS="-lpthread -ldl -static"

install_sh: *.sh
	mkdir -p "$(prefix)/bin"
	@for SCRIPT in $^; do cp -vp "$$SCRIPT" "$(prefix)/bin/tve-`basename $$SCRIPT .sh`"; done
	mv "$(prefix)/bin/tve-undeb" "$(prefix)/bin/undeb"
	mv "$(prefix)/bin/tve-maybesudo" "$(prefix)/bin/maybesudo"
	$(RM) "$(prefix)/bin/tve-tve-setup" "$(prefix)/bin/tve-setup.sh"
	$(RM) "$(prefix)/bin/tve-xdebuild"*
	mkdir -p "$(prefix)/lib/"
	cp -vp tve-setup.sh "$(prefix)/lib/tve-setup.sh"

install: install_sh
	-cp -RLpv external/* "$(prefix)/.."
	cp -vp gui.tcl "$(prefix)/bin/tve-gui"
# TODO: TCL includes to packages and such
	mkdir -p "$(prefix)/share/doc/tve-core"
	cp -vp README  "$(prefix)/share/doc/tve-core/README"
	cp -vp COPYING "$(prefix)/share/doc/tve-core/COPYING"

tve-core.deb:
	debuild --no-tgz-check
	mv ../tve-core_*.deb tve-core.deb
	$(RM) ../tve-core_*

tve.exe:
	$(MAKE) prefix=./nsis/dist/usr install
	makensis nsis/tve.nsi

test: all
	test/test-login.sh
	test/test-update.sh
	test/test-install.sh
	test/test-remove.sh
	test/test-logout.sh

clean:
	$(RM) $(CLEAN)

distclean: clean
	$(RM) -r tve-core.deb build-stamp debian/tve-core.debhelper.log debian/tve-core.substvars debian/tve-core tve.exe nsis/dist
