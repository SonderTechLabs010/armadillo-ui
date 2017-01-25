// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'nothing.dart';
import 'story_cluster_id.dart';

const double _kDragTargetHeight = 100.0;
const Color _kDraggableHoverColor = const Color(0x00FFFF00);
const Color _kNoDraggableHoverColor = const Color(0x00FFFF00);
const double _kTargetScrollSpeed = 1500.0;

/// Called whenever an [ArmadilloDragTarget] child of [EdgeScrollDragTarget] is
/// built.
typedef void _BuildCallback(bool hasDraggableAbove);

/// Scroll speed spring simulation
const RK4SpringDescription _kScrollSpeedSimulationDesc =
    const RK4SpringDescription(
  tension: 450.0,
  friction: 50.0,
);

/// The drag targets which cause the given [scrollableKey]'s [Scrollable] to
/// scroll when a draggable hovers over them.
class EdgeScrollDragTarget extends StatefulWidget {
  final GlobalKey<ScrollableState> scrollableKey;

  EdgeScrollDragTarget({Key key, this.scrollableKey}) : super(key: key);

  @override
  EdgeScrollDragTargetState createState() => new EdgeScrollDragTargetState();
}

class EdgeScrollDragTargetState extends TickingState<EdgeScrollDragTarget> {
  final RK4SpringSimulation _scrollSimulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kScrollSpeedSimulationDesc,
  );
  bool _topHadDraggableAbove = false;
  bool _bottomHadDraggableAbove = false;
  bool _enabled = true;
  Duration _lastTimeStamp;

  void disable() {
    if (_enabled) {
      setState(() {
        _enabled = false;
      });
    }
  }

  void enable() {
    if (!_enabled) {
      setState(() {
        _enabled = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => !_enabled
      ? Nothing.widget
      : new Stack(
          children: <Widget>[
            new Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              height: _kDragTargetHeight,
              child: _buildDragTarget(
                onBuild: (bool hasDraggableAbove) {
                  if (_topHadDraggableAbove &&
                      !hasDraggableAbove &&
                      !_bottomHadDraggableAbove) {
                    // Stop the simulation.
                    _scrollSimulation.target = 0.0;
                    startTicking();
                  } else if (!_bottomHadDraggableAbove &&
                      !_topHadDraggableAbove &&
                      hasDraggableAbove) {
                    // Start a simulation toward max
                    _scrollSimulation.target = _kTargetScrollSpeed;
                    startTicking();
                    _scheduleFrameCallback();
                  }
                  _topHadDraggableAbove = hasDraggableAbove;
                },
              ),
            ),
            new Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              height: _kDragTargetHeight,
              child: _buildDragTarget(
                onBuild: (bool hasDraggableAbove) {
                  if (_bottomHadDraggableAbove &&
                      !hasDraggableAbove &&
                      !_topHadDraggableAbove) {
                    // Stop the simulation.
                    _scrollSimulation.target = 0.0;
                    startTicking();
                  } else if (!_bottomHadDraggableAbove &&
                      !_topHadDraggableAbove &&
                      hasDraggableAbove) {
                    // Start a simulation toward min
                    _scrollSimulation.target = -_kTargetScrollSpeed;
                    startTicking();
                    _scheduleFrameCallback();
                  }
                  _bottomHadDraggableAbove = hasDraggableAbove;
                },
              ),
            ),
          ],
        );

  void _scheduleFrameCallback() {
    _lastTimeStamp = null;
    SchedulerBinding.instance.addPostFrameCallback(_frameCallback);
  }

  void _frameCallback(Duration timeStamp) {
    if (_scrollSimulation.target == 0 && _scrollSimulation.isDone) {
      return;
    }
    if (_lastTimeStamp != null) {
      // Set scroll value.
      double scrollDelta = _scrollSimulation.value *
          (timeStamp - _lastTimeStamp).inMicroseconds.toDouble() /
          1000000.0;
      config.scrollableKey.currentState.scrollTo(
          (config.scrollableKey.currentState.scrollOffset + scrollDelta).clamp(
        config.scrollableKey.currentState.scrollBehavior.minScrollOffset,
        config.scrollableKey.currentState.scrollBehavior.maxScrollOffset,
      ));
    }

    _lastTimeStamp = timeStamp;
    SchedulerBinding.instance.addPostFrameCallback(_frameCallback);
  }

  Widget _buildDragTarget({
    Key key,
    _BuildCallback onBuild,
  }) =>
      new ArmadilloDragTarget<StoryClusterId>(
        onWillAccept: (StoryClusterId storyClusterId, Point point) => false,
        onAccept: (StoryClusterId storyClusterId, Point point) => null,
        builder: (
          BuildContext context,
          Map<StoryClusterId, Point> candidateData,
          Map<dynamic, Point> rejectedData,
        ) {
          onBuild(rejectedData.isNotEmpty);
          return new IgnorePointer(
            child: new Container(
              decoration: new BoxDecoration(
                backgroundColor: rejectedData.isEmpty
                    ? _kNoDraggableHoverColor
                    : _kDraggableHoverColor,
              ),
            ),
          );
        },
      );

  @override
  bool handleTick(double elapsedSeconds) {
    bool continueTicking = false;

    if (_scrollSimulation != null) {
      if (!_scrollSimulation.isDone) {
        _scrollSimulation.elapseTime(elapsedSeconds);
        if (!_scrollSimulation.isDone) {
          continueTicking = true;
        }
      }
    }
    return continueTicking;
  }
}
