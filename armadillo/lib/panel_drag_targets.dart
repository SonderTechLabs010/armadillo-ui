// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'line_segment.dart';
import 'panel.dart';
import 'place_holder_story.dart';
import 'simulated_fractional.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_id.dart';
import 'story_model.dart';
import 'target_line_overlay.dart';

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

const String _kStoryBarTargetName = 'Story Bar target';
const Duration _kMinLockDuration = const Duration(milliseconds: 750);

/// Set to true to draw target lines.
const bool _kDrawTargetLines = false;

/// Once a drag target is chosen, this is the distance a draggable must travel
/// before new drag targets are considered.
const double _kStickyDistance = 32.0;

const RK4SpringDescription _kScaleSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

const RK4SpringDescription _kOpacitySimulationDesc =
    const RK4SpringDescription(tension: 900.0, friction: 50.0);

const Duration _kHoverDuration = const Duration(milliseconds: 400);
const Duration _kVerticalEdgeHoverDuration = const Duration(
  milliseconds: 1000,
);

const double _kVerticalFlingToDiscardSpeedThreshold = 2000.0;

/// Wraps its [child] in an [ArmadilloDragTarget] which tracks any
/// [ArmadilloLongPressDraggable]'s above it such that they can be dropped on
/// specific parts of [storyCluster]'s [StoryCluster.stories]'s [Panel]s.
///
/// When an [ArmadilloLongPressDraggable] is above, [child] will be scaled down
/// slightly depending on [focusProgress].
/// [onVerticalEdgeHover] will be called whenever a cluster hovers over the top
/// or bottom targets.
class PanelDragTargets extends StatefulWidget {
  final StoryCluster storyCluster;
  final Widget child;
  final double scale;
  final double focusProgress;
  final VoidCallback onAccept;
  final VoidCallback onVerticalEdgeHover;
  final Size currentSize;
  final Set<LineSegment> _targetLines = new Set<LineSegment>();

  PanelDragTargets({
    Key key,
    this.storyCluster,
    this.child,
    this.scale,
    this.focusProgress,
    this.onAccept,
    this.onVerticalEdgeHover,
    this.currentSize,
  })
      : super(key: key);

  @override
  PanelDragTargetsState createState() => new PanelDragTargetsState();
}

class PanelDragTargetsState extends TickingState<PanelDragTargets> {
  final Set<LineSegment> _targetLines = new Set<LineSegment>();

  /// When a 'closest target' is chosen, the [Point] of the candidate becomes
  /// the lock point for that target.  A new 'closest target' will not be chosen
  /// until the candidate travels the [_kStickyDistance] away from that lock
  /// point.
  final Map<StoryCluster, Point> _closestTargetLockPoints =
      <StoryCluster, Point>{};
  final Map<StoryCluster, LineSegment> _closestTargets =
      <StoryCluster, LineSegment>{};
  final Map<StoryCluster, DateTime> _closestTargetTimestamps =
      <StoryCluster, DateTime>{};
  final RK4SpringSimulation _scaleSimulation = new RK4SpringSimulation(
    initValue: 1.0,
    desc: _kScaleSimulationDesc,
  );

  /// When candidates are dragged over this drag target we add
  /// [PlaceHolderStory]s to the [StoryCluster] this target is representing.
  /// To ensure we can return to the original layout of the stories if the
  /// candidates leave without being dropped we store off the original story
  /// list, the original focus story ID, and the original display mode..
  StoryId _originalFocusedStoryId;
  List<Story> _originalStories;
  DisplayMode _originalDisplayMode;

  bool _hadCandidates = false;

  /// Candidates become valid after hovering over this drag target for
  /// [_kHoverDuration]
  bool _candidatesValid = false;

  /// The timer which triggers candidate validity when [_kHoverDuration]
  /// elapses.
  Timer _candidateValidityTimer;

  /// The timer which triggers [PanelDragTargets.onVerticalEdgeHover] when
  /// [_kVerticalEdgeHoverDuration] elapses.
  Timer _verticalEdgeHoverTimer;

  @override
  void initState() {
    super.initState();
    config.storyCluster.addStoryListListener(_populateTargetLines);
    _originalFocusedStoryId = config.storyCluster.focusedStoryId;
    _originalStories = config.storyCluster.stories;
    _originalDisplayMode = config.storyCluster.displayMode;
    _populateTargetLines();
  }

  @override
  void didUpdateConfig(PanelDragTargets oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.storyCluster.id != config.storyCluster.id) {
      oldConfig.storyCluster.removeStoryListListener(_populateTargetLines);
      config.storyCluster.addStoryListListener(_populateTargetLines);
      _originalFocusedStoryId = config.storyCluster.focusedStoryId;
      _originalStories = config.storyCluster.stories;
      _originalDisplayMode = config.storyCluster.displayMode;
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
        onWillAccept: (StoryClusterId storyClusterId, _) =>
            config.storyCluster.id != storyClusterId,
        onAccept: (StoryClusterId storyClusterId, _, Velocity velocity) =>
            _onAccept(
              StoryModel.of(context).getStoryCluster(storyClusterId),
              velocity,
            ),
        builder: (
          BuildContext context,
          Map<StoryClusterId, Point> storyClusterIdCandidates,
          Map<dynamic, Point> rejectedData,
        ) =>
            _build(storyClusterIdCandidates),
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _scaleSimulation.elapseTime(elapsedSeconds);
    return !_scaleSimulation.isDone;
  }

  void _onAccept(StoryCluster storyCluster, Velocity velocity) {
    // When focused, if the cluster has been flung, don't call the target
    // onDrop, instead just adjust the appropriate story bars.  Since a dragged
    // story cluster is already not a part of this cluster, not calling onDrop
    // ensures it will not be added to this cluster.
    if (!_inTimeline &&
        velocity.pixelsPerSecond.dy.abs() >
            _kVerticalFlingToDiscardSpeedThreshold) {
      storyCluster.stories.forEach((Story story) {
        story.storyBarKey.currentState?.minimize();
      });
      return;
    }

    _transposeToChildCoordinates(storyCluster.stories);

    config.onAccept?.call();

    // If a target hasn't been chosen yet, default to dropping on the story bar
    // target as that's always there.
    if (_closestTargets[storyCluster]?.onDrop != null) {
      _closestTargets[storyCluster].onDrop.call(context, storyCluster);
    } else {
      _onStoryBarDrop(context, storyCluster);
    }
    _updateFocusedStoryId(storyCluster);
  }

  bool get _inTimeline => config.focusProgress == 0.0;

  /// [storyClusterIdCandidates] are the clusters that are currently
  /// being dragged over this drag target with their associated local
  /// position.
  Widget _build(Map<StoryClusterId, Point> storyClusterIdCandidates) {
    // Update the acceptance of a dragged StoryCluster.  If we have no
    // candidates we're not accepting it.  If we do have condidates and we're
    // focused we do accept it.  If we're in the timeline we need to wait for
    // the validity timer to go off before accepting it.
    if (storyClusterIdCandidates.isEmpty) {
      StoryClusterDragStateModel
          .of(context)
          .removeAcceptance(config.storyCluster.id);
    } else if (!_inTimeline) {
      StoryClusterDragStateModel
          .of(context)
          .addAcceptance(config.storyCluster.id);
    }

    if (_inTimeline) {
      if (storyClusterIdCandidates.isEmpty) {
        _candidateValidityTimer?.cancel();
        _candidateValidityTimer = null;
        _candidatesValid = false;
      } else {
        if (!_candidatesValid && _candidateValidityTimer == null) {
          _candidateValidityTimer = new Timer(
            _kHoverDuration,
            () {
              if (mounted) {
                setState(
                  () {
                    _candidatesValid = true;
                    _candidateValidityTimer = null;
                    StoryClusterDragStateModel
                        .of(context)
                        .addAcceptance(config.storyCluster.id);
                  },
                );
              }
            },
          );
        }
      }
    }

    return _buildWithConfirmedCandidates(
      !_inTimeline || _candidatesValid
          ? storyClusterIdCandidates
          : <StoryClusterId, Point>{},
    );
  }

  /// [storyClusterIdCandidates] are the clusters that are currently
  /// being dragged over this drag target for the prerequesite time period with
  /// their associated local position.
  Widget _buildWithConfirmedCandidates(
    Map<StoryClusterId, Point> storyClusterIdCandidates,
  ) {
    bool hasCandidates = storyClusterIdCandidates.isNotEmpty;
    if (hasCandidates && !_hadCandidates) {
      _originalFocusedStoryId = config.storyCluster.focusedStoryId;
      _originalStories = config.storyCluster.stories;
      _originalDisplayMode = config.storyCluster.displayMode;
      _populateTargetLines();
    }
    _hadCandidates = hasCandidates;

    _updateInlinePreviewScalingSimulation(hasCandidates && _inTimeline);

    Map<StoryCluster, Point> storyClusterCandidates = _getStoryClusterMap(
      storyClusterIdCandidates,
    );

    _updateStoryBars(hasCandidates);
    _updateClosestTargets(storyClusterCandidates);

    // Scale child to config.scale if we aren't in the timeline
    // and we have a candidate being dragged over us.
    _scale = hasCandidates && !_inTimeline ? config.scale : 1.0;

    return new TargetLineOverlay(
      drawTargetLines: _kDrawTargetLines,
      targetLines: _targetLines,
      closestTargetLockPoints: _closestTargetLockPoints,
      storyClusterCandidates: storyClusterCandidates,
      child: new Transform(
        transform: new Matrix4.identity().scaled(_scale, _scale),
        alignment: FractionalOffset.center,
        child: config.child,
      ),
    );
  }

  set _scale(double scale) {
    if (_scaleSimulation.target != scale) {
      _scaleSimulation.target = scale;
      startTicking();
    }
  }

  double get _scale => _scaleSimulation.value;

  void _updateStoryBars(bool hasCandidates) {
    if (!StoryClusterDragStateModel.of(context).isDragging) {
      return;
    }

    if (hasCandidates) {
      config.storyCluster.stories.forEach((Story story) {
        story.storyBarKey.currentState?.maximize();
      });
    } else {
      config.storyCluster.stories.forEach((Story story) {
        story.storyBarKey.currentState?.minimize();
      });
    }
  }

  /// Moves the [stories] corrdinates from whatever space they're in to the
  /// coordinate space of our [PanelDragTargets.child].
  void _transposeToChildCoordinates(List<Story> stories) {
    stories.forEach((Story story) {
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
          config.storyCluster.panelsKey.currentContext.findRenderObject();
      Point storyInPanelsTopLeft = panelsBox.globalToLocal(storyTopLeft);
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
    });
  }

  Map<StoryCluster, Point> _getStoryClusterMap(
    Map<StoryClusterId, Point> storyClusterIdMap,
  ) {
    Map<StoryCluster, Point> storyClusterMap = <StoryCluster, Point>{};
    storyClusterIdMap.keys.forEach(
      (StoryClusterId storyClusterId) {
        Point storyClusterPoint = storyClusterIdMap[storyClusterId];
        StoryCluster storyCluster =
            StoryModel.of(context).getStoryCluster(storyClusterId);
        storyClusterMap[storyCluster] = storyClusterPoint;
      },
    );
    return storyClusterMap;
  }

  /// If [activate] is true, start the inline preview scale simulation.  If
  /// false, reverse the simulation back to its beginning.
  void _updateInlinePreviewScalingSimulation(bool activate) {
    scheduleMicrotask(() {
      config.storyCluster.inlinePreviewScaleSimulationKey.currentState?.target =
          activate ? 1.0 : 0.0;
      config.storyCluster.inlinePreviewHintScaleSimulationKey.currentState
          ?.target = (activate || _candidateValidityTimer != null) ? 1.0 : 0.0;
    });
  }

  void _updateClosestTargets(Map<StoryCluster, Point> storyClusterCandidates) {
    // Remove any candidates that no longer exist.
    _closestTargetLockPoints.keys.toList().forEach((StoryCluster storyCluster) {
      if (!storyClusterCandidates.keys.contains(storyCluster)) {
        _closestTargetLockPoints.remove(storyCluster);
        _closestTargets.remove(storyCluster);

        config.storyCluster.removePreviews();
        _normalizeSizes();

        // If no stories have changed, and a candidate was removed we need
        // to revert back to our original layout.
        if (_originalStories.length == config.storyCluster.stories.length) {
          _originalStories.forEach((Story story) {
            config.storyCluster.replaceStoryPanel(
              storyId: story.id,
              withPanel: story.panel,
            );
          });
          config.storyCluster.displayMode = _originalDisplayMode;
          config.storyCluster.focusedStoryId = _originalFocusedStoryId;
        }

        _updateDragFeedback(storyCluster);
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

      // ... lock to line closest to the candidate if the candidate:
      // 1) is new, or
      // 2) is old, and
      //    a) the closest line to the candidate has changed,
      //    b) we've moved past the sticky distance from the candidate's lock
      //       point, and
      //    c) the candidate's closest line hasn't changed recently.
      if (_closestTargets[storyCluster] == null ||
          (_closestTargets[storyCluster].name != closestLine.name &&
              ((lockPoint - storyClusterPoint).distance > _kStickyDistance) &&
              (new DateTime.now().subtract(_kMinLockDuration).isAfter(
                    _closestTargetTimestamps[storyCluster],
                  )))) {
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
    _closestTargetTimestamps[storyCluster] = new DateTime.now();
    _closestTargetLockPoints[storyCluster] = point;
    _closestTargets[storyCluster] = closestLine;
    _verticalEdgeHoverTimer?.cancel();
    _verticalEdgeHoverTimer = null;
    closestLine.onHover?.call(context, storyCluster);
    _updateFocusedStoryId(storyCluster);
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
        .where((LineSegment line) =>
            line.distanceFrom(point) < line.validityDistance)
        .forEach((LineSegment line) {
      double targetLineDistance = line.distanceFrom(point);
      if (targetLineDistance < minDistance &&
          (!initialTarget || line.initiallyTargetable)) {
        minDistance = targetLineDistance;
        closestLine = line;
      }
    });
    if (closestLine == null) {
      closestLine = _targetLines
          .where((LineSegment line) => line.name == _kStoryBarTargetName)
          .single;
    }
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
    SizeModel sizeModel = SizeModel.of(context);

    _targetLines.clear();
    double verticalMargin = (1.0 - config.scale) / 2.0 * sizeModel.size.height;
    double horizontalMargin = (1.0 - config.scale) / 2.0 * sizeModel.size.width;

    List<Panel> panels =
        _originalStories.map((Story story) => story.panel).toList();
    int availableRows = maxRows(sizeModel.size) -
        _getCurrentRows(
          panels: panels,
        );
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
    int availableColumns = maxColumns(sizeModel.size) -
        _getCurrentColumns(
          panels: panels,
        );
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
        name: _kStoryBarTargetName,
        y: verticalMargin + _kStoryBarTargetYOffset,
        left: horizontalMargin + _kStoryEdgeTargetInset,
        right: sizeModel.size.width - horizontalMargin - _kStoryEdgeTargetInset,
        color: _kStoryBarTargetColor,
        validityDistance: verticalMargin + _kStoryBarTargetYOffset,
        maxStoriesCanAccept:
            _kMaxStoriesPerCluster - config.storyCluster.stories.length,
        onHover: _onStoryBarHover,
        onDrop: _onStoryBarDrop,
      ),
    );

    if (!_inTimeline) {
      // Top discard target.
      _targetLines.add(
        new LineSegment.horizontal(
          name: 'Top discard target',
          initiallyTargetable: false,
          y: verticalMargin + _kDiscardTargetTopEdgeYOffset,
          left: horizontalMargin * 3.0,
          right: sizeModel.size.width - 3.0 * horizontalMargin,
          color: _kDiscardTargetColor,
          validityDistance: verticalMargin + _kDiscardTargetTopEdgeYOffset,
          maxStoriesCanAccept: _kMaxStoriesPerCluster,
          onHover: (BuildContext context, StoryCluster storyCluster) {
            config.storyCluster.removePreviews();
            _cleanup(context: context, preview: true);
            _updateDragFeedback(storyCluster);
            _verticalEdgeHoverTimer = new Timer(
              _kVerticalEdgeHoverDuration,
              () => config.onVerticalEdgeHover?.call(),
            );
          },
          onDrop: (BuildContext context, StoryCluster storyCluster) {
            _verticalEdgeHoverTimer?.cancel();
            _verticalEdgeHoverTimer = null;
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
          validityDistance:
              verticalMargin - _kBringToFrontTargetBottomEdgeYOffset,
          maxStoriesCanAccept: _kMaxStoriesPerCluster,
          onHover: (BuildContext context, StoryCluster storyCluster) {
            config.storyCluster.removePreviews();
            _cleanup(context: context, preview: true);
            _updateDragFeedback(storyCluster);
            _verticalEdgeHoverTimer = new Timer(
              _kVerticalEdgeHoverDuration,
              () => config.onVerticalEdgeHover?.call(),
            );
          },
          onDrop: (BuildContext context, StoryCluster storyCluster) {
            _verticalEdgeHoverTimer?.cancel();
            _verticalEdgeHoverTimer = null;
          },
        ),
      );
    }

    // Story edge targets.
    Point center = new Point(
      sizeModel.size.width / 2.0,
      sizeModel.size.height / 2.0,
    );
    _originalStories.forEach((Story story) {
      Rect bounds = _transform(story.panel, center, sizeModel.size);

      // If we can split vertically add vertical targets on left and right.
      int verticalSplits = _getVerticalSplitCount(
        story.panel,
        sizeModel.size,
        panels,
      );
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
                  validityDistance: lerpDouble(
                    0.0,
                    lineSegment.validityDistance,
                    verticalScale,
                  ),
                ),
          )
          .toList();
      _targetLines.clear();
      _targetLines.addAll(scaledLines);
    }
  }

  void _onStoryBarHover(BuildContext context, StoryCluster storyCluster) {
    _addClusterToRightOfPanels(
      context: context,
      storyCluster: storyCluster,
      preview: true,
      displayMode: DisplayMode.tabs,
    );
  }

  void _onStoryBarDrop(BuildContext context, StoryCluster storyCluster) {
    config.storyCluster.removePreviews();
    storyCluster.removePreviews();
    _cleanup(context: context, preview: true);

    config.storyCluster.displayMode = DisplayMode.tabs;
    config.storyCluster.focusedStoryId = storyCluster.focusedStoryId;

    StoryModel.of(context).combine(
          source: storyCluster,
          target: config.storyCluster,
        );

    storyCluster.realStories.forEach((Story story) {
      story.storyBarKey.currentState?.maximize();
    });
  }

  /// Adds the stories of [storyCluster] to the left, spanning the full height.
  void _addClusterToLeftOfPanels({
    BuildContext context,
    StoryCluster storyCluster,
    bool preview: false,
  }) {
    config.storyCluster.displayMode = DisplayMode.panels;

    // 0) Remove any existing preview stories.
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster);
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
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster, displayMode);
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
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster);
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
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster);
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
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster);
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
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster);
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
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster);
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
    Map<StoryId, PlaceHolderStory> placeholders =
        config.storyCluster.removePreviews();

    List<Story> storiesToAdd = preview
        ? new List<Story>.generate(
            storyCluster.realStories.length,
            (int index) =>
                placeholders[storyCluster.realStories[index].id] ??
                new PlaceHolderStory(
                  associatedStoryId: storyCluster.realStories[index].id,
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
      _updateDragFeedback(storyCluster);
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

  void _updateFocusedStoryId(StoryCluster storyCluster) {
    // After onHover or onDrop call always focus on, in order of priority:

    // 1. story with same ID as storyCluster.focusedStoryId if exists. OR
    if (config.storyCluster.realStories
        .where((Story story) => story.id == storyCluster.focusedStoryId)
        .isNotEmpty) {
      config.storyCluster.focusedStoryId = storyCluster.focusedStoryId;
      return;
    }

    // 2. placeholder with same ID as storyCluster.focusedStoryId if exists. OR
    List<PlaceHolderStory> previews = config.storyCluster.previewStories
        .where((PlaceHolderStory story) =>
            story.associatedStoryId == storyCluster.focusedStoryId)
        .toList();
    if (previews.isNotEmpty) {
      config.storyCluster.focusedStoryId = previews[0].id;
      return;
    }

    // 3. _originalFocusedStoryId.
    config.storyCluster.focusedStoryId = _originalFocusedStoryId;
  }

  void _updateDragFeedback(
    StoryCluster draggingStoryCluster, [
    DisplayMode displayMode = DisplayMode.panels,
  ]) {
    // 1. Remove existing PlaceHolders (and save them off).
    Map<StoryId, PlaceHolderStory> previews =
        draggingStoryCluster.removePreviews();

    // 2. Create and Add PlaceHolders for dragging story cluster for each story
    //    in this story cluster.
    if (config.storyCluster.previewStories.isNotEmpty) {
      config.storyCluster.realStories.forEach((Story story) {
        draggingStoryCluster.add(
          story: previews[story.id] ??
              new PlaceHolderStory(
                associatedStoryId: story.id,
                transparent: true,
              ),
          withPanel: story.panel,
          atIndex: 0,
        );
      });
    }

    // 3. Resize all panels in the dragging story cluster with the placeholders
    config.storyCluster.previewStories.forEach((Story story) {
      PlaceHolderStory placeHolderStory = story;
      draggingStoryCluster.replace(
          panel: draggingStoryCluster.stories
              .where((Story story) =>
                  story.id == placeHolderStory.associatedStoryId)
              .single
              .panel,
          withPanel: placeHolderStory.panel);
    });

    //    in this story cluster.
    // 4. Update displaymode.
    draggingStoryCluster.displayMode = displayMode;
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

  int _getCurrentColumns({List<Panel> panels}) =>
      _getColumns(top: 0.0, bottom: 1.0, panels: panels);

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

  int _getColumns({double top, double bottom, List<Panel> panels}) {
    Set<double> lefts = new Set<double>();
    panels
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

  int _getVerticalSplitCount(Panel panel, Size fullSize, List<Panel> panels) =>
      maxColumns(fullSize) -
      _getColumns(
        top: panel.top,
        bottom: panel.bottom,
        panels: panels,
      );

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
