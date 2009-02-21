
#Is there some way to make this magical?  --DV
dir     := ./depends

.PHONY: targets all
localtargets:
	$(MAKE) -C .. targets_$(dir)
all:
	$(MAKE) -C .. all

%:
	$(MAKE) -C .. $*
