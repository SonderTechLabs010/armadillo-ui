// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:sysui_tools_common/git.dart';
import 'package:sysui_tools_common/run_command.dart';

import '../lib/diff.dart';
import '../lib/engine.dart';

const FLAG_COUNT = 'count';
const FLAG_FROM = 'from';
const FLAG_TO = 'to';

const BRANCH_NAME = 'sync';
const COMMIT_TITLE = 'Flutter sync';

/// Returns the current head of the Flutter project in the tree hosting this
/// script.
Future<String> _getFlutterHead() async {
  final root = await runCommand('git rev-parse --show-toplevel');
  Directory.current = path.join(root, 'third_party', 'flutter');
  return runCommand('git rev-parse HEAD');
}

/// Creates a clone of the Flutter repo and returns its path.
Future<String> _createFlutterClone(String baseDirectory) async {
  final repoPath = path.join(baseDirectory, 'flutter');
  await runCommand(
      'git clone -q --branch master --single-branch https://github.com/flutter/flutter $repoPath');
  return repoPath;
}

/// Generates a sync commit.
class GenerateCommitCommand extends Command {
  @override
  final name = 'generate';
  @override
  final description = 'Generates a sync commit.';

  GenerateCommitCommand() {
    argParser
      ..addOption(FLAG_COUNT,
          help: 'Minimum number of commits needed to create a pull request',
          defaultsTo: '1');
  }

  @override
  run() async {
    final minCount = int.parse(argResults[FLAG_COUNT]);

    // Check that master is the current branch.
    final currentBranch = await runCommand('git rev-parse --abbrev-ref HEAD');
    if (currentBranch != 'master') {
      print('This script should be run from a clean master branch!');
      exit(314);
    }

    // Reset sync branch if needed.
    final hasSyncBranch = (await runCommand(
            'git rev-parse --verify $BRANCH_NAME',
            ignoreErrors: true)) !=
        null;
    if (hasSyncBranch) {
      print('Deleting existing sync branch');
      await runCommand('git branch -D $BRANCH_NAME');
    }

    // Set up temporary directories.
    final baseDirectory = await Directory.systemTemp.createTemp('sync_flutter');
    final basePath = baseDirectory.path;
    print('Working directory: $basePath');

    // Get the currently sync'd Flutter commit.
    final sysuiRoot = await runCommand('git rev-parse --show-toplevel');
    Directory.current = sysuiRoot;
    final currentCommit = new File('FLUTTER_VERSION').readAsStringSync().trim();
    print('Flutter currently synced at: $currentCommit');

    // Get diff from Flutter clone.
    final flutterPath = await _createFlutterClone(basePath);
    Diff diff = await diffFlutter(flutterPath, from: currentCommit, to: 'HEAD');
    if (diff.commits.isEmpty) {
      print('Flutter is up-to-date!');
      return;
    }
    if (diff.commits.length < minCount) {
      print('Not enough changes (${diff.commits.length}), skipping.');
      return;
    }
    print('Current Flutter head is: ${diff.head}');
    print('${diff.commits.length} missing commits:');
    for (Commit commit in diff.commits) {
      print('    $commit');
    }

    // Get the Flutter engine's dependencies.
    Directory.current = flutterPath;
    final additionalDependencies =
        await extractEngineDependencies(basePath, flutterPath);

    // Prepare the SysUI repo.
    Directory.current = sysuiRoot;
    await runCommand('git checkout -q -b $BRANCH_NAME');

    // Update the various files.
    new File('FLUTTER_VERSION').writeAsStringSync(diff.head);
    List updated_files = ['FLUTTER_VERSION'];
    (await new Git().pubspecFiles).forEach((specFilename) {
      // Replace the version of mojo_sdk for packages that depend on it.
      final specFile = new File(specFilename);
      final specs = specFile.readAsStringSync();
      if (!specs.contains('mojo_sdk')) {
        return;
      }
      updated_files.add(specFilename);
      final newSpecs = specs.replaceFirst(
          new RegExp(r"mojo_sdk: [^\s]+", multiLine: true),
          'mojo_sdk: ${additionalDependencies.mojoSdkPackageVersion}');
      specFile.writeAsStringSync(newSpecs);
    });

    // Build the list of commits included in the sync.
    final listBuilder = new StringBuffer();
    for (Commit commit in diff.commits) {
      listBuilder.writeln(
          'https://github.com/flutter/flutter/commit/${commit.id} ${commit.title}');
    }
    final commitList = listBuilder.toString();

    // Prepare the (long) commit message.
    final messageFilePath =
        path.join(basePath, 'flutter_sync_commit_message.txt');
    final messageFile = new File(messageFilePath);
    StringBuffer content = new StringBuffer(COMMIT_TITLE)
      ..writeln()
      ..writeln()
      ..write(commitList);
    messageFile.writeAsStringSync(content.toString());

    // Create the sync commit.
    await runCommand('git add -A ${updated_files.join(" ")}');
    await runCommand('git commit -F $messageFilePath');
    print('Commit created!');
  }
}

/// Shows the new commits in the Flutter tree.
class DiffCommand extends Command {
  @override
  final name = 'diff';
  @override
  final description = 'View new changes in the Flutter tree.';

  DiffCommand() {
    argParser
      ..addOption(FLAG_FROM, help: 'Current Flutter commit')
      ..addOption(FLAG_TO, help: 'New Flutter commit');
  }

  @override
  run() async {
    final originCommit = argResults[FLAG_FROM] ?? await _getFlutterHead();
    final targetCommit = argResults[FLAG_TO] ?? 'HEAD';
    print('Showing commits from: $originCommit to $targetCommit');
    final path = (await Directory.systemTemp.createTemp('diff_flutter')).path;
    final diff = await diffFlutter(await _createFlutterClone(path),
        from: originCommit, to: targetCommit);
    print('-------------------------------------');
    for (var commit in diff.commits) {
      print(commit);
    }
    print('-------------------------------------');
    print('${diff.commits.length} commits');
  }
}

main(List<String> args) async {
  final runner =
      new CommandRunner('sync_flutter', 'Syncs Flutter in the SysUI repo')
        ..addCommand(new GenerateCommitCommand())
        ..addCommand(new DiffCommand());
  runner.run(args).catchError((error) {
    if (error is! UsageException) {
      throw error;
    }
    print(error);
    exit(64);
  });
}
