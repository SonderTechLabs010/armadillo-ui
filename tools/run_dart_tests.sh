#!/bin/bash
# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Usage: run_dart [/directory_off_of_root]
# If the parameter is missing, then the project's root directory is used.

# Finds the Dart source files in the tree and runs the analyzer on them.
ROOT=`git rev-parse --show-toplevel`
cd $ROOT/$1

n_packages=0
n_tested=0
has_failed=false

for spec in `git ls-files | grep pubspec.yaml`
do
  let "n_packages += 1"
  package=`dirname $spec`
  uses_flutter=`grep "\sflutter:" $spec`
  has_tests=false
  cd $package
  tput setaf 5
  echo "$package"
  tput sgr0
  if [[ -d "test" ]]; then
    if [[ $uses_flutter ]]; then
      flutter test
    else
      pub run test test/
    fi
    if [[ $? -ne 0 ]]; then
      has_failed=true
    fi
    has_tests=true
  fi
  if [[ "$has_tests" = true ]]; then
    let "n_tested += 1"
  else
    echo "No tests :("
  fi
  cd - >/dev/null
done

return_code=0
echo "--------------------------------------------"
let "coverage=100 * n_tested / n_packages"
tput setaf 3
echo -n "  $coverage%"
tput sgr0
echo " of packages tested"
if [[ "$has_failed" = true ]]; then
  echo -n "  Some tests "
  tput setaf 1
  echo -n "FAILED"
  tput sgr0
  echo "!"
  return_code=314
fi
echo "--------------------------------------------"
exit $return_code
