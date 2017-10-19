TOP_DIR := $(T)
CONFIG_DIR := $(O)
DEPENDENT_LIST := $(wildcard $(D))
BR2_CONFIG := $(CONFIG_DIR)/.config

include $(BR2_CONFIG)
include support/misc/utils.mk

SOURCE_DIRS := $(call qstrip,$(BR2_SOURCE_DIR))
EXPORT_VAR := $(call qstrip,$(BR2_GLOBAL_EXPORT_VAR))
OVERRIDE_FILE := $(call qstrip,$(BR2_PACKAGE_OVERRIDE_FILE))
GLOBAL_VAR_FILE := $(call qstrip,$(BR2_GLOBAL_VARIABLE_FILE))

DIR_LIST := $(foreach d,$(SOURCE_DIRS),\
  $(if $(findstring :, $d),\
    $(foreach n, $(wildcard $(lastword $(subst :, , $d))), $(firstword $(subst :, , $d)):$n), \
    $(foreach n, $(wildcard $d), :$n)))

.PHONY: all
all: $(OVERRIDE_FILE) $(GLOBAL_VAR_FILE)

$(OVERRIDE_FILE): $(DEPENDENT_LIST)
	@rm -rf $(OVERRIDE_FILE)
	@for d in $(DIR_LIST) ; do \
		dirs=`echo $$d | cut -d: -f2`; \
		subst=`echo $$d | cut -d: -f1`; \
		for dirn in $$dirs ; do \
			if test -z "$$subst" ; then \
				name=$${dirn##*/}; \
			else \
				name=$$subst; \
			fi ; \
			echo $$(echo $$name | tr a-z A-Z | tr '-' '_')_OVERRIDE_SRCDIR=\"$$dirn\" >> $(OVERRIDE_FILE); \
		done; \
	done

$(GLOBAL_VAR_FILE): $(DEPENDENT_LIST)
	@rm -rf $(GLOBAL_VAR_FILE);
	@for i in $(EXPORT_VAR); do \
		echo "export $$i" >> $(GLOBAL_VAR_FILE); \
	done
