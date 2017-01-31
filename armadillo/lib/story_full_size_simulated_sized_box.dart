// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'simulated_fractional.dart';
import 'size_model.dart';
import 'story_cluster.dart';

/// Sets the size of [child] based on [displayMode] and [panel] using a
/// [SimulatedFractional].  This widget expects to have an ancestor
/// [ScopedModel] which provides the size the [child] should be
/// when fully focused.
class StoryFullSizeSimulatedSizedBox extends StatelessWidget {
  final Widget child;
  final GlobalKey containerKey;
  final DisplayMode displayMode;
  final Panel panel;
  final double storyBarMaximizedHeight;

  StoryFullSizeSimulatedSizedBox({
    this.displayMode,
    this.panel,
    this.containerKey,
    this.storyBarMaximizedHeight,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Size fullSize = SizeModel.of(context, rebuildOnChange: true).size;
    return new SimulatedFractional(
      key: containerKey,
      fractionalWidth: displayMode == DisplayMode.panels ? panel.width : 1.0,
      fractionalHeight:
          ((displayMode == DisplayMode.panels ? panel.height : 1.0) -
                  (storyBarMaximizedHeight / fullSize.height))
              .clamp(0.0, double.INFINITY),
      size: fullSize,
      child: child,
    );
  }
}
