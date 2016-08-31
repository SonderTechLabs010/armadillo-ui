// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'story_bar.dart';

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
  final Object id;
  final WidgetBuilder builder;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;
  final Color themeColor;

  Story(
      {this.id,
      this.builder,
      this.lastInteraction,
      this.cumulativeInteractionDuration,
      this.themeColor});

  Story copyWith({DateTime lastInteraction}) => new Story(
      id: this.id,
      builder: this.builder,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      cumulativeInteractionDuration: this.cumulativeInteractionDuration,
      themeColor: this.themeColor);

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

typedef void OnStoryFocused(Story story);
typedef void ProgressListener(double progress, bool isDone);

/// The visual representation of a [Story].  A [Story] has a default size but
/// will expand to [fullSize] when it comes into focus.  [FocusableStory]s are
/// intended to be children of [RecentList].
class FocusableStory extends StatefulWidget {
  final Story story;
  final bool multiColumn;
  final Size fullSize;
  final OnStoryFocused onStoryFocused;
  FocusableStory(
      {Key key,
      this.story,
      this.multiColumn,
      this.fullSize,
      this.onStoryFocused})
      : super(key: key);

  @override
  FocusableStoryState createState() => new FocusableStoryState();
}

const RK4SpringDescription _kFocusSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kFocusSimulationTarget = 200.0;

class FocusableStoryState extends TickingState<FocusableStory> {
  final Set<ProgressListener> _listeners = new Set<ProgressListener>();
  final GlobalKey<StoryBarState> _storyBarKey = new GlobalKey<StoryBarState>();

  /// The simulation for maximizing a [Story] to [config.fullSize].
  final RK4SpringSimulation _focusSimulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kFocusSimulationDesc);
  bool _focused = false;

  bool get focused => _focused;
  set focused(bool focused) {
    if (focused != _focused) {
      _focused = focused;
      _focusSimulation.target = _focused ? _kFocusSimulationTarget : 0.0;
      startTicking();
      if (focused) {
        _storyBarKey.currentState.maximize();
      } else {
        _storyBarKey.currentState.minimize();
      }
    }
  }

  double get _focusProgress => _focusSimulation.value / _kFocusSimulationTarget;

  @override
  bool handleTick(double elapsedSeconds) {
    bool wasDone = _focusSimulation.isDone;
    if (wasDone) {
      return false;
    }

    // Tick the focus simulation.
    _focusSimulation.elapseTime(elapsedSeconds);

    // Notify listeners of progress change.
    _listeners.toList().forEach((ProgressListener listener) {
      listener(_focusProgress, _focusSimulation.isDone);
    });

    // Notify that the story has come into focus.
    if (_focusSimulation.isDone &&
        _focusProgress == 1.0 &&
        config.onStoryFocused != null) {
      config.onStoryFocused(config.story);
    }

    return !_focusSimulation.isDone;
  }

  @override
  Widget build(BuildContext context) {
    double verticalMargin =
        config.story.getVerticalMargin(multiColumn: config.multiColumn) *
            (1.0 - _focusProgress);

    double horizontalMargin = (config.multiColumn
            ? _kMultiColumnMinimumStoryMargin / 2.0
            : _kSingleColumnStoryMargin) *
        (1.0 - _focusProgress);

    double unfocusedStoryHeight = config.story.getHeight(
        multiColumn: config.multiColumn, parentWidth: config.fullSize.width);

    double width = (config.multiColumn
            ? (unfocusedStoryHeight * _kWidthToHeightRatio) +
                (config.fullSize.width -
                        (unfocusedStoryHeight * _kWidthToHeightRatio)) *
                    _focusProgress
            : config.fullSize.width) -
        2.0 * horizontalMargin;

    double height = unfocusedStoryHeight +
        (config.fullSize.height - unfocusedStoryHeight) * _focusProgress;

    // Calculate how much the Story needs to be scaled to fit the card.
    double scale = width / config.fullSize.width;
    Matrix4 transform = new Matrix4.identity();
    transform.scale(scale, scale);

    return new Padding(
      padding: new EdgeInsets.symmetric(
          vertical: verticalMargin, horizontal: horizontalMargin),
      child: new ClipRRect(
        borderRadius: new BorderRadius.circular(4.0 * (1.0 - _focusProgress)),
        child: new Container(
          decoration: new BoxDecoration(backgroundColor: new Color(0xFFFF0000)),
          height: height,
          width: width,
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The story bar that pushes down the story.
              new StoryBar(
                key: _storyBarKey,
                color: config.story.themeColor,
              ),

              // The scaled and clipped story.  When full size, the story will
              // no longer be scaled or clipped due to the nature of the
              // calculations of scale, width, height, and margins above.
              new Flexible(
                child: new Transform(
                  transform: transform,
                  alignment: FractionalOffset.topCenter,
                  child: new Stack(
                    children: [
                      // Touch listener that activates in full screen mode.
                      // When a touch comes in we hide the story bar.
                      new Listener(
                        onPointerDown: (_focusProgress == 1.0)
                            ? (PointerDownEvent event) {
                                _storyBarKey.currentState.hide();
                              }
                            : null,
                        behavior: HitTestBehavior.translucent,
                        child: new OverflowBox(
                          alignment: FractionalOffset.topCenter,
                          minWidth: config.fullSize.width,
                          maxWidth: config.fullSize.width,
                          minHeight: config.fullSize.height,
                          maxHeight: config.fullSize.height,
                          child: config.story.builder(context),
                        ),
                      ),

                      // Vertical gesture detector that activates in full screen
                      // mode.  When a drag down from top of screen occurs we
                      // show the story bar.
                      new Positioned(
                        top: 0.0,
                        left: 0.0,
                        right: 0.0,
                        height: 16.0,
                        child: new GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onVerticalDragUpdate: (_focusProgress == 1.0)
                              ? (DragUpdateDetails details) {
                                  _storyBarKey.currentState.show();
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addProgressListener(ProgressListener listener) {
    _listeners.add(listener);
  }

  void removeProgressListener(ProgressListener listener) {
    _listeners.remove(listener);
  }
}
