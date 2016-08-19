// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:sysui_tools_common/get_dependencies.dart';
import 'package:sysui_tools_common/git.dart';
import 'package:sysui_tools_common/run_command.dart';

main(List<String> args) async {
  final pubCommand = args.contains('upgrade') ? 'upgrade' : 'get';
  final git = new Git();

  // Fill the pubcache by performing an online pub upgrade/get for a package
  // that lists all the packages in this repo as a dependency.
  await createTempDependenciesPackage(pubCommand: pubCommand, git: git);

  // Perform offline pub upgrade/get for all of the packages.
  (await git.pubspecFiles).forEach((String pubspecFile) async {
    runCommand('pub $pubCommand --verbosity=error --offline',
        workingDirectory: path.join(await git.root, path.dirname(pubspecFile)));
  });
}
