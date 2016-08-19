// Copyright 2015 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Generates some documentation for the Dart packages in the tree.
///
/// The docs will be placed in |<root>/out/Docs/dart/<package name>|.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sysui_tools_common/get_dependencies.dart';
import 'package:sysui_tools_common/git.dart';
import 'package:sysui_tools_common/run_command.dart';

main(List<String> args) async {
  final git = new Git();
  final root = await git.root;
  final outputDirPath = path.join(root, 'out', 'Docs', 'dart');

  // Gather a list of all our git-tracked dart files.  Filter out dart tests as
  // their mains will conflict later on and we're not interested in their docs
  // anyway.
  final dartFiles = await git.nonTestDartFiles;

  final pubspecFiles = await git.pubspecFiles;

  // Determine our list of packages from the pubspec.yamls.
  final packageFolders =
      pubspecFiles.map((String filePath) => path.dirname(filePath)).toList();

  final tempDir = await createTempDependenciesPackage(git: git);
  final libDir = new Directory(path.join(tempDir.path, 'lib'));
  await libDir.create(recursive: true);

  // For each package, create a dart file with all the dart files in that
  // package exported.
  final createdFiles = <File>[];
  packageFolders.forEach((String packageFolder) {
    final body = new StringBuffer();
    dartFiles
        .where((String dartFile) => dartFile.startsWith(packageFolder))
        .forEach((String dartFile) =>
            body.writeln('export \'file://${path.join(root, dartFile)}\';'));

    final String bodyString = body.toString();
    if (bodyString.isNotEmpty) {
      createdFiles.add(new File(
          path.join(libDir.path, '${packageFolder.replaceAll("/","_")}.dart'))
        ..writeAsStringSync(bodyString));
    }
  });

  // Remove any preexisting docs.
  final outputDir = new Directory(outputDirPath);
  if (outputDir.exists()) {
    await outputDir.delete(recursive: true);
  }

  // Create docs from our newly created package specific dart files then delete
  // those dart files when done.
  await runCommand('dartdoc --input ${tempDir.path} --output $outputDirPath',
      workingDirectory: tempDir.path).then((String stdout) {
    tempDir.delete(recursive: true);
    print(stdout);
  });
}
