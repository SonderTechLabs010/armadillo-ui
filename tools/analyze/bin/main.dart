// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sysui_tools_common/git.dart';
import 'package:sysui_tools_common/run_command.dart';

main(List<String> args) async {
  final git = new Git();
  int exitCode = 0;
  String errors = '';
  int analyzeCount = 0;

  // Get the git root folder...
  git.root.then((String gitRoot) {
    // ... then get all the pubspec files in the git repo.
    git.pubspecFiles.then((List<String> pubspecFiles) {
      // For each pubspec file in the repo...
      pubspecFiles.forEach((String pubspecFile) {
        //  ... get the dependencies for the package...
        String workingDirectory = path.join(gitRoot, path.dirname(pubspecFile));
        runCommand('flutter packages get', workingDirectory: workingDirectory)
            .then((_) {
          // ... and then analyze the project.
          final packagesFile = path.join(workingDirectory, '.packages');
          final optionsFile = path.join(gitRoot, '.analysis_options');
          final command =
              'dartanalyzer $workingDirectory --packages=$packagesFile --options $optionsFile --fatal-lints --fatal-warnings --fatal-hints';
          final runArgs = command.split(' ');
          Process
              .run(runArgs[0], runArgs.sublist(1), workingDirectory: gitRoot)
              .then((final result) {
            // As each analysis completes, collect the output and exit codes.
            final output = _filterResults(result.stdout.trim());
            if (result.exitCode != 0) {
              errors += result.stderr;
              exitCode = result.exitCode;
            }
            if (output.isNotEmpty) {
              errors += output;
            }

            // If we've analyzed all the projects print the cumulative output
            // and exit with an appropriate exit code.
            analyzeCount++;
            if (analyzeCount == pubspecFiles.length) {
              if (exitCode != 0) {
                print('Analysis failed:');
                print(errors);
              }
              exit(exitCode);
            }
          });
        });
      });
    });
  });
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
