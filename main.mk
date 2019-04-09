# Decide which path to run make

MAKEARGS := O=$(BR2_OUTDIR)

MAKEFLAGS += --no-print-directory

.PHONY: _all $(MAKECMDGOALS)

all	:= $(filter-out Makefile,$(MAKECMDGOALS))

defconfigs := $(filter %_defconfig,$(all))

targets	:= $(filter-out %_defconfig,$(all))

_targets:
	$(MAKE) $(MAKEARGS) -C $(BR2_OUTDIR) $(targets)

_defconfig:
	$(MAKE) $(MAKEARGS) -C $(BR2_BUILDDIR) $(defconfigs)

Makefile:;

ifneq ($(defconfigs),)
$(defconfigs): _defconfig
	@:
endif

$(targets): _targets
	@:
