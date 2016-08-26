// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

/// The minimum story height.
const double _kMinimumStoryHeight = 200.0;

/// In multicolumn mode, the distance from the parent's edge the largest story
/// will be.
const double _kMultiColumnMargin = 64.0;

/// In multicolumn mode, the aspect ratio of a story.
const double _kWidthToHeightRatio = 16.0 / 9.0;

/// In single column mode, the distance from a story and other UI elements.
const double _kSingleColumnStoryMargin = 8.0;

/// In multicolumn mode, the minimum distance from a story and other UI
/// elements.
const double _kMultiColumnMinimumStoryMargin = 8.0;

/// The representation of a Story.  A Story's contents are display as a [Widget]
/// provided by [builder] while the size of a story in the [RecentList] is
/// determined by [lastInteraction] and [cumulativeInteractionDuration].
class Story {
  final WidgetBuilder builder;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;

  Story(
      {this.builder, this.lastInteraction, this.cumulativeInteractionDuration});

  /// A [Story] is bigger if it has been used often and recently.
  double getHeight({bool multiColumn, double parentWidth}) {
    double sizeFactor = 1.0;
    if (multiColumn) {
      double maxStoryWidth = (parentWidth / 2.0 - _kMultiColumnMargin);
      double maxStoryHeight = maxStoryWidth / _kWidthToHeightRatio;
      sizeFactor = maxStoryHeight / (2.0 * _kMinimumStoryHeight);
    }
    double sizeRatio =
        1.0 + (_culmulativeInteractionDurationRatio * _lastInteractionRatio);
    return _kMinimumStoryHeight * sizeRatio * sizeFactor;
  }

  double getVerticalMargin({bool multiColumn}) {
    return multiColumn
        ? _kMultiColumnMinimumStoryMargin * (0.25 + _lastInteractionRatio) * 2.0
        : _kSingleColumnStoryMargin / 2.0;
  }

  double get _culmulativeInteractionDurationRatio =>
      cumulativeInteractionDuration.inMinutes.toDouble() / 60.0;

  double get _lastInteractionRatio =>
      1.0 -
      math.min(
          1.0,
          new DateTime.now().difference(lastInteraction).inMinutes.toDouble() /
              60.0);
}

/// The visual representation of a [Story].  A [Story] has a default size but
/// will expand to [fullSize] when it comes into focus.  [FocusableStory]s are
/// intended to be children of [RecentList].
class FocusableStory extends StatefulWidget {
  final Story story;
  final bool multiColumn;
  final Size fullSize;
  FocusableStory({Key key, this.story, this.multiColumn, this.fullSize})
      : super(key: key);

  @override
  FocusableStoryState createState() => new FocusableStoryState();
}

const RK4SpringDescription _kFocusSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kFocusSimulationTarget = 100.0;

class FocusableStoryState extends TickingState<FocusableStory> {
  /// The simulation for maximizing a [Story] to [config.fullSize].
  final RK4SpringSimulation _focusSimulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kFocusSimulationDesc);
  bool _focused = false;

  bool get focused => _focused;
  set focused(bool focused) {
    _focused = focused;
    _focusSimulation.target = _focused ? _kFocusSimulationTarget : 0.0;
    startTicking();
  }

  double get _focusProgress => _focusSimulation.value / _kFocusSimulationTarget;

  @override
  bool handleTick(double elapsedSeconds) {
    // Tick the minimization simulation.
    _focusSimulation.elapseTime(elapsedSeconds);
    return !_focusSimulation.isDone;
  }

  @override
  Widget build(BuildContext context) {
    double unfocusedStoryHeight = config.story.getHeight(
        multiColumn: config.multiColumn, parentWidth: config.fullSize.width);
    return new Container(
        height: unfocusedStoryHeight +
            (config.fullSize.height - unfocusedStoryHeight) * _focusProgress,
        width: config.multiColumn
            ? (unfocusedStoryHeight * _kWidthToHeightRatio) +
                (config.fullSize.width -
                        (unfocusedStoryHeight * _kWidthToHeightRatio)) *
                    _focusProgress -
                _kMultiColumnMinimumStoryMargin * (1.0 - _focusProgress)
            : config.fullSize.width -
                2.0 * _kSingleColumnStoryMargin * (1.0 - _focusProgress),
        margin: new EdgeInsets.symmetric(
            vertical: config.story
                    .getVerticalMargin(multiColumn: config.multiColumn) *
                (1.0 - _focusProgress),
            horizontal: (config.multiColumn
                    ? _kMultiColumnMinimumStoryMargin / 2.0
                    : _kSingleColumnStoryMargin) *
                (1.0 - _focusProgress)),
        child: new ClipRRect(
            borderRadius:
                new BorderRadius.circular(4.0 * (1.0 - _focusProgress)),
            child: config.story.builder(context)));
  }
}
