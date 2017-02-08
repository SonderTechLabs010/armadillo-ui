// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'nothing.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_id.dart';

const Color _kDraggableHoverColor = const Color(0x00FFFF00);
const Color _kNoDraggableHoverColor = const Color(0x00FFFF00);
const double _kDragScrollThreshold = 120.0;

/// Called whenever an [ArmadilloDragTarget] child of [EdgeScrollDragTarget] is
/// built.
typedef void _BuildCallback(bool hasDraggableAbove, List<Point> points);

/// The drag targets which cause the given [scrollableKey]'s [Scrollable] to
/// scroll when a draggable hovers over them.
class EdgeScrollDragTarget extends StatefulWidget {
  final GlobalKey<ScrollableState> scrollableKey;

  EdgeScrollDragTarget({Key key, this.scrollableKey}) : super(key: key);

  @override
  EdgeScrollDragTargetState createState() => new EdgeScrollDragTargetState();
}

class EdgeScrollDragTargetState extends TickingState<EdgeScrollDragTarget> {
  bool _enabled = true;
  double _currentVelocity = 0.0;
  double _lastHeight = 2.0 * _kDragScrollThreshold;
  double _y = _kDragScrollThreshold;

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
  Widget build(BuildContext context) {
    bool clusterBeingDragged = StoryClusterDragStateModel
        .of(context, rebuildOnChange: true)
        .isDragging;
    if (!_enabled || !clusterBeingDragged) {
      _y = _lastHeight / 2.0;
    }
    return !_enabled || !clusterBeingDragged
        ? Nothing.widget
        : new Stack(
            children: <Widget>[
              new Positioned(
                top: 0.0,
                left: 0.0,
                right: 0.0,
                bottom: 0.0,
                child: _buildDragTarget(
                  onBuild: (bool hasDraggableAbove, List<Point> points) {
                    RenderBox box = context.findRenderObject();
                    _lastHeight = box.size.height;
                    _y = _lastHeight;
                    points.forEach((Point point) {
                      _y = math.min(_y, point.y);
                    });
                    if (_shouldScrollUp || _shouldScrollDown) {
                      startTicking();
                    }
                  },
                ),
              ),
            ],
          );
  }

  bool get _shouldScrollUp => _y < _kDragScrollThreshold;
  bool get _shouldScrollDown => _y > _lastHeight - _kDragScrollThreshold;

  @override
  bool handleTick(double seconds) {
    // Cancel callbacks if we've disabled the drag targets or we've settled.
    if (!_enabled ||
        (_currentVelocity == 0.0 && !_shouldScrollUp && !_shouldScrollDown)) {
      return false;
    }

    double minScrollOffset =
        config.scrollableKey.currentState.scrollBehavior.minScrollOffset;
    double maxScrollOffset =
        config.scrollableKey.currentState.scrollBehavior.maxScrollOffset;
    double currentScrollOffset = config.scrollableKey.currentState.scrollOffset;

    double cumulativeScrollDelta = 0.0;
    double secondsRemaining = seconds;
    final double _kMaxStepSize = 1 / 60;
    while (secondsRemaining > 0.0) {
      double stepSize =
          secondsRemaining > _kMaxStepSize ? _kMaxStepSize : secondsRemaining;
      cumulativeScrollDelta += _getScrollAmount(stepSize);
      secondsRemaining -= _kMaxStepSize;
    }
    config.scrollableKey.currentState.scrollTo(
      (currentScrollOffset + cumulativeScrollDelta).clamp(
        minScrollOffset,
        maxScrollOffset,
      ),
    );
    return true;
  }

  double _getScrollAmount(double seconds) {
    const double a = 1.0;
    const double b = 0.5;
    const double c = 1.5;
    const double d = 0.02;
    const double e = 2.0;

    // If we should scroll up, accelerate upward.
    if (_shouldScrollUp) {
      _currentVelocity += math.pow(
              math.min(
                1.0,
                (_kDragScrollThreshold - _y) / _kDragScrollThreshold * e,
              ),
              a) *
          b *
          seconds *
          60;
    }

    // If we should scroll down, accelerate downward.
    if (_shouldScrollDown) {
      _currentVelocity -= math.pow(
              math.min(
                1.0,
                (_y - (_lastHeight - _kDragScrollThreshold)) /
                    _kDragScrollThreshold *
                    e,
              ),
              a) *
          b *
          seconds *
          60;
    }

    // Apply friction.
    double friction;
    if (_y < (_lastHeight / 2)) {
      friction = math.pow(math.max(0.0, _y) / _kDragScrollThreshold, c) * d;
    } else {
      friction = math.pow(
              math.max(0.0, (_lastHeight - _y)) / _kDragScrollThreshold, c) *
          d;
    }
    _currentVelocity -= _currentVelocity * friction * seconds * 60;

    // Once we drop below a certian threshold, jump to 0.0.
    if (_currentVelocity.abs() < 0.1) {
      _currentVelocity = 0.0;
    }

    return _currentVelocity * seconds * 60;
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
          onBuild(rejectedData.isNotEmpty, rejectedData.values.toList());
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
}
