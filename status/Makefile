
#Is there some way to make this magical?  --DV
dir     := ./status

.PHONY: targets all install
localtargets:
	$(MAKE) -C .. targets_$(dir)
all:
	$(MAKE) -C .. all
install:
	$(MAKE) -C .. install_$(dir)

%:
	$(MAKE) -C .. $*
