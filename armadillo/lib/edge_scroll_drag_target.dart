// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'kenichi_edge_scrolling.dart';
import 'nothing.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_id.dart';

const Color _kDraggableHoverColor = const Color(0x00FFFF00);
const Color _kNoDraggableHoverColor = const Color(0x00FFFF00);

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
  final KenichiEdgeScrolling _kenichiEdgeScrolling = new KenichiEdgeScrolling();
  bool _enabled = true;

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
      _kenichiEdgeScrolling.onNoDrag();
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
                    double height = box.size.height;
                    double y = height;
                    points.forEach((Point point) {
                      y = math.min(y, point.y);
                    });
                    _kenichiEdgeScrolling.update(y, height);
                    if (!_kenichiEdgeScrolling.isDone) {
                      startTicking();
                    }
                  },
                ),
              ),
            ],
          );
  }

  @override
  bool handleTick(double seconds) {
    // Cancel callbacks if we've disabled the drag targets or we've settled.
    if (!_enabled || _kenichiEdgeScrolling.isDone) {
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
      cumulativeScrollDelta += _kenichiEdgeScrolling.getScrollDelta(stepSize);
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
