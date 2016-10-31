// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'simulated_sized_box.dart';
import 'size_manager.dart';
import 'story_cluster.dart';

const double _kStoryBarMaximizedHeight = 48.0;

/// Sets the size of [child] based on [displayMode] and [panel] using a
/// [SimulatedSizedBox].  This widget expects to have an ancestor
/// [InheritedSizeManager] which provides the size the [child] should be
/// when fully focused.
class StoryFullSizeSimulatedSizedBox extends StatelessWidget {
  final Widget child;
  final GlobalKey containerKey;
  final DisplayMode displayMode;
  final Panel panel;

  StoryFullSizeSimulatedSizedBox({
    this.displayMode,
    this.panel,
    this.containerKey,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Size fullSize = InheritedSizeManager
        .of(
          context,
          rebuildOnChange: true,
        )
        .size;

    Size storySize = new Size(
      displayMode == DisplayMode.panels
          ? fullSize.width * panel.width
          : fullSize.width,
      displayMode == DisplayMode.panels
          ? fullSize.height * panel.height
          : fullSize.height,
    );

    return new SimulatedSizedBox(
      key: containerKey,
      width: storySize.width,
      height: storySize.height - _kStoryBarMaximizedHeight,
      child: child,
    );
  }
}
