// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart' as yaml;

import 'git.dart';
import 'run_command.dart';

/// Creates a temp directory containing a pubspec.yaml listing all the packages
/// in the git repo related to the current directory as dependencies. This
/// dependency package will also have pub upgrade/get called on it.
Future<Directory> createTempDependenciesPackage(
    {String pubCommand: 'get', Git git}) async {
  if (git == null) {
    git = new Git(workingDirectory: Directory.current.path);
  }
  final root = await git.root;
  final pubspecFiles = await git.pubspecFiles;

  String dependencies = 'name: sysui\ndependencies:\n';
  final collectiveDevDependencies = new Map<String, String>();
  pubspecFiles.forEach((String pubspecFile) {
    var file = new File(path.join(root, pubspecFile));
    String fileContents = file.readAsStringSync(encoding: ASCII);
    yaml.YamlMap yamlMap =
        yaml.loadYamlNode(fileContents, sourceUrl: pubspecFile);
    String packageName = yamlMap['name'];
    String fullPath = path.join(root, path.dirname(pubspecFile));
    dependencies += '  $packageName:\n    path: $fullPath\n';
    yamlMap['dev_dependencies']?.forEach((String key, yaml.YamlNode yamlNode) {
      if (yamlNode is yaml.YamlMap) {
        yaml.YamlMap yamlMap = yamlNode;
        String normalizedPath = path.normalize(
            path.join(root, path.dirname(pubspecFile), yamlMap['path']));
        if (!pubspecFiles.contains(
            normalizedPath.substring(root.length + 1) + '/pubspec.yaml')) {
          collectiveDevDependencies[key] =
              '  $key:\n    path: $normalizedPath\n';
        }
      } else {
        collectiveDevDependencies[key] = '  $key: \'$yamlNode\'\n';
      }
    });
  });

  if (collectiveDevDependencies.isNotEmpty) {
    dependencies += 'dev_dependencies:\n';
    collectiveDevDependencies.forEach((String key, String value) {
      dependencies += value;
    });
  }

  // This isn't really necessary but it'll throw an error if the YAML we created
  // is malformed.
  yaml.loadYamlNode(dependencies, sourceUrl: 'blah');

  final tempDir = Directory.systemTemp.createTempSync('sysui');
  File dependenciesPubSpec = new File(path.join(tempDir.path, 'pubspec.yaml'));
  dependenciesPubSpec.writeAsStringSync(dependencies);
  await runCommand('pub $pubCommand', workingDirectory: tempDir.path);
  return tempDir;
}
