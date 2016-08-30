// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:test/test.dart';

import '../lib/engine.dart';

void main() {
  test('extract Mojo SDK revision', () {
    const depsContent = '''
    # When adding a new dependency, please update the top-level .gitignore file
    # to list the dependency's destination directory.

    vars = {
      'chromium_git': 'https://chromium.googlesource.com',
      'mojo_sdk_revision': '333333333311111111114444444444ffffffffff',
      'base_revision': '6c89618151eb0e23d330778e6d6ea16fc6105010',
      'skia_revision': '992ad363d7ca879cdb86f802b379f06800a44125',

      # Note: When updating the Dart revision, ensure that all entries that are
      # dependencies of dart are also updated
      'dart_revision': '7c2c02d6a6e299124946672eeaf52b71fbd74d3e',
    ''';
    final commit = extractMojoSdkRevision(depsContent);
    expect(commit, equals('333333333311111111114444444444ffffffffff'));
  });
}
