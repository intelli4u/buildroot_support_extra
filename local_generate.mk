TOP_DIR := $(T)
CONFIG_DIR := $(O)
DEPENDENT_LIST := $(D)
BR2_CONFIG := $(CONFIG_DIR)/.config

include $(BR2_CONFIG)
include support/misc/utils.mk

SOURCE_DIRS := $(call qstrip,$(BR2_SOURCE_DIR))
OVERRIDE_FILE := $(call qstrip,$(BR2_PACKAGE_OVERRIDE_FILE))

DIR_LIST := $(foreach d,$(SOURCE_DIRS),\
  $(if $(findstring :, $d),\
    $(foreach n, $(wildcard $(lastword $(subst :, , $d))), $(firstword $(subst :, , $d)):$n), \
    $(foreach n, $(wildcard $d), :$n)))

$(OVERRIDE_FILE): $(DEPENDENT_LIST)
	@for d in $(DIR_LIST) ; do \
		dirs=`echo $$d | cut -d: -f2`; \
		subst=`echo $$d | cut -d: -f1`; \
		for dirn in $$dirs ; do \
			if test -z "$$subst" ; then \
				name=$${dirn##*/}; \
			else \
				name=$$subst; \
			fi ; \
			echo $$(echo $$name | tr a-z A-Z)_OVERRIDE_SRCDIR=\"$$dirn\" >> $(OVERRIDE_FILE); \
		done; \
	done

