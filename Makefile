SHELL := /bin/bash
# TERMBASE_VERSION := $(shell yq r metadata.yaml version)
# TERMBASE_XLSX_PATH := $(shell yq r metadata.yaml filename)
TERMBASE_VERSION := 20201214
TERMBASE_XLSX_PATH := data/${TERMBASE_VERSION}-iev-export.xlsx

all: concepts

clean:
	rm -rf termbase.xlsx

distclean: clean
	rm -rf concepts termbase.yaml

termbase.xlsx:
	cp '${TERMBASE_XLSX_PATH}' termbase.xlsx

termbase.yaml: termbase.xlsx
	bundle exec iev-termbase xlsx2yaml $<;

concepts: termbase.yaml

concepts.zip: concepts
	zip -9 -r $@ concepts images

# update-init:
# 	git submodule update --init
#
# update-modules:
# 	git submodule foreach git pull origin master

.PHONY: all clean distclean

# update-init update-modules
