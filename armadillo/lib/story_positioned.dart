// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'nothing.dart';
import 'panel.dart';
import 'simulation_builder.dart';
import 'simulated_positioned.dart';
import 'story.dart';
import 'story_cluster.dart';

const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedStoryMargin = 1.0;
const double _kStoryMargin = 4.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Positions the [story] in a [StoryPanels] within the given [currentSize] with
/// a [SimulatedPositioned] based on [story.panel], [displayMode], and
/// [isFocused].
class StoryPositioned extends StatelessWidget {
  final DisplayMode displayMode;
  final bool isFocused;
  final Story story;
  final Size currentSize;
  final double focusProgress;
  final Widget child;
  final GlobalKey<SimulationBuilderState> focusSimulationKey;

  StoryPositioned({
    this.displayMode,
    this.isFocused,
    this.story,
    this.currentSize,
    this.focusProgress,
    this.focusSimulationKey,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Panel panel = story.panel;

    double scale =
        lerpDouble(_kUnfocusedStoryMargin, _kStoryMargin, focusProgress) /
            _kStoryMargin;
    double scaledMargin = _kStoryMargin / 2.0 * scale;
    double topMargin = panel.top == 0.0 ? 0.0 : scaledMargin;
    double leftMargin = panel.left == 0.0 ? 0.0 : scaledMargin;
    double bottomMargin = panel.bottom == 1.0 ? 0.0 : scaledMargin;
    double rightMargin = panel.right == 1.0 ? 0.0 : scaledMargin;

    BorderRadius borderRadius = new BorderRadius.all(
      new Radius.circular(
        lerpDouble(
          _kUnfocusedCornerRadius,
          _kFocusedCornerRadius,
          focusProgress,
        ),
      ),
    );

    // Because focusing and defocusing is using a spring simulation to change
    // the size of the story doing an additional simulation here causes a weird
    // delayed resizing effect.  To fix that, don't use a simulation here if
    // we're in the progress of focusing or defocusing.
    bool useSimulation =
        ((focusSimulationKey.currentState?.progress ?? 0.5) == 1.0) ||
            ((focusSimulationKey.currentState?.progress ?? 0.5) == 0.0);

    return story.isPlaceHolder
        ? Nothing.widget
        : displayMode == DisplayMode.panels
            ? _buildPositioned(
                useSimulation: useSimulation,
                key: story.positionedKey,
                top: currentSize.height * panel.top + topMargin,
                left: currentSize.width * panel.left + leftMargin,
                width:
                    currentSize.width * panel.width - leftMargin - rightMargin,
                height: currentSize.height * panel.height -
                    topMargin -
                    bottomMargin,
                child: new ClipRRect(
                  borderRadius: borderRadius,
                  child: child,
                ),
              )
            : _buildPositioned(
                useSimulation: useSimulation,
                key: story.positionedKey,
                top: 0.0,
                left: 0.0,
                width: currentSize.width,
                height: (isFocused)
                    ? currentSize.height
                    : _kStoryBarMaximizedHeight,
                child: child,
              );
  }

  Widget _buildPositioned({
    Key key,
    double top,
    double left,
    double width,
    double height,
    Widget child,
    bool useSimulation: false,
  }) =>
      useSimulation
          ? new SimulatedPositioned(
              key: key,
              top: top,
              left: left,
              width: width,
              height: height,
              child: child,
            )
          : new Positioned(
              key: key,
              top: top,
              left: left,
              width: width,
              height: height,
              child: child,
            );
}
