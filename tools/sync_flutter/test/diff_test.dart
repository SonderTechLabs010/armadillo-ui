// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';

import '../lib/diff.dart';

const COMMIT_LIST = '''
abcdef3 Some commit
123efe4 Another commit
23efab4 Not a merge
9867fe3 Merge pull request #314 from foo
2fe147b More code
9876543 Merge pull request #313 from bar
''';

void main() {
  test('filtering merge commits out', () {
    final commits = LineSplitter.split(COMMIT_LIST);
    final filtered = removeMerges(commits);
    expect(filtered.length, equals(4));
  });

  test('parsing a commit', () {
    final commit = parseCommit('abcdef3 Some commit');
    expect(commit.id, equals('abcdef3'));
    expect(commit.title, equals('Some commit'));
  });
}
