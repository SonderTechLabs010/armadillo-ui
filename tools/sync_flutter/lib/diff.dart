// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:sysui_tools_common/run_command.dart';

/// Removes merge commits from a list of Git commits.
Iterable<String> removeMerges(Iterable<String> commits) {
  return commits.where(
      (line) => !line.startsWith(new RegExp(r'.{7,15}\sMerge pull request')));
}

/// Parse the given one-line representation of a commit.
Commit parseCommit(String line) {
  final pattern = new RegExp(r'(^[0-9a-f]{7,15})\s(.+)$');
  final match = pattern.firstMatch(line);
  return new Commit(match.group(1), match.group(2));
}

/// Returns a diff of the Flutter tree between the given commits.
///
/// Note that the given repo will remain untouched.
Future<Diff> diffFlutter(String path, {String from, String to}) async {
  Directory.current = path;
  // Filter commits.
  final commits = removeMerges(
          LineSplitter.split(await runCommand('git log --oneline $from..$to')))
      .map((line) => parseCommit(line))
      .toList();
  final head = await runCommand('git rev-parse HEAD');

  return new Diff(commits, head);
}

/// Result of a diff.
class Diff {
  /// The new commits.
  final List<Commit> commits;

  /// Full id of the head commit.
  final String head;

  Diff(this.commits, this.head);
}

/// Represents a commit in the Flutter tree.
class Commit {
  /// Abbreviated id.
  final String id;

  /// One-line title.
  final String title;

  Commit(this.id, this.title);

  @override
  String toString() {
    return '$id $title';
  }
}
