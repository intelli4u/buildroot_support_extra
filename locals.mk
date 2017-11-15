TOP_DIR := $(T)
CONFIG_DIR := $(O)
DEPENDENT_LIST := $(wildcard $(D))
BR2_CONFIG := $(CONFIG_DIR)/.config

include $(BR2_CONFIG)
include support/misc/utils.mk

define normalize
  $(foreach d,$1,\
    $(if $(findstring :, $d),\
      $(foreach n, $(wildcard $(lastword $(subst :, , $d))), $(firstword $(subst :, , $d)):$n), \
      $(foreach n, $(wildcard $d), :$n)))
endef

OVERRIDE_DIRS := $(call qstrip,$(BR2_OVERRIDE_DIRS))
OVERRIDE2_DIRS := $(call qstrip,$(BR2_OVERRIDE2_DIRS))
EXPORT_VAR := $(call qstrip,$(BR2_GLOBAL_EXPORT_VAR))
OVERRIDE_FILE := $(call qstrip,$(BR2_PACKAGE_OVERRIDE_FILE))
GLOBAL_VAR_FILE := $(call qstrip,$(BR2_GLOBAL_VARIABLE_FILE))

OVERRIDE_LIST=$(call normalize,$(OVERRIDE_DIRS))
OVERRIDE2_LIST=$(call normalize,$(OVERRIDE2_DIRS))

.PHONY: all
all: $(OVERRIDE_FILE) $(GLOBAL_VAR_FILE)

$(OVERRIDE_FILE): $(BR2_CONFIG) $(DEPENDENT_LIST)
	@rm -rf $(OVERRIDE_FILE)
	@records=''; \
	for d in $(OVERRIDE2_LIST) ; do \
		dirs=`echo $$d | cut -d: -f2`; \
		subst=`echo $$d | cut -d: -f1`; \
		for dirn in $$dirs ; do \
			if test -z "$$subst" ; then \
				name=$${dirn##*/}; \
			else \
				name=$$subst; \
			fi ; \
			records="$$records $$dirn"; \
			echo $$(echo $$name | tr a-z A-Z | tr '-' '_')_OVERRIDE2_SRCDIR=\"$$dirn\" >> $(OVERRIDE_FILE); \
		done; \
	done; \
	for d in $(OVERRIDE_LIST) ; do \
		dirs=`echo $$d | cut -d: -f2`; \
		subst=`echo $$d | cut -d: -f1`; \
		for dirn in $$dirs ; do \
			if echo $$records | grep -qi $$dirn ; then \
				continue; \
			fi; \
			if test -z "$$subst" ; then \
				name=$${dirn##*/}; \
			else \
				name=$$subst; \
			fi ; \
			echo $$(echo $$name | tr a-z A-Z | tr '-' '_')_OVERRIDE_SRCDIR=\"$$dirn\" >> $(OVERRIDE_FILE); \
		done; \
	done

$(GLOBAL_VAR_FILE): $(DEPENDENT_LIST)
	@rm -rf $(GLOBAL_VAR_FILE)
	@echo "export BR2_USE_BUILDROOT=y" >> $(GLOBAL_VAR_FILE)
	@for i in $(EXPORT_VAR); do \
		echo "export $$i" >> $(GLOBAL_VAR_FILE); \
	done
