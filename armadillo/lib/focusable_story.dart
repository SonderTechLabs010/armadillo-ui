// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'story.dart';
import 'story_bar.dart';
import 'story_title.dart';

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

/// The height of the vertical gesture detector used to reveal the story bar in
/// full screen mode.
/// TODO(apwilson): Reduce the height of this.  It's large for now for ease of
/// use.
const double _kVerticalGestureDetectorHeight = 32.0;

const double _kStoryBarMinimizedHeight = 12.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kStoryInlineTitleHeight = 20.0;

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
  final VoidCallback onFocusProgressChanged;
  final bool startFocused;
  FocusableStory(
      {Key key,
      this.story,
      this.multiColumn,
      this.fullSize,
      this.onStoryFocused,
      this.onFocusProgressChanged,
      this.startFocused})
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
  RK4SpringSimulation _focusSimulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kFocusSimulationDesc);
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusSimulation = new RK4SpringSimulation(
      initValue: config.startFocused ? _kFocusSimulationTarget : 0.0,
      desc: _kFocusSimulationDesc,
    );
    _focusSimulation.target = _kFocusSimulationTarget;
    _focused = config.startFocused;
  }

  @override
  void didUpdateConfig(FocusableStory oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.story.id != oldConfig.story.id ||
        ((config.startFocused != oldConfig.startFocused) &&
            config.startFocused)) {
      _focusSimulation = new RK4SpringSimulation(
          initValue: config.startFocused ? _kFocusSimulationTarget : 0.0,
          desc: _kFocusSimulationDesc);
      _focusSimulation.target = _kFocusSimulationTarget;
      _focused = config.startFocused;
    }
  }

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

  double get focusProgress => _focusSimulation.value / _kFocusSimulationTarget;

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
      listener(focusProgress, _focusSimulation.isDone);
    });

    config.onFocusProgressChanged?.call();

    // Notify that the story has come into focus.
    if (_focusSimulation.isDone &&
        focusProgress == 1.0 &&
        config.onStoryFocused != null) {
      config.onStoryFocused(config.story);
    }

    return !_focusSimulation.isDone;
  }

  @override
  Widget build(BuildContext context) {
    return new Offstage(
      offstage: config.story.inactive,
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Story.
          new Flexible(
            child: new ClipRRect(
              borderRadius:
                  new BorderRadius.circular(4.0 * (1.0 - focusProgress)),
              child: new Container(
                decoration:
                    new BoxDecoration(backgroundColor: new Color(0xFFFF0000)),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The story bar that pushes down the story.
                    new StoryBar(
                      key: _storyBarKey,
                      story: config.story,
                      minimizedHeight: _kStoryBarMinimizedHeight,
                      maximizedHeight: _kStoryBarMaximizedHeight,
                      startMaximized: config.startFocused,
                    ),

                    // The scaled and clipped story.  When full size, the story will
                    // no longer be scaled or clipped due to the nature of the
                    // calculations of scale, width, height, and margins above.
                    new Flexible(
                      child: new Stack(
                        children: [
                          // Touch listener that activates in full screen mode.
                          // When a touch comes in we hide the story bar.
                          new Listener(
                            onPointerDown:
                                (focusProgress == 1.0 && !config.multiColumn)
                                    ? (PointerDownEvent event) {
                                        _storyBarKey.currentState.hide();
                                      }
                                    : null,
                            behavior: HitTestBehavior.translucent,
                            child: new OverflowBox(
                              alignment: FractionalOffset.topCenter,
                              minWidth: config.fullSize.width,
                              maxWidth: config.fullSize.width,
                              minHeight: config.fullSize.height -
                                  (config.multiColumn
                                      ? _kStoryBarMaximizedHeight
                                      : 0.0),
                              maxHeight: config.fullSize.height -
                                  (config.multiColumn
                                      ? _kStoryBarMaximizedHeight
                                      : 0.0),
                              child: config.multiColumn
                                  ? config.story.wideBuilder(context)
                                  : config.story.builder(context),
                            ),
                          ),

                          // Vertical gesture detector that activates in full screen
                          // mode.  When a drag down from top of screen occurs we
                          // show the story bar.
                          new Positioned(
                            top: 0.0,
                            left: 0.0,
                            right: 0.0,
                            height: _kVerticalGestureDetectorHeight,
                            child: new GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragUpdate:
                                  (focusProgress == 1.0 && !config.multiColumn)
                                      ? (DragUpdateDetails details) {
                                          _storyBarKey.currentState.show();
                                        }
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Inline Story Title.
          new Container(
            height: _inlineStoryTitleHeight,
            child: new OverflowBox(
              minHeight: _kStoryInlineTitleHeight,
              maxHeight: _kStoryInlineTitleHeight,
              child: new Padding(
                padding: const EdgeInsets.only(
                  left: 8.0,
                  right: 8.0,
                  top: 4.0,
                ),
                child: new Opacity(
                  opacity: 1.0 - focusProgress,
                  child: new Align(
                    alignment: FractionalOffset.bottomLeft,
                    child: new StoryTitle(title: config.story.title),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double get _inlineStoryTitleHeight =>
      _kStoryInlineTitleHeight * (1.0 - focusProgress);

  void addProgressListener(ProgressListener listener) {
    _listeners.add(listener);
  }

  void removeProgressListener(ProgressListener listener) {
    _listeners.remove(listener);
  }
}
