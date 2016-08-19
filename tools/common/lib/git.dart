// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'run_command.dart';

/// Performs various git operations.
class Git {
  final String workingDirectory;
  String _root;
  List<String> _pubSpecFiles;
  List<String> _dartFiles;
  List<String> _nonTestDartFiles;

  Git({String workingDirectory})
      : workingDirectory = workingDirectory ?? Directory.current.path;

  /// Get's the git root directory from [workingDirectory].
  /// The result will be cached.
  Future<String> get root async {
    if (_root == null) {
      _root = await runCommand('git rev-parse --show-toplevel',
          workingDirectory: workingDirectory);
    }
    return _root;
  }

  /// Gathers a list of all the git-tracked pubspec.yamls.
  /// The result will be cached.
  Future<List<String>> get pubspecFiles async {
    if (_pubSpecFiles == null) {
      _pubSpecFiles = await getFiles('pubspec.yaml');
    }
    return _pubSpecFiles;
  }

  /// Gathers a list of all the git-tracked dart files.
  /// The result will be cached.
  Future<List<String>> get dartFiles async {
    if (_dartFiles == null) {
      _dartFiles = await getFiles('.dart');
    }
    return _dartFiles;
  }

  /// Gathers a list of all the git-tracked dart files that aren't tests.
  /// The result will be cached.
  Future<List<String>> get nonTestDartFiles async {
    if (_nonTestDartFiles == null) {
      _nonTestDartFiles = await dartFiles;
      _nonTestDartFiles.removeWhere((String dartFile) =>
          (!dartFile.contains('/lib/') && !dartFile.contains('/bin/')));
    }
    return _nonTestDartFiles;
  }

  /// Gathers a list of all the git-tracked files with the given suffix.
  Future<List<String>> getFiles(String fileSuffix) async => LineSplitter
      .split(await runCommand('git ls-files', workingDirectory: await root))
      .where((line) => line.endsWith(fileSuffix))
      .toList();
}
