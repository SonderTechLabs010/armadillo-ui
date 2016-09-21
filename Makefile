# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# The purpose of this file is to make it easy to sync, set up, and start a build
# without having to remember the flurry of necessary commands and their
# associated parameters.

################################################################################
## Flags.

# This script uses bash-specific commands. Travis does not use bash by default,
# so force use of the correct shell.
SHELL := /bin/bash

# Run slow things that are not needed every build (default: off)
# Slow things include fetching deps and running |tools/get_dependencies|.
sync := no
ifeq ($(sync), no)
flag_sync := no
else
flag_sync := yes
endif

################################################################################
## Local variables.
root := $(shell pwd)
dart_bin := $(root)/third_party/flutter/bin/cache/dart-sdk/bin
pub := $(dart_bin)/pub

################################################################################
## Build flags.
ifeq ($(wildcard ~/goma/.*),)
	goma_installed := no
	gen_flags :=
	ninja_flags := -j32
else
	goma_installed := yes
	gen_flags := --goma
	ninja_flags := -j1000
endif

################################################################################
## Makefile phony rules and default target
.PHONY: *
all: build

################################################################################
## Main targets.

check:
ifeq ($(goma_installed), yes)
	~/goma/goma_ctl.py ensure_start
else
	$(warning [WARNING] Goma not installed. Install Goma to get faster distributed builds.)
endif

sync: check
ifeq ($(flag_sync), yes)
	tools/install_flutter.sh
	# Force an update of Flutter's dependencies.
	third_party/flutter/bin/flutter precache
	cd tools/get_dependencies && $(pub) upgrade && $(pub) run bin/main.dart upgrade
	(cd ../magenta; ./scripts/build-magenta-x86-64)
	../scripts/build-sysroot.sh -c -t x86_64

else
	@:
endif

build: sync
	rm -rf interfaces/lib
	cd .. && packages/gn/gen.py $(gen_flags) -m sysui && buildtools/ninja $(ninja_flags) -C out/debug-x86-64
	$(eval files := $(shell find ../out/debug-x86-64/gen/sysui/interfaces/ -name *.mojom.dart))
	mkdir interfaces/lib
	$(foreach file,$(files),ln -s $(abspath $(file)) interfaces/lib/$(notdir $(file)))

# The Analyzer takes a while to run, so it was moved to be a separate target so
# it won't hurt the development workflow.
analyze: build
	cd tools/analyze && $(pub) run bin/main.dart

# Run all tests.
test: build
	tools/run_dart_tests.sh

# Generate project documentation.
docs: build
	cd tools/generate_dart_doc && $(pub) run bin/main.dart

format:
	git ls-files | grep '\.dart$$' | xargs dartfmt -w

clean:
	rm -rf ../out/

## Example invocations
help:
	@echo "Targets:"
	@echo "	build			Just build sysui"
	@echo "	clean			Clean build directories"
	@echo "	analyze			Run the Dart analyzer"
	@echo "	test			Run all tests"
	@echo "	docs			Generate the project's documentation"
	@echo "	format			Format Dart code"
	@echo ""
	@echo "Flags:"
	@echo "	sync=			Sync deps before building"
