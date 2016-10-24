// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'panel.dart';
import 'place_holder_story.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_manager.dart';

const double _kLineWidth = 4.0;
const double _kTopEdgeTargetYOffset = 16.0;
const double _kDiscardTargetTopEdgeYOffset = -48.0;
const double _kBringToFrontTargetBottomEdgeYOffset = 48.0;
const double _kStoryBarTargetYOffset = -16.0;
const double _kStoryTopEdgeTargetYOffset = 48.0;
const double _kStoryEdgeTargetInset = 16.0;
const int _kMaxStoriesPerCluster = 100;
const double _kAddedStorySpan = 0.01;
const Color _kEdgeTargetColor = const Color(0xFFFFFF00);
const Color _kStoryBarTargetColor = const Color(0xFF00FFFF);
const Color _kDiscardTargetColor = const Color(0xFFFF0000);
const Color _kBringToFrontTargetColor = const Color(0xFF00FF00);
const Color _kStoryEdgeTargetColor = const Color(0xFF0000FF);

/// Set to true to draw target lines.
const bool _kDrawTargetLines = false;

/// Once a drag target is chosen, this is the distance a draggable must travel
/// before new drag targets are considered.
const double _kStickyDistance = 32.0;

const RK4SpringDescription _kScaleSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

typedef void _OnPanelEvent(BuildContext context, StoryCluster storyCluster);

/// Details about a target used by [PanelDragTargets].
///
/// [LineSegment] specifies a line from [a] to [b].
/// When turned into a widget the [LineSegment] will have the color [color].
/// When the [LineSegment] is being targeted by a draggable [onHover] will be
/// called.
/// When the [LineSegment] is dropped upon with a draggable [onDropped] will be
/// called.
/// This [LineSegment] can only be targeted by [StoryCluster]s with a story
/// count of less than or equal to [maxStoriesCanAccept].
class LineSegment {
  /// [a] always aligns with [b] in either vertically or horizontally.
  /// [a] is always 'less than' [b] in x or y direction.
  final Point a;
  final Point b;
  final Color color;
  final _OnPanelEvent onHover;
  final _OnPanelEvent onDrop;
  final int maxStoriesCanAccept;

  LineSegment(
    Point a,
    Point b, {
    this.color: const Color(0xFFFFFFFF),
    this.onHover,
    this.onDrop,
    this.maxStoriesCanAccept: 1,
  })
      : this.a = (a.x < b.x || a.y < b.y) ? a : b,
        this.b = (a.x < b.x || a.y < b.y) ? b : a {
    // Ensure the line is either vertical or horizontal.
    assert(a.x == b.x || a.y == b.y);
  }

  factory LineSegment.vertical({
    double x,
    double top,
    double bottom,
    Color color,
    _OnPanelEvent onHover,
    _OnPanelEvent onDrop,
    int maxStoriesCanAccept,
  }) =>
      new LineSegment(
        new Point(x, top),
        new Point(x, bottom),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
      );

  factory LineSegment.horizontal({
    double y,
    double left,
    double right,
    Color color,
    _OnPanelEvent onHover,
    _OnPanelEvent onDrop,
    int maxStoriesCanAccept,
  }) =>
      new LineSegment(
        new Point(left, y),
        new Point(right, y),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
      );

  bool get isHorizontal => a.y == b.y;
  bool get isVertical => !isHorizontal;
  bool canAccept(StoryCluster storyCluster) =>
      storyCluster.stories.length <= maxStoriesCanAccept;

  double distanceFrom(Point p) {
    if (isHorizontal) {
      if (p.x < a.x) {
        return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2));
      } else if (p.x > b.x) {
        return math.sqrt(math.pow(p.x - b.x, 2) + math.pow(p.y - b.y, 2));
      } else {
        return (p.y - a.y).abs();
      }
    } else {
      if (p.y < a.y) {
        return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2));
      } else if (p.y > b.y) {
        return math.sqrt(math.pow(p.x - b.x, 2) + math.pow(p.y - b.y, 2));
      } else {
        return (p.x - a.x).abs();
      }
    }
  }

  Positioned buildStackChild({bool highlighted: false}) => new Positioned(
        left: a.x - _kLineWidth / 2.0,
        top: a.y - _kLineWidth / 2.0,
        width: isHorizontal ? b.x - a.x + _kLineWidth : _kLineWidth,
        height: isVertical ? b.y - a.y + _kLineWidth : _kLineWidth,
        child: new Container(
          decoration: new BoxDecoration(
            backgroundColor: color.withOpacity(highlighted ? 1.0 : 0.3),
          ),
        ),
      );

  @override
  String toString() =>
      'LineSegment(a: $a, b: $b, color: $color, maxStoriesCanAccept: $maxStoriesCanAccept)';
}

/// Wraps its [child] in an [ArmadilloDragTarget] which tracks any
/// [ArmadilloLongPressDraggable]'s above it such that they can be dropped on
/// specific parts of [storyCluster]'s [storyCluster.stories]'s [Panel]s.
///
/// When an [ArmadilloLongPressDraggable] is above, [child] will be scaled down
/// slightly depending on [focusProgress].
class PanelDragTargets extends StatefulWidget {
  final StoryCluster storyCluster;
  final Size fullSize;
  final Widget child;
  final double scale;
  final double focusProgress;
  final Set<LineSegment> _targetLines = new Set<LineSegment>();

  PanelDragTargets({
    Key key,
    this.storyCluster,
    this.fullSize,
    this.child,
    this.scale,
    this.focusProgress,
  })
      : super(key: key);

  @override
  PanelDragTargetsState createState() => new PanelDragTargetsState();
}

class PanelDragTargetsState extends TickingState<PanelDragTargets> {
  final Set<LineSegment> _targetLines = new Set<LineSegment>();
  final Map<StoryCluster, Point> _closestTargetLockPoints =
      new Map<StoryCluster, Point>();
  final Map<StoryCluster, LineSegment> _closestTargets =
      new Map<StoryCluster, LineSegment>();
  final RK4SpringSimulation _scaleSimulation = new RK4SpringSimulation(
    initValue: 1.0,
    desc: _kScaleSimulationDesc,
  );

  @override
  void initState() {
    super.initState();
    _populateTargetLines();
    config.storyCluster.addStoryListListener(_populateTargetLines);
  }

  @override
  void didUpdateConfig(PanelDragTargets oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.storyCluster.id != config.storyCluster.id) {
      oldConfig.storyCluster.removeStoryListListener(_populateTargetLines);
      config.storyCluster.addStoryListListener(_populateTargetLines);
    }
  }

  @override
  void dispose() {
    config.storyCluster.removeStoryListListener(_populateTargetLines);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new ArmadilloDragTarget<StoryClusterId>(
      onWillAccept: (StoryClusterId storyClusterId, Point point) => true,
      onAccept: (StoryClusterId storyClusterId, Point point) {
        StoryCluster storyCluster =
            InheritedStoryManager.of(context).getStoryCluster(storyClusterId);
        return _getClosestLine(point, storyCluster)
            .onDrop
            ?.call(context, storyCluster);
      },
      builder: (
        BuildContext context,
        Map<StoryClusterId, Point> storyClusterIdCandidates,
        Map<dynamic, Point> rejectedData,
      ) {
        Map<StoryCluster, Point> storyClusterCandidates = {};
        storyClusterIdCandidates.keys.forEach((StoryClusterId storyClusterId) {
          StoryCluster storyCluster =
              InheritedStoryManager.of(context).getStoryCluster(storyClusterId);
          storyClusterCandidates[storyCluster] =
              storyClusterIdCandidates[storyClusterId];
        });

        _updateClosestTargets(storyClusterCandidates);

        double newScale = storyClusterCandidates.isEmpty ? 1.0 : config.scale;
        if (_scaleSimulation.target != newScale) {
          _scaleSimulation.target = newScale;
          startTicking();
        }

        // Scale the child.
        double childScale = _scaleSimulation.value;

        List<Widget> stackChildren = [
          new Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: new Transform(
              transform: new Matrix4.identity().scaled(childScale, childScale),
              alignment: FractionalOffset.center,
              child: config.child,
            ),
          )
        ];

        // When we have a candidate and we're fully focused, show the target
        // lines.
        if (_kDrawTargetLines &&
            storyClusterCandidates.isNotEmpty &&
            config.focusProgress == 1.0) {
          // Add all the lines.
          stackChildren.addAll(
            _targetLines
                .where(
                  (LineSegment line) => !storyClusterCandidates.keys.every(
                        (StoryCluster key) => !line.canAccept(key),
                      ),
                )
                .map(
                  (LineSegment line) => line.buildStackChild(),
                ),
          );
        }
        return new Stack(children: stackChildren);
      });

  @override
  bool handleTick(double elapsedSeconds) {
    _scaleSimulation.elapseTime(elapsedSeconds);
    return !_scaleSimulation.isDone;
  }

  void _updateClosestTargets(Map<StoryCluster, Point> storyClusterCandidates) {
    // Remove any candidates that no longer exist.
    _closestTargetLockPoints.keys.toList().forEach((StoryCluster storyCluster) {
      if (!storyClusterCandidates.keys.contains(storyCluster)) {
        _closestTargetLockPoints[storyCluster] = null;
        _closestTargets[storyCluster] = null;
      }
    });

    // For each candidate...
    storyClusterCandidates.keys.forEach((StoryCluster storyCluster) {
      LineSegment closestLine =
          _getClosestLine(storyClusterCandidates[storyCluster], storyCluster);
      Point lockPoint = _closestTargetLockPoints[storyCluster];

      // ... lock to its closest line if this is the first time we've seen the
      // candidate or it's an existing candidate whose closest line has changed
      // and we've moved past the sticky distance for its lock point.
      if ((lockPoint == null) ||
          _closestTargets[storyCluster] != closestLine &&
              ((lockPoint - storyClusterCandidates[storyCluster]).distance >
                  _kStickyDistance)) {
        _lockClosestTarget(
          storyCluster: storyCluster,
          point: storyClusterCandidates[storyCluster],
          closestLine: closestLine,
        );
      }
    });
  }

  void _lockClosestTarget({
    StoryCluster storyCluster,
    Point point,
    LineSegment closestLine,
  }) {
    _closestTargetLockPoints[storyCluster] = point;
    _closestTargets[storyCluster] = closestLine;
    closestLine.onHover?.call(context, storyCluster);
  }

  LineSegment _getClosestLine(Point point, StoryCluster storyCluster) {
    double minDistance = double.INFINITY;
    LineSegment closestLine;
    _targetLines
        .where((LineSegment line) => line.canAccept(storyCluster))
        .forEach((LineSegment line) {
      double targetLineDistance = line.distanceFrom(point);
      if (targetLineDistance < minDistance) {
        minDistance = targetLineDistance;
        closestLine = line;
      }
    });
    return closestLine;
  }

  /// Creates the target lines for the configuration of panels represented by
  /// the story cluster's stories.
  ///
  /// Typically this includes the following targets:
  ///   1) Discard story target.
  ///   2) Bring to front target.
  ///   3) Convert to tabs target.
  ///   4) Edge targets on top, bottom, left, and right of the cluster.
  ///   5) Edge targets on top, bottom, left, and right of each panel.
  void _populateTargetLines() {
    // Only update target lines if there are no placeholders.
    if (!config.storyCluster.stories
        .every((Story story) => !story.isPlaceHolder)) {
      return;
    }

    _targetLines.clear();
    double verticalMargin = (1.0 - config.scale) / 2.0 * config.fullSize.height;
    double horizontalMargin =
        (1.0 - config.scale) / 2.0 * config.fullSize.width;

    int availableRows = maxRows(config.fullSize) - _currentRows;
    if (availableRows > 0) {
      // Top edge target.
      _targetLines.add(
        new LineSegment.horizontal(
          y: verticalMargin + _kTopEdgeTargetYOffset,
          left: horizontalMargin + _kStoryEdgeTargetInset,
          right:
              config.fullSize.width - horizontalMargin - _kStoryEdgeTargetInset,
          color: _kEdgeTargetColor,
          maxStoriesCanAccept: availableRows,
          onHover: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterAbovePanels(
                context: context,
                storyCluster: storyCluster,
                preview: true,
              ),
          onDrop: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterAbovePanels(
                context: context,
                storyCluster: storyCluster,
              ),
        ),
      );

      // Bottom edge target.
      _targetLines.add(
        new LineSegment.horizontal(
          y: config.fullSize.height - verticalMargin,
          left: horizontalMargin + _kStoryEdgeTargetInset,
          right:
              config.fullSize.width - horizontalMargin - _kStoryEdgeTargetInset,
          color: _kEdgeTargetColor,
          maxStoriesCanAccept: availableRows,
          onHover: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterBelowPanels(
                context: context,
                storyCluster: storyCluster,
                preview: true,
              ),
          onDrop: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterBelowPanels(
                context: context,
                storyCluster: storyCluster,
              ),
        ),
      );
    }

    // Left edge target.
    int availableColumns = maxColumns(config.fullSize) - _currentColumns;
    if (availableColumns > 0) {
      _targetLines.add(
        new LineSegment.vertical(
          x: horizontalMargin,
          top: verticalMargin,
          bottom:
              config.fullSize.height - verticalMargin - _kStoryEdgeTargetInset,
          color: _kEdgeTargetColor,
          maxStoriesCanAccept: availableColumns,
          onHover: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterToLeftOfPanels(
                context: context,
                storyCluster: storyCluster,
                preview: true,
              ),
          onDrop: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterToLeftOfPanels(
                context: context,
                storyCluster: storyCluster,
              ),
        ),
      );

      // Right edge target.
      _targetLines.add(
        new LineSegment.vertical(
          x: config.fullSize.width - horizontalMargin,
          top: verticalMargin,
          bottom:
              config.fullSize.height - verticalMargin - _kStoryEdgeTargetInset,
          color: _kEdgeTargetColor,
          maxStoriesCanAccept: availableColumns,
          onHover: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterToRightOfPanels(
                context: context,
                storyCluster: storyCluster,
                preview: true,
              ),
          onDrop: (BuildContext context, StoryCluster storyCluster) =>
              _addClusterToRightOfPanels(
                context: context,
                storyCluster: storyCluster,
              ),
        ),
      );
    }

    // Story Bar target.
    _targetLines.add(
      new LineSegment.horizontal(
        y: verticalMargin + _kStoryBarTargetYOffset,
        left: horizontalMargin + _kStoryEdgeTargetInset,
        right:
            config.fullSize.width - horizontalMargin - _kStoryEdgeTargetInset,
        color: _kStoryBarTargetColor,
        maxStoriesCanAccept:
            _kMaxStoriesPerCluster - config.storyCluster.stories.length,
        onHover: (BuildContext context, StoryCluster storyCluster) {
          config.storyCluster.removePreviews();
          _cleanup(context: context, preview: true);
          _updateDragFeedback(storyCluster.dragFeedbackKey);

          // TODO(apwilson): Switch all the stories involved into tabs.
        },
        onDrop: (BuildContext context, StoryCluster storyCluster) {
          config.storyCluster.removePreviews();
          _cleanup(context: context, preview: true);

          // TODO(apwilson): Switch all the stories involved into tabs.
        },
      ),
    );

    // Top discard target.
    _targetLines.add(
      new LineSegment.horizontal(
        y: verticalMargin + _kDiscardTargetTopEdgeYOffset,
        left: horizontalMargin * 3.0,
        right: config.fullSize.width - 3.0 * horizontalMargin,
        color: _kDiscardTargetColor,
        maxStoriesCanAccept: _kMaxStoriesPerCluster,
        onHover: (BuildContext context, StoryCluster storyCluster) {
          config.storyCluster.removePreviews();
          _cleanup(context: context, preview: true);
          _updateDragFeedback(storyCluster.dragFeedbackKey);
        },
        onDrop: (BuildContext context, StoryCluster storyCluster) {
          config.storyCluster.removePreviews();
          _cleanup(context: context, preview: true);

          // TODO(apwilson): Animate storyCluster away.
        },
      ),
    );

    // Bottom bring-to-front target.
    _targetLines.add(
      new LineSegment.horizontal(
        y: config.fullSize.height -
            verticalMargin +
            _kBringToFrontTargetBottomEdgeYOffset,
        left: horizontalMargin * 3.0,
        right: config.fullSize.width - 3.0 * horizontalMargin,
        color: _kBringToFrontTargetColor,
        maxStoriesCanAccept: _kMaxStoriesPerCluster,
        onHover: (BuildContext context, StoryCluster storyCluster) {
          config.storyCluster.removePreviews();
          _cleanup(context: context, preview: true);
          _updateDragFeedback(storyCluster.dragFeedbackKey);
        },
        onDrop: (BuildContext context, StoryCluster storyCluster) {
          config.storyCluster.removePreviews();
          _cleanup(context: context, preview: true);

          // TODO(apwilson): Defocus this cluster away.
          // Bring storyCluster into focus.
        },
      ),
    );

    // Story edge targets.
    Point center =
        new Point(config.fullSize.width / 2.0, config.fullSize.height / 2.0);
    config.storyCluster.stories.forEach((Story story) {
      Rect bounds = _transform(story.panel, center, config.fullSize);

      // If we can split vertically add vertical targets on left and right.
      int verticalSplits = _getVerticalSplitCount(story.panel);
      if (verticalSplits > 0) {
        double left = bounds.left + _kStoryEdgeTargetInset;
        double right = bounds.right - _kStoryEdgeTargetInset;
        double top = bounds.top +
            _kStoryEdgeTargetInset +
            (story.panel.top == 0.0
                ? _kStoryTopEdgeTargetYOffset
                : 2.0 * _kStoryEdgeTargetInset);
        double bottom =
            bounds.bottom - _kStoryEdgeTargetInset - _kStoryEdgeTargetInset;

        // Add left target.
        _targetLines.add(
          new LineSegment.vertical(
            x: left,
            top: top,
            bottom: bottom,
            color: _kStoryEdgeTargetColor,
            maxStoriesCanAccept: verticalSplits,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToLeftOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToLeftOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                ),
          ),
        );

        // Add right target.
        _targetLines.add(
          new LineSegment.vertical(
            x: right,
            top: top,
            bottom: bottom,
            color: _kStoryEdgeTargetColor,
            maxStoriesCanAccept: verticalSplits,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToRightOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToRightOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                ),
          ),
        );
      }

      // If we can split horizontally add horizontal targets on top and bottom.
      int horizontalSplits = _getHorizontalSplitCount(story.panel);
      if (horizontalSplits > 0) {
        double top = bounds.top +
            (story.panel.top == 0.0
                ? _kStoryTopEdgeTargetYOffset
                : _kStoryEdgeTargetInset);
        double left =
            bounds.left + _kStoryEdgeTargetInset + _kStoryEdgeTargetInset;
        double right =
            bounds.right - _kStoryEdgeTargetInset - _kStoryEdgeTargetInset;
        double bottom = bounds.bottom - _kStoryEdgeTargetInset;

        // Add top target.
        _targetLines.add(
          new LineSegment.horizontal(
            y: top,
            left: left,
            right: right,
            color: _kStoryEdgeTargetColor,
            maxStoriesCanAccept: horizontalSplits,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterAbovePanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterAbovePanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                ),
          ),
        );

        // Add bottom target.
        _targetLines.add(
          new LineSegment.horizontal(
            y: bottom,
            left: left,
            right: right,
            color: _kStoryEdgeTargetColor,
            maxStoriesCanAccept: horizontalSplits,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterBelowPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterBelowPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: story.id,
                ),
          ),
        );
      }
    });
  }

  /// Adds the stories of [storyCluster] to the left, spanning the full height.
  void _addClusterToLeftOfPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: config.storyCluster.panels
          .where((Panel panel) => panel.left == 0)
          .toList(),
      leftDelta: (_kAddedStorySpan * storiesToAdd.length),
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: 0.0,
      top: 0.0,
      bottom: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  /// Adds the stories of [storyCluster] to the right, spanning the full height.
  void _addClusterToRightOfPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: config.storyCluster.panels
          .where((Panel panel) => panel.right == 1.0)
          .toList(),
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: 1.0 - (_kAddedStorySpan * storiesToAdd.length),
      top: 0.0,
      bottom: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  /// Adds the stories of [storyCluster] to the top, spanning the full width.
  void _addClusterAbovePanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: config.storyCluster.panels
          .where((Panel panel) => panel.top == 0.0)
          .toList(),
      topDelta: (_kAddedStorySpan * storiesToAdd.length),
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: 0.0,
      left: 0.0,
      right: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  /// Adds the stories of [storyCluster] to the bottom, spanning the full width.
  void _addClusterBelowPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    // 1) Make room for new stories.
    _makeRoom(
      panels: config.storyCluster.panels
          .where((Panel panel) => panel.bottom == 1.0)
          .toList(),
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 2) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: 1.0 - (_kAddedStorySpan * storiesToAdd.length),
      left: 0.0,
      right: 1.0,
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  Panel _getPanelFromStoryId(Object storyId) => config.storyCluster.stories
      .where((Story s) => storyId == s.id)
      .single
      .panel;

  /// Adds the stories of [storyCluster] to the left of [panel], spanning
  /// [panel]'s height.
  void _addClusterToLeftOfPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: panel.left,
      top: panel.top,
      bottom: panel.bottom,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: [panel],
      leftDelta: (_kAddedStorySpan * storiesToAdd.length),
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  /// Adds the stories of [storyCluster] to the right of [panel], spanning
  /// [panel]'s height.
  void _addClusterToRightOfPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getHorizontallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesHorizontally(
      stories: storiesToAdd,
      x: panel.right - storiesToAdd.length * _kAddedStorySpan,
      top: panel.top,
      bottom: panel.bottom,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: [panel],
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  /// Adds the stories of [storyCluster] to the top of [panel], spanning
  /// [panel]'s width.
  void _addClusterAbovePanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: panel.top,
      left: panel.left,
      right: panel.right,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: [panel],
      topDelta: (_kAddedStorySpan * storiesToAdd.length),
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  /// Adds the stories of [storyCluster] to the bottom of [panel], spanning
  /// [panel]'s width.
  void _addClusterBelowPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    // 0) Remove any existing preview stories.
    config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.stories.length,
            (int index) => new PlaceHolderStory(
                  index: index,
                  associatedStoryId: storyCluster.stories[index].id,
                ),
          )
        : _getVerticallySortedStories(storyCluster);

    Panel panel = _getPanelFromStoryId(storyId);

    // 1) Add new stories.
    _addStoriesVertically(
      stories: storiesToAdd,
      y: panel.bottom - storiesToAdd.length * _kAddedStorySpan,
      left: panel.left,
      right: panel.right,
    );

    // 2) Make room for new stories.
    _makeRoom(
      panels: [panel],
      heightFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  void _cleanup({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview,
  }) {
    // 1) Normalize sizes.
    _normalizeSizes();

    // 2) Remove dropped cluster from story manager.
    // NOTE: We do this in a microtask because of the following:
    //   a) Messing with the [StoryManager] could cause a setState call.
    //   b) This function could be called while we're building (due to an
    //      onHover callback).
    //   c) Causing a setState while building is a big Flutter no-no.
    scheduleMicrotask(() {
      if (!preview) {
        InheritedStoryManager
            .of(context)
            .remove(storyClusterId: storyCluster.id);
      } else {
        InheritedStoryManager.of(context).notifyListeners();
      }
    });
  }

  void _updateDragFeedback(
    GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey,
  ) {
    Map<Object, Panel> panelMap = <Object, Panel>{};

    config.storyCluster.stories
        .where((Story story) => story.isPlaceHolder)
        .forEach((PlaceHolderStory story) {
      panelMap[story.associatedStoryId] = story.panel;
    });

    // NOTE: We do this in a microtask because of the following:
    //   a) Messing with the [StoryClusterDragFeedbackState] could cause a
    //      setState call.
    //   b) This function could be called while we're building (due to an
    //      onHover callback).
    //   c) Causing a setState while building is a big Flutter no-no.
    scheduleMicrotask(() {
      dragFeedbackKey.currentState?.storyPanels = panelMap;
    });
  }

  void _normalizeSizes() => config.storyCluster.normalizeSizes();

  /// Resizes the existing panels just enough to add new ones.
  void _makeRoom({
    List<Panel> panels,
    double topDelta: 0.0,
    double leftDelta: 0.0,
    double widthFactorDelta: 0.0,
    double heightFactorDelta: 0.0,
  }) {
    panels.forEach((Panel panel) {
      config.storyCluster.replace(
        panel: panel,
        withPanel: new Panel(
          origin: new FractionalOffset(
            panel.left + leftDelta,
            panel.top + topDelta,
          ),
          widthFactor: panel.width + widthFactorDelta,
          heightFactor: panel.height + heightFactorDelta,
        ),
      );
    });
  }

  /// Adds stories horizontally starting from [x] with vertical bounds of
  /// [top] to [bottom].
  void _addStoriesHorizontally({
    List<Story> stories,
    double x,
    double top,
    double bottom,
  }) {
    double dx = x;
    stories.forEach((Story story) {
      config.storyCluster.add(
        story: story,
        withPanel: new Panel(
          origin: new FractionalOffset(dx, top),
          widthFactor: _kAddedStorySpan,
          heightFactor: bottom - top,
        ),
      );
      dx += _kAddedStorySpan;
      story.storyBarKey.currentState?.maximize(jumpToFinish: true);
    });
  }

  /// Adds stories vertically starting from [y] with horizontal bounds of
  /// [left] to [right].
  void _addStoriesVertically({
    List<Story> stories,
    double y,
    double left,
    double right,
  }) {
    double dy = y;
    stories.forEach((Story story) {
      config.storyCluster.add(
        story: story,
        withPanel: new Panel(
          origin: new FractionalOffset(left, dy),
          widthFactor: right - left,
          heightFactor: _kAddedStorySpan,
        ),
      );
      dy += _kAddedStorySpan;
      story.storyBarKey.currentState?.maximize(jumpToFinish: true);
    });
  }

  int get _currentRows => _getRows(left: 0.0, right: 1.0);

  int get _currentColumns => _getColumns(top: 0.0, bottom: 1.0);

  int _getRows({double left, double right}) {
    Set<double> tops = new Set<double>();
    config.storyCluster.panels
        .where((Panel panel) =>
            (left <= panel.left && right > panel.left) ||
            (panel.left < left && panel.right > left))
        .forEach((Panel panel) {
      tops.add(panel.top);
    });
    return tops.length;
  }

  int _getColumns({double top, double bottom}) {
    Set<double> lefts = new Set<double>();
    config.storyCluster.panels
        .where((Panel panel) =>
            (top <= panel.top && bottom > panel.top) ||
            (top < panel.top && panel.bottom > top))
        .forEach((Panel panel) {
      lefts.add(panel.left);
    });
    return lefts.length;
  }

  int _getHorizontalSplitCount(Panel panel) =>
      maxRows(config.fullSize) - _getRows(left: panel.left, right: panel.right);

  int _getVerticalSplitCount(Panel panel) =>
      maxColumns(config.fullSize) -
      _getColumns(top: panel.top, bottom: panel.bottom);

  Rect _bounds(Panel panel, Size size) => new Rect.fromLTRB(
        panel.left * size.width,
        panel.top * size.height,
        panel.right * size.width,
        panel.bottom * size.height,
      );

  Rect _transform(Panel panel, Point origin, Size size) =>
      Rect.lerp(origin & Size.zero, _bounds(panel, size), config.scale);

  static List<Story> _getVerticallySortedStories(StoryCluster storyCluster) {
    List<Story> sortedStories = new List.from(storyCluster.stories);
    sortedStories.sort(
      (Story a, Story b) => a.panel.top < b.panel.top
          ? -1
          : a.panel.top > b.panel.top
              ? 1
              : a.panel.left < b.panel.left
                  ? -1
                  : a.panel.left > b.panel.left ? 1 : 0,
    );
    return sortedStories;
  }

  static List<Story> _getHorizontallySortedStories(StoryCluster storyCluster) {
    List<Story> sortedStories = new List.from(storyCluster.stories);
    sortedStories.sort(
      (Story a, Story b) => a.panel.left < b.panel.left
          ? -1
          : a.panel.left > b.panel.left
              ? 1
              : a.panel.top < b.panel.top
                  ? -1
                  : a.panel.top > b.panel.top ? 1 : 0,
    );
    return sortedStories;
  }
}
