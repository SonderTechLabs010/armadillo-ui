// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'nothing.dart';
import 'panel.dart';
import 'simulated_fractional.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

const double _kUnfocusedStoryMargin = 1.0;
const double _kStoryMargin = 4.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Positions the [story] in a [StoryPanels] within the given [currentSize] with
/// a [SimulatedFractional] based on [story]'s panel, [displayMode], and
/// [isFocused].
class StoryPositioned extends StatelessWidget {
  final DisplayMode displayMode;
  final bool isFocused;
  final Story story;
  final Size currentSize;
  final double focusProgress;
  final Widget child;
  final double storyBarMaximizedHeight;

  StoryPositioned({
    this.storyBarMaximizedHeight,
    this.displayMode,
    this.isFocused,
    this.story,
    this.currentSize,
    this.focusProgress,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    Panel panel = story.panel;

    double scale =
        lerpDouble(_kUnfocusedStoryMargin, _kStoryMargin, focusProgress) /
            _kStoryMargin;
    double scaledMargin = _kStoryMargin / 2.0 * scale;
    double topMargin =
        panel.top == 0.0 ? 0.0 : scaledMargin / currentSize.height;
    double leftMargin =
        panel.left == 0.0 ? 0.0 : scaledMargin / currentSize.width;
    double bottomMargin =
        panel.bottom == 1.0 ? 0.0 : scaledMargin / currentSize.height;
    double rightMargin =
        panel.right == 1.0 ? 0.0 : scaledMargin / currentSize.width;

    BorderRadius borderRadius = new BorderRadius.all(
      new Radius.circular(
        lerpDouble(
          _kUnfocusedCornerRadius,
          _kFocusedCornerRadius,
          focusProgress,
        ),
      ),
    );

    return story.isPlaceHolder
        ? Nothing.widget
        : displayMode == DisplayMode.panels
            ? new SimulatedFractional(
                key: story.positionedKey,
                fractionalTop: panel.top + topMargin,
                fractionalLeft: panel.left + leftMargin,
                fractionalWidth: panel.width - (leftMargin + rightMargin),
                fractionalHeight: panel.height - (topMargin + bottomMargin),
                size: currentSize,
                child: new ClipRRect(
                  borderRadius: borderRadius,
                  child: child,
                ),
              )
            : new SimulatedFractional(
                key: story.positionedKey,
                fractionalTop: 0.0,
                fractionalLeft: 0.0,
                fractionalWidth: 1.0,
                fractionalHeight: (isFocused)
                    ? 1.0
                    : storyBarMaximizedHeight / currentSize.height,
                size: currentSize,
                child: child,
              );
  }
}
