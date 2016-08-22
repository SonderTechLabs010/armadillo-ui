#!/bin/sh
# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

# Installs Flutter in third_party/flutter and syncs it to the version specified
# in the FLUTTER_VERSION file.

ROOT=`git rev-parse --show-toplevel`
DEST=$ROOT/third_party/flutter
TARGET_VERSION=`cat $ROOT/FLUTTER_VERSION`

# Create the repo if needed.
if [ ! -d $DEST ]; then
  echo "Flutter repo does not exist, cloning..."
  git clone https://github.com/flutter/flutter.git $DEST
fi

cd $DEST
echo "Resetting Flutter repo to $TARGET_VERSION"
git fetch
git reset --hard $TARGET_VERSION
