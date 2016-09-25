// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:sysui_tools_common/git.dart';
import 'package:sysui_tools_common/run_command.dart';

main(List<String> args) async {
  final git = new Git();

  // Perform flutter get for all of the packages.
  (await git.pubspecFiles).forEach((String pubspecFile) async {
    runCommand('flutter packages get',
        workingDirectory: path.join(await git.root, path.dirname(pubspecFile)));
  });
}
