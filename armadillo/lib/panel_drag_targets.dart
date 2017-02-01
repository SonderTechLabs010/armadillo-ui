// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'panel.dart';
import 'place_holder_story.dart';
import 'simulated_fractional.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_id.dart';
import 'story_model.dart';

const double _kLineWidth = 4.0;
const double _kTopEdgeTargetYOffset = 64.0;
const double _kDiscardTargetTopEdgeYOffset = -48.0;
const double _kBringToFrontTargetBottomEdgeYOffset = 48.0;
const double _kStoryBarTargetYOffset = 16.0;
const double _kStoryTopEdgeTargetYOffset = 112.0;
const double _kStoryEdgeTargetInset = 48.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;
const int _kMaxStoriesPerCluster = 100;
const double _kAddedStorySpan = 0.01;
const Color _kEdgeTargetColor = const Color(0xFFFFFF00);
const Color _kStoryBarTargetColor = const Color(0xFF00FFFF);
const Color _kDiscardTargetColor = const Color(0xFFFF0000);
const Color _kBringToFrontTargetColor = const Color(0xFF00FF00);
const Color _kStoryEdgeTargetColor = const Color(0xFF0000FF);
const Color _kTargetBackgroundColor = const Color.fromARGB(128, 153, 234, 216);

/// Set to true to draw target lines.
const bool _kDrawTargetLines = false;

/// Once a drag target is chosen, this is the distance a draggable must travel
/// before new drag targets are considered.
const double _kStickyDistance = 32.0;

const RK4SpringDescription _kScaleSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

const RK4SpringDescription _kOpacitySimulationDesc =
    const RK4SpringDescription(tension: 900.0, friction: 50.0);

typedef void _OnPanelEvent(BuildContext context, StoryCluster storyCluster);

/// Details about a target used by [PanelDragTargets].
///
/// [LineSegment] specifies a line from [a] to [b].
/// When turned into a widget the [LineSegment] will have the color [color].
/// When the [LineSegment] is being targeted by a draggable [onHover] will be
/// called.
/// When the [LineSegment] is dropped upon with a draggable [onDrop] will be
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
  final String name;
  final bool initiallyTargetable;

  LineSegment(
    Point a,
    Point b, {
    this.color: const Color(0xFFFFFFFF),
    this.onHover,
    this.onDrop,
    this.maxStoriesCanAccept: 1,
    this.name,
    this.initiallyTargetable: true,
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
    String name,
    bool initiallyTargetable: true,
  }) =>
      new LineSegment(
        new Point(x, top),
        new Point(x, bottom),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
        name: name,
        initiallyTargetable: initiallyTargetable,
      );

  factory LineSegment.horizontal({
    double y,
    double left,
    double right,
    Color color,
    _OnPanelEvent onHover,
    _OnPanelEvent onDrop,
    int maxStoriesCanAccept,
    String name,
    bool initiallyTargetable: true,
  }) =>
      new LineSegment(
        new Point(left, y),
        new Point(right, y),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
        name: name,
        initiallyTargetable: initiallyTargetable,
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
/// specific parts of [storyCluster]'s [StoryCluster.stories]'s [Panel]s.
///
/// When an [ArmadilloLongPressDraggable] is above, [child] will be scaled down
/// slightly depending on [focusProgress].
class PanelDragTargets extends StatefulWidget {
  final StoryCluster storyCluster;
  final Widget child;
  final double scale;
  final double focusProgress;
  final VoidCallback onGainFocus;
  final Size currentSize;
  final Set<LineSegment> _targetLines = new Set<LineSegment>();

  PanelDragTargets({
    Key key,
    this.storyCluster,
    this.child,
    this.scale,
    this.focusProgress,
    this.onGainFocus,
    this.currentSize,
  })
      : super(key: key);

  @override
  PanelDragTargetsState createState() => new PanelDragTargetsState();
}

class PanelDragTargetsState extends TickingState<PanelDragTargets> {
  final GlobalKey _childContainerKey = new GlobalKey();
  final Set<LineSegment> _targetLines = new Set<LineSegment>();

  /// When a 'closest target' is chosen, the [Point] of the candidate becomes
  /// the lock point for that target.  A new 'closest target' will not be chosen
  /// until the candidate travels the [_kStickyDistance] away from that lock
  /// point.
  final Map<StoryCluster, Point> _closestTargetLockPoints =
      <StoryCluster, Point>{};
  final Map<StoryCluster, LineSegment> _closestTargets =
      <StoryCluster, LineSegment>{};
  final RK4SpringSimulation _scaleSimulation = new RK4SpringSimulation(
    initValue: 1.0,
    desc: _kScaleSimulationDesc,
  );
  final RK4SpringSimulation _opacitySimulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kOpacitySimulationDesc,
  );

  /// When candidates are dragged over this drag target we add
  /// [PlaceHolderStory]s to the [StoryCluster] this target is representing.
  /// To ensure we can return to the original layout of the stories if the
  /// candidates leave without being dropped we store off the original story
  /// list.
  final List<Story> _originalStoryPlacement = <Story>[];

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
    if (oldConfig.focusProgress != config.focusProgress ||
        oldConfig.currentSize != config.currentSize) {
      _populateTargetLines();
    }
  }

  @override
  void dispose() {
    config.storyCluster.removeStoryListListener(_populateTargetLines);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new ArmadilloDragTarget<StoryClusterId>(
        onWillAccept: (_, __) => true,
        onAccept: (StoryClusterId storyClusterId, _) {
          StoryCluster storyCluster =
              StoryModel.of(context).getStoryCluster(storyClusterId);

          storyCluster.stories.forEach((Story story) {
            if (story.positionedKey.currentState is SimulatedFractionalState) {
              // Get the Story's current global bounds...
              RenderBox storyBox =
                  story.positionedKey.currentContext.findRenderObject();
              Point storyTopLeft = storyBox.localToGlobal(Point.origin);
              Point storyBottomRight = storyBox.localToGlobal(
                new Point(storyBox.size.width, storyBox.size.height),
              );

              // Convert the Story's global bounds into bounds local to the
              // StoryPanels...
              RenderBox panelsBox =
                  _childContainerKey.currentContext.findRenderObject();
              Point storyInPanelsTopLeft =
                  panelsBox.globalToLocal(storyTopLeft);
              Point storyInPanelsBottomRight =
                  panelsBox.globalToLocal(storyBottomRight);
              // Jump the Story's SimulatedFractional to its new location to
              // ensure a seamless animation into place.
              SimulatedFractionalState state = story.positionedKey.currentState;
              state.jump(
                new Rect.fromLTRB(
                  storyInPanelsTopLeft.x,
                  storyInPanelsTopLeft.y,
                  storyInPanelsBottomRight.x,
                  storyInPanelsBottomRight.y,
                ),
                panelsBox.size,
              );
            }
          });

          if (config.focusProgress == 0.0) {
            config.onGainFocus?.call();
          }

          _closestTargets[storyCluster]?.onDrop?.call(context, storyCluster);
        },
        builder: (
          BuildContext context,
          Map<StoryClusterId, Point> storyClusterIdCandidates,
          Map<dynamic, Point> rejectedData,
        ) {
          _updateInlinePreviewScalingSimulation(
            storyClusterIdCandidates.isNotEmpty,
          );
          Map<StoryCluster, Point> storyClusterCandidates =
              <StoryCluster, Point>{};
          storyClusterIdCandidates.keys
              .forEach((StoryClusterId storyClusterId) {
            Point storyClusterPoint = storyClusterIdCandidates[storyClusterId];
            StoryCluster storyCluster =
                StoryModel.of(context).getStoryCluster(storyClusterId);
            storyClusterCandidates[storyCluster] = storyClusterPoint;
          });

          _updateClosestTargets(storyClusterCandidates);

          // Scale child to config.scale if we aren't in the timeline
          // and we have a candidate being dragged over us.
          double newScale =
              storyClusterCandidates.isEmpty || config.focusProgress == 0.0
                  ? 1.0
                  : config.scale;
          if (_scaleSimulation.target != newScale) {
            _scaleSimulation.target = newScale;
            startTicking();
          }

          double newTargetOpacity =
              storyClusterIdCandidates.isEmpty ? 0.0 : 0.5;
          if (_opacitySimulation.target != newTargetOpacity) {
            _opacitySimulation.target = newTargetOpacity;
            startTicking();
          }

          // Scale the child.
          double childScale = _scaleSimulation.value;

          List<Widget> stackChildren = <Widget>[
            new Positioned(
              top: 0.0,
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: new Transform(
                transform:
                    new Matrix4.identity().scaled(childScale, childScale),
                alignment: FractionalOffset.center,
                child: new Stack(children: <Widget>[
                  new Container(
                    key: _childContainerKey,
                    decoration: new BoxDecoration(
                      backgroundColor: _kTargetBackgroundColor.withOpacity(
                        _opacitySimulation.value,
                      ),
                      boxShadow: kElevationToShadow[12],
                      borderRadius: new BorderRadius.all(
                        new Radius.circular(
                          lerpDouble(
                            _kUnfocusedCornerRadius,
                            _kFocusedCornerRadius,
                            config.focusProgress,
                          ),
                        ),
                      ),
                    ),
                  ),
                  config.child,
                ]),
              ),
            )
          ];

          // When we have a candidate and we're fully focused, show the target
          // lines.
          if (_kDrawTargetLines && storyClusterCandidates.isNotEmpty) {
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
            // Add candidate points
            stackChildren.addAll(
              storyClusterCandidates.values.map(
                (Point point) => new Positioned(
                      left: point.x - 5.0,
                      top: point.y - 5.0,
                      width: 10.0,
                      height: 10.0,
                      child: new Container(
                        decoration: new BoxDecoration(
                          backgroundColor: new Color(0xFFFFFF00),
                        ),
                      ),
                    ),
              ),
            );
            // Add candidate lockpoints
            stackChildren.addAll(
              _closestTargetLockPoints.values.map(
                (Point point) => new Positioned(
                      left: point.x - 5.0,
                      top: point.y - 5.0,
                      width: 10.0,
                      height: 10.0,
                      child: new Container(
                        decoration: new BoxDecoration(
                          backgroundColor: new Color(0xFFFF00FF),
                        ),
                      ),
                    ),
              ),
            );
          }
          return new Stack(children: stackChildren);
        },
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _scaleSimulation.elapseTime(elapsedSeconds);
    _opacitySimulation.elapseTime(elapsedSeconds);

    return !(_scaleSimulation.isDone && _opacitySimulation.isDone);
  }

  /// If [hasCandidates] is true and we're currently in the timeline, start
  /// the inline preview scale simulation.  If either is false, reverse the
  /// simulation back to its beginning.
  void _updateInlinePreviewScalingSimulation(bool hasCandidates) {
    scheduleMicrotask(() {
      config.storyCluster.inlinePreviewScaleSimulationKey.currentState?.target =
          (hasCandidates && config.focusProgress == 0.0) ? 1.0 : 0.0;
    });
  }

  void _updateClosestTargets(Map<StoryCluster, Point> storyClusterCandidates) {
    // Remove any candidates that no longer exist.
    _closestTargetLockPoints.keys.toList().forEach((StoryCluster storyCluster) {
      if (!storyClusterCandidates.keys.contains(storyCluster)) {
        _closestTargetLockPoints.remove(storyCluster);
        _closestTargets.remove(storyCluster);
        config.storyCluster.removePreviews();
        _cleanup(context: context, preview: true);
        config.storyCluster.displayMode = DisplayMode.panels;
        _updateDragFeedback(storyCluster.dragFeedbackKey);
      }
    });

    // For each candidate...
    storyClusterCandidates.keys.forEach((StoryCluster storyCluster) {
      Point storyClusterPoint = storyClusterCandidates[storyCluster];

      if (_closestTargetLockPoints[storyCluster] == null) {
        _closestTargetLockPoints[storyCluster] = storyClusterPoint;
      }

      Point lockPoint = _closestTargetLockPoints[storyCluster];

      LineSegment closestLine = _getClosestLine(
        storyClusterPoint,
        storyCluster,
        _closestTargets[storyCluster] == null,
      );

      // ... lock to its closest line if it's an existing candidate whose
      // closest line has changed and we've moved past the sticky distance for
      // its lock point.
      if (_closestTargets[storyCluster] == null ||
          (_closestTargets[storyCluster].name != closestLine.name &&
              ((lockPoint - storyClusterPoint).distance > _kStickyDistance))) {
        _lockClosestTarget(
          storyCluster: storyCluster,
          point: storyClusterPoint,
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

  LineSegment _getClosestLine(
    Point point,
    StoryCluster storyCluster,
    bool initialTarget,
  ) {
    double minDistance = double.INFINITY;
    LineSegment closestLine;
    _targetLines
        .where((LineSegment line) => line.canAccept(storyCluster))
        .forEach((LineSegment line) {
      double targetLineDistance = line.distanceFrom(point);
      if (targetLineDistance < minDistance &&
          (!initialTarget || line.initiallyTargetable)) {
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
    // Only update original story layout if there are no placeholders.
    if (config.storyCluster.stories
        .every((Story story) => !story.isPlaceHolder)) {
      _originalStoryPlacement.clear();
      config.storyCluster.stories.forEach(
        (Story story) => _originalStoryPlacement.add(story.copyWith()),
      );
    }

    SizeModel sizeModel = SizeModel.of(context);

    _targetLines.clear();
    double verticalMargin = (1.0 - config.scale) / 2.0 * sizeModel.size.height;
    double horizontalMargin = (1.0 - config.scale) / 2.0 * sizeModel.size.width;

    List<Panel> panels =
        _originalStoryPlacement.map((Story story) => story.panel).toList();
    int availableRows =
        maxRows(sizeModel.size) - _getCurrentRows(panels: panels);
    if (availableRows > 0) {
      // Top edge target.
      _targetLines.add(
        new LineSegment.horizontal(
          name: 'Top edge target',
          y: verticalMargin + _kTopEdgeTargetYOffset,
          left: horizontalMargin + _kStoryEdgeTargetInset,
          right:
              sizeModel.size.width - horizontalMargin - _kStoryEdgeTargetInset,
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
          name: 'Bottom edge target',
          y: sizeModel.size.height - verticalMargin,
          left: horizontalMargin + _kStoryEdgeTargetInset,
          right:
              sizeModel.size.width - horizontalMargin - _kStoryEdgeTargetInset,
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
    int availableColumns = maxColumns(sizeModel.size) - _currentColumns;
    if (availableColumns > 0) {
      _targetLines.add(
        new LineSegment.vertical(
          name: 'Left edge target',
          x: horizontalMargin,
          top: verticalMargin,
          bottom:
              sizeModel.size.height - verticalMargin - _kStoryEdgeTargetInset,
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
          name: 'Right edge target',
          x: sizeModel.size.width - horizontalMargin,
          top: verticalMargin,
          bottom:
              sizeModel.size.height - verticalMargin - _kStoryEdgeTargetInset,
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
        name: 'Story Bar target',
        y: verticalMargin + _kStoryBarTargetYOffset,
        left: horizontalMargin + _kStoryEdgeTargetInset,
        right: sizeModel.size.width - horizontalMargin - _kStoryEdgeTargetInset,
        color: _kStoryBarTargetColor,
        maxStoriesCanAccept:
            _kMaxStoriesPerCluster - config.storyCluster.stories.length,
        onHover: (BuildContext context, StoryCluster storyCluster) {
          _addClusterToRightOfPanels(
            context: context,
            storyCluster: storyCluster,
            preview: true,
            displayMode: DisplayMode.tabs,
          );
        },
        onDrop: (BuildContext context, StoryCluster storyCluster) {
          config.storyCluster.removePreviews();
          _cleanup(context: context, preview: true);

          config.storyCluster.displayMode = DisplayMode.tabs;

          StoryModel.of(context).combine(
                source: storyCluster,
                target: config.storyCluster,
              );

          storyCluster.stories.forEach((Story story) {
            story.storyBarKey.currentState?.maximize();
          });
        },
      ),
    );

    if (config.focusProgress != 0.0) {
      // Top discard target.
      _targetLines.add(
        new LineSegment.horizontal(
          name: 'Top discard target',
          initiallyTargetable: false,
          y: verticalMargin + _kDiscardTargetTopEdgeYOffset,
          left: horizontalMargin * 3.0,
          right: sizeModel.size.width - 3.0 * horizontalMargin,
          color: _kDiscardTargetColor,
          maxStoriesCanAccept: _kMaxStoriesPerCluster,
          onHover: (BuildContext context, StoryCluster storyCluster) {
            config.storyCluster.removePreviews();
            _cleanup(context: context, preview: true);
            _updateDragFeedback(storyCluster.dragFeedbackKey);
            config.storyCluster.displayMode = DisplayMode.panels;
          },
          onDrop: (BuildContext context, StoryCluster storyCluster) {
            config.storyCluster.removePreviews();
            _cleanup(context: context, preview: true);
            config.storyCluster.displayMode = DisplayMode.panels;

            // TODO(apwilson): Animate storyCluster away.
          },
        ),
      );

      // Bottom bring-to-front target.
      _targetLines.add(
        new LineSegment.horizontal(
          name: 'Bottom bring-to-front target',
          initiallyTargetable: false,
          y: sizeModel.size.height -
              verticalMargin +
              _kBringToFrontTargetBottomEdgeYOffset,
          left: horizontalMargin * 3.0,
          right: sizeModel.size.width - 3.0 * horizontalMargin,
          color: _kBringToFrontTargetColor,
          maxStoriesCanAccept: _kMaxStoriesPerCluster,
          onHover: (BuildContext context, StoryCluster storyCluster) {
            config.storyCluster.removePreviews();
            _cleanup(context: context, preview: true);
            _updateDragFeedback(storyCluster.dragFeedbackKey);
            config.storyCluster.displayMode = DisplayMode.panels;
          },
          onDrop: (BuildContext context, StoryCluster storyCluster) {
            config.storyCluster.removePreviews();
            _cleanup(context: context, preview: true);
            config.storyCluster.displayMode = DisplayMode.panels;
            // TODO(apwilson): Defocus this cluster away.
            // Bring storyCluster into focus.
          },
        ),
      );
    }

    // Story edge targets.
    Point center = new Point(
      sizeModel.size.width / 2.0,
      sizeModel.size.height / 2.0,
    );
    _originalStoryPlacement.forEach((Story story) {
      Rect bounds = _transform(story.panel, center, sizeModel.size);

      // If we can split vertically add vertical targets on left and right.
      int verticalSplits = _getVerticalSplitCount(story.panel, sizeModel.size);
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
            name: 'Add left target ${story.id}',
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
            name: 'Add right target ${story.id}',
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
      int horizontalSplits = _getHorizontalSplitCount(
        story.panel,
        sizeModel.size,
        panels,
      );
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
            name: 'Add top target ${story.id}',
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
            name: 'Add bottom target ${story.id}',
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

    // All of the above LineSegments have been created assuming the cluster
    // as at the size specified by the sizeModel.  Since that's not always the
    // case (particularly when we're doing an inline preview) we need to scale
    // down all the lines when our current size doesn't match our expected size.
    double horizontalScale = config.currentSize.width / sizeModel.size.width;
    double verticalScale = config.currentSize.height / sizeModel.size.height;
    if (horizontalScale != 1.0 || verticalScale != 1.0) {
      List<LineSegment> scaledLines = _targetLines
          .map(
            (LineSegment lineSegment) => new LineSegment(
                  new Point(
                    lerpDouble(0.0, lineSegment.a.x, horizontalScale),
                    lerpDouble(0.0, lineSegment.a.y, verticalScale),
                  ),
                  new Point(
                    lerpDouble(0.0, lineSegment.b.x, horizontalScale),
                    lerpDouble(0.0, lineSegment.b.y, verticalScale),
                  ),
                  name: lineSegment.name,
                  color: lineSegment.color,
                  onHover: lineSegment.onHover,
                  onDrop: lineSegment.onDrop,
                  maxStoriesCanAccept: lineSegment.maxStoriesCanAccept,
                ),
          )
          .toList();
      _targetLines.clear();
      _targetLines.addAll(scaledLines);
    }
  }

  /// Adds the stories of [storyCluster] to the left, spanning the full height.
  void _addClusterToLeftOfPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    config.storyCluster.displayMode = DisplayMode.panels;

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
    DisplayMode displayMode: DisplayMode.panels,
  }) {
    config.storyCluster.displayMode = displayMode;

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
      _updateDragFeedback(storyCluster.dragFeedbackKey, displayMode);
    }
  }

  /// Adds the stories of [storyCluster] to the top, spanning the full width.
  void _addClusterAbovePanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    config.storyCluster.displayMode = DisplayMode.panels;

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
    config.storyCluster.displayMode = DisplayMode.panels;

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

  /// Adds the stories of [storyCluster] to the left of [storyId]'s panel,
  /// spanning that panel's height.
  void _addClusterToLeftOfPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    config.storyCluster.displayMode = DisplayMode.panels;

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
      panels: <Panel>[panel],
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

  /// Adds the stories of [storyCluster] to the right of [storyId]'s panel',
  /// spanning that panel's height.
  void _addClusterToRightOfPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    config.storyCluster.displayMode = DisplayMode.panels;

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
      panels: <Panel>[panel],
      widthFactorDelta: -(_kAddedStorySpan * storiesToAdd.length),
    );

    // 3) Clean up.
    _cleanup(context: context, storyCluster: storyCluster, preview: preview);

    // 4) If previewing, update the drag feedback.
    if (preview) {
      _updateDragFeedback(storyCluster.dragFeedbackKey);
    }
  }

  /// Adds the stories of [storyCluster] to the top of [storyId]'s panel,
  /// spanning that panel's width.
  void _addClusterAbovePanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    config.storyCluster.displayMode = DisplayMode.panels;

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
      panels: <Panel>[panel],
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

  /// Adds the stories of [storyCluster] to the bottom of [storyId]'s panel,
  /// spanning that panel's width.
  void _addClusterBelowPanel({
    BuildContext context,
    StoryCluster storyCluster,
    StoryId storyId,
    bool preview: false,
  }) {
    config.storyCluster.displayMode = DisplayMode.panels;

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
      panels: <Panel>[panel],
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

    // 2) Remove dropped cluster from story model.
    // NOTE: We do this in a microtask because of the following:
    //   a) Messing with the [StoryModel] could cause a setState call.
    //   b) This function could be called while we're building (due to an
    //      onHover callback).
    //   c) Causing a setState while building is a big Flutter no-no.
    scheduleMicrotask(() {
      if (!preview) {
        StoryModel.of(context).remove(storyClusterId: storyCluster.id);
      }
    });
  }

  void _updateDragFeedback(
    GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey, [
    DisplayMode displayMode = DisplayMode.panels,
  ]) {
    Map<Object, Panel> panelMap = <Object, Panel>{};

    config.storyCluster.stories
        .where((Story story) => story.isPlaceHolder)
        .forEach((Story story) {
      PlaceHolderStory placeHolderStory = story;
      panelMap[placeHolderStory.associatedStoryId] = placeHolderStory.panel;
    });

    // NOTE: We do this in a microtask because of the following:
    //   a) Messing with the [StoryClusterDragFeedbackState] could cause a
    //      setState call.
    //   b) This function could be called while we're building (due to an
    //      onHover callback).
    //   c) Causing a setState while building is a big Flutter no-no.
    scheduleMicrotask(() {
      dragFeedbackKey.currentState?.storyPanels = panelMap;
      dragFeedbackKey.currentState?.displayMode = displayMode;
      dragFeedbackKey.currentState?.targetClusterStoryCount =
          config.storyCluster.stories.length;
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
      story.storyBarKey.currentState?.maximize();
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
      story.storyBarKey.currentState?.maximize();
    });
  }

  int _getCurrentRows({List<Panel> panels}) =>
      _getRows(left: 0.0, right: 1.0, panels: panels);

  int get _currentColumns => _getColumns(top: 0.0, bottom: 1.0);

  int _getRows({double left, double right, List<Panel> panels}) {
    Set<double> tops = new Set<double>();
    panels
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

  int _getHorizontalSplitCount(
    Panel panel,
    Size fullSize,
    List<Panel> panels,
  ) =>
      maxRows(fullSize) -
      _getRows(
        left: panel.left,
        right: panel.right,
        panels: panels,
      );

  int _getVerticalSplitCount(Panel panel, Size fullSize) =>
      maxColumns(fullSize) - _getColumns(top: panel.top, bottom: panel.bottom);

  Rect _bounds(Panel panel, Size size) => new Rect.fromLTRB(
        panel.left * size.width,
        panel.top * size.height,
        panel.right * size.width,
        panel.bottom * size.height,
      );

  Rect _transform(Panel panel, Point origin, Size size) =>
      Rect.lerp(origin & Size.zero, _bounds(panel, size), config.scale);

  static List<Story> _getVerticallySortedStories(StoryCluster storyCluster) {
    List<Story> sortedStories = new List<Story>.from(storyCluster.stories);
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
    List<Story> sortedStories = new List<Story>.from(storyCluster.stories);
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
