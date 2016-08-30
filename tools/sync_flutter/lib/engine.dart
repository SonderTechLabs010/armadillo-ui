// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:sysui_tools_common/run_command.dart';
import 'package:yaml/yaml.dart' as yaml;

/// Contains the commit ids of some of Flutter's dependencies.
class FlutterDependencies {
  final String mojoSdkPackageVersion;

  FlutterDependencies(this.mojoSdkPackageVersion);

  @override
  String toString() => 'pub:$mojoSdkPackageVersion';
}

/// Extracts the Mojo SDK revision from the given dependencies file content.
String extractMojoSdkRevision(String deps) {
  final pattern = new RegExp(r"\s+'mojo_sdk_revision':\s'([0-9a-f]{40})',");
  return pattern.firstMatch(deps).group(1);
}

/// Identifies the required dependencies of the Flutter engine based on the
/// Flutter repo at [flutterPath].
Future<FlutterDependencies> extractEngineDependencies(
    String basePath, String flutterPath) async {
  final directory = new Directory(path.join(basePath, 'engine'));
  directory.createSync();

  // Get the revision of flutter/engine.
  final revisionFile =
      new File(path.join(flutterPath, 'bin', 'cache', 'engine.version'));
  final engineRevision = (await revisionFile.readAsString()).trim();
  print('Engine revision: $engineRevision');

  // Clone the engine project repo.
  await runCommand(
      'git clone -q --branch master --single-branch https://github.com/flutter/engine ${directory.path}');
  Directory.current = directory;
  await runCommand('git checkout -q $engineRevision');

  // Get the version of the mojo_sdk package.
  final specsFile =
      new File(path.join('sky', 'packages', 'sky_services', 'pubspec.yaml'));
  final Map<String, dynamic> specs =
      yaml.loadYaml(specsFile.readAsStringSync());
  final mojoSdkVersion = specs['dependencies']['mojo_sdk'];
  print('mojo_sdk package: $mojoSdkVersion');

  return new FlutterDependencies(mojoSdkVersion);
}
