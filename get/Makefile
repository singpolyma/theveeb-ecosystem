#Is there some way to make this magical?  --DV
dir     := ./get

.PHONY: localtargets all
localtargets:
	$(MAKE) -C .. targets_$(dir)
all:
	$(MAKE) -C .. all

%:
	$(MAKE) -C .. $*
