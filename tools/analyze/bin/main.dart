// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sysui_tools_common/get_dependencies.dart';
import 'package:sysui_tools_common/git.dart';

main(List<String> args) async {
  final git = new Git();

  // Gather a list of all our git-tracked dart files.
  final dartFiles = await git.dartFiles;
  if (args.isNotEmpty) {
    final prefix = path.relative(args[0], from: await git.root);
    dartFiles.removeWhere((String dartFile) => !dartFile.startsWith(prefix));
  }
  if (dartFiles.isEmpty) {
    print('No file to analyze!');
    return;
  }

  final dartFolderArgumentString =
      dartFiles.reduce((String value, String element) => value + ' ' + element);

  final tempDir = await createTempDependenciesPackage(git: git);
  final packagesFile = path.join(tempDir.path, '.packages');
  final optionsFile = path.join(await git.root, '.analysis_options');
  final command =
      'dartanalyzer $dartFolderArgumentString --packages=$packagesFile --options $optionsFile --fatal-lints --fatal-warnings --fatal-hints';

  final runArgs = command.split(' ');
  final result = await Process.run(runArgs[0], runArgs.sublist(1),
      workingDirectory: await git.root);
  final output = _filterResults(result.stdout.trim());
  if (result.exitCode != 0) {
    print('Analysis failed:');
    print(result.stderr);
  }
  if (output.isNotEmpty) {
    print(output);
  }
  exit(result.exitCode);
}

// Filters out duplicate lines, 'No issues found', and TODOs.
String _filterResults(String string) {
  final seenLines = new Set<String>();
  final lines = LineSplitter.split(string).where((line) {
    bool result = !seenLines.contains(line) &&
        line.startsWith('[') &&
        !line.startsWith('[info] TODO');
    if (result) {
      seenLines.add(line);
    }
    return result;
  }).toList();
  if (lines.isEmpty) {
    return '';
  } else {
    return lines
        .reduce((String value, String element) => value + '\n' + element);
  }
}
