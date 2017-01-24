// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'simulated_sized_box.dart';
import 'simulation_builder.dart';
import 'size_manager.dart';
import 'story_cluster.dart';

const double _kStoryBarMaximizedHeight = 48.0;

/// Sets the size of [child] based on [displayMode] and [panel] using a
/// [SimulatedSizedBox].  This widget expects to have an ancestor
/// [ScopedSizeModel] which provides the size the [child] should be
/// when fully focused.
class StoryFullSizeSimulatedSizedBox extends StatelessWidget {
  final Widget child;
  final GlobalKey containerKey;
  final DisplayMode displayMode;
  final Panel panel;
  final GlobalKey<SimulationBuilderState> focusSimulationKey;

  StoryFullSizeSimulatedSizedBox({
    this.displayMode,
    this.panel,
    this.containerKey,
    this.focusSimulationKey,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Size fullSize = SizeModel.of(context, rebuildOnChange: true).size;

    Size storySize = new Size(
      displayMode == DisplayMode.panels
          ? fullSize.width * panel.width
          : fullSize.width,
      displayMode == DisplayMode.panels
          ? fullSize.height * panel.height
          : fullSize.height,
    );

    // Because focusing and defocusing is using a spring simulation to change
    // the size of the story doing an additional simulation here causes a weird
    // delayed resizing effect.  To fix that, don't use a simulation here if
    // we're in the progress of focusing or defocusing.
    bool useSimulation =
        ((focusSimulationKey.currentState?.progress ?? 0.5) == 1.0) ||
            ((focusSimulationKey.currentState?.progress ?? 0.5) == 0.0);
    return _buildSizedBox(
      useSimulation: useSimulation,
      key: containerKey,
      width: storySize.width,
      height: storySize.height - _kStoryBarMaximizedHeight,
      child: child,
    );
  }

  Widget _buildSizedBox({
    Key key,
    double width,
    double height,
    Widget child,
    bool useSimulation: false,
  }) =>
      useSimulation
          ? new SimulatedSizedBox(
              key: key,
              width: width,
              height: height,
              child: child,
            )
          : new SizedBox(
              key: key,
              width: width,
              height: height,
              child: child,
            );
}
