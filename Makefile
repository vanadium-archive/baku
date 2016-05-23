MAKEFLAGS += --warn-undefined-variables
SHELL := /bin/bash

.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.SUFFIXES:

DIRNAME := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
FLUTTER_BIN := $(DIRNAME)/deps/flutter/bin
DART_BIN := $(FLUTTER_BIN)/cache/dart-sdk/bin
PATH := $(FLUTTER_BIN):$(DART_BIN):$(PATH)

.PHONY: all
all: deps/flutter
	@true # silences watch, do not remove.

deps/flutter:
	git clone https://github.com/flutter/flutter.git -b alpha $@
	cd $@ && git checkout $(shell echo -e `cat FLUTTER_VERSION`)
	flutter doctor
	@touch $@

.PHONY: clean
clean:
	@true

.PHONY: depclean
depclean:
	@rm -rf deps/flutter

.PHONY: packages
packages: examples/todos/packages

examples/todos/packages: examples/todos/pubspec.yaml deps/flutter
	cd examples/todos && pub get
	@touch $@

.PHONY: analyze
analyze: deps/flutter packages
	cd examples/todos/ && flutter analyze

.PHONY: test
test: packages analyze deps/flutter
	cd examples/todos/ && flutter test

.PHONY: fmt
fmt: packages deps/flutter
	cd examples/todos/ && dartfmt --overwrite lib
