// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'armadillo_drag_target.dart';
import 'candidate_info.dart';
import 'cluster_layout.dart';
import 'debug_model.dart';
import 'drag_direction.dart';
import 'line_segment.dart';
import 'panel.dart';
import 'panel_drag_target.dart';
import 'place_holder_story.dart';
import 'simulated_fractional.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_id.dart';
import 'story_cluster_stories_model.dart';
import 'story_model.dart';
import 'target_overlay.dart';
import 'target_influence_overlay.dart';

const double _kGapBetweenTopTargets = 48.0;
const double _kStoryBarTargetYOffset = 48.0;
const double _kTopEdgeTargetYOffset =
    _kStoryBarTargetYOffset + _kGapBetweenTopTargets + 16.0;
const double _kStoryTopEdgeTargetYOffset =
    _kTopEdgeTargetYOffset + _kGapBetweenTopTargets;
const double _kDiscardTargetTopEdgeYOffset = -48.0;
const double _kBringToFrontTargetBottomEdgeYOffset = 48.0;
const double _kStoryEdgeTargetInset = 48.0;
const double _kStoryEdgeTargetInsetMinDistance = 0.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;
const int _kMaxStoriesPerCluster = 100;
const double _kAddedStorySpan = 0.01;
final Color _kTopEdgeTargetColor = Colors.yellow[700];
final Color _kLeftEdgeTargetColor = Colors.yellow[500];
final Color _kBottomEdgeTargetColor = Colors.yellow[700];
final Color _kRightEdgeTargetColor = Colors.yellow[500];
final List<Color> _kStoryBarTargetColor = <Color>[
  Colors.grey[500],
  Colors.grey[700]
];
final Color _kDiscardTargetColor = Colors.red[700];
final Color _kBringToFrontTargetColor = Colors.green[700];
final Color _kTopStoryEdgeTargetColor = Colors.blue[100];
final Color _kLeftStoryEdgeTargetColor = Colors.blue[300];
final Color _kBottomStoryEdgeTargetColor = Colors.blue[500];
final Color _kRightStoryEdgeTargetColor = Colors.blue[700];
const Color _kTargetBackgroundColor = const Color.fromARGB(128, 153, 234, 216);

const String _kStoryBarTargetName = 'Story Bar target';

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
  _PanelDragTargetsState createState() => new _PanelDragTargetsState();
}

class _PanelDragTargetsState extends TickingState<PanelDragTargets> {
  final Set<PanelDragTarget> _targets = new Set<PanelDragTarget>();

  final Map<StoryClusterId, CandidateInfo> _trackedCandidates =
      <StoryClusterId, CandidateInfo>{};
  final RK4SpringSimulation _scaleSimulation = new RK4SpringSimulation(
    initValue: 1.0,
    desc: _kScaleSimulationDesc,
  );

  /// When candidates are dragged over this drag target we add
  /// [PlaceHolderStory]s to the [StoryCluster] this target is representing.
  /// To ensure we can return to the original layout of the stories if the
  /// candidates leave without being dropped we store off the original story
  /// list, the original focus story ID, and the original display mode.
  ClusterLayout _originalClusterLayout;

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
    _originalClusterLayout = new ClusterLayout.from(config.storyCluster);
    _populateTargets();
  }

  @override
  void didUpdateConfig(PanelDragTargets oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.storyCluster.id != config.storyCluster.id) {
      _originalClusterLayout = new ClusterLayout.from(config.storyCluster);
    }
    if (oldConfig.focusProgress != config.focusProgress ||
        oldConfig.currentSize != config.currentSize) {
      _populateTargets();
    }
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDecendant<StoryClusterStoriesModel>(
        builder: (
          BuildContext context,
          Widget child,
          StoryClusterStoriesModel storyClusterStoriesModel,
        ) {
          _populateTargets();
          return _buildWidget(context);
        },
      );

  Widget _buildWidget(BuildContext context) =>
      new ArmadilloDragTarget<DraggedStoryClusterData>(
        onWillAccept: (DraggedStoryClusterData draggedStoryClusterData, _) =>
            config.storyCluster.id != draggedStoryClusterData.id,
        onAccept: (DraggedStoryClusterData draggedStoryClusterData, _,
                Velocity velocity) =>
            _onAccept(
              draggedStoryClusterData,
              velocity,
            ),
        builder: (
          BuildContext context,
          Map<DraggedStoryClusterData, Point> candidates,
          Map<dynamic, Point> rejectedData,
        ) =>
            _build(candidates),
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _scaleSimulation.elapseTime(elapsedSeconds);
    return !_scaleSimulation.isDone;
  }

  void _onAccept(DraggedStoryClusterData data, Velocity velocity) {
    StoryCluster storyCluster = StoryModel.of(context).getStoryCluster(data.id);

    // When focused, if the cluster has been flung, don't call the target
    // onDrop, instead just adjust the appropriate story bars.  Since a dragged
    // story cluster is already not a part of this cluster, not calling onDrop
    // ensures it will not be added to this cluster.
    if (!_inTimeline &&
        velocity.pixelsPerSecond.dy.abs() >
            _kVerticalFlingToDiscardSpeedThreshold) {
      storyCluster.removePreviews();
      storyCluster.minimizeStoryBars();
      return;
    }

    _transposeToChildCoordinates(storyCluster.stories);

    config.onAccept?.call();

    // If a target hasn't been chosen yet, default to dropping on the story bar
    // target as that's always there.
    if (_trackedCandidates[storyCluster.id]?.closestTarget?.onDrop != null) {
      _trackedCandidates[storyCluster.id]
          .closestTarget
          .onDrop(context, storyCluster);
    } else {
      if (!_inTimeline && data.onNoTarget != null) {
        data.onNoTarget.call();
      } else {
        _onStoryBarDrop(context, storyCluster);
      }
    }
    _updateFocusedStoryId(storyCluster);
  }

  bool get _inTimeline => config.focusProgress == 0.0;

  /// [candidates] are the clusters that are currently
  /// being dragged over this drag target with their associated local
  /// position.
  Widget _build(Map<DraggedStoryClusterData, Point> candidates) {
    // Update the acceptance of a dragged StoryCluster.  If we have no
    // candidates we're not accepting it.  If we do have condidates and we're
    // focused we do accept it.  If we're in the timeline we need to wait for
    // the validity timer to go off before accepting it.
    if (candidates.isEmpty) {
      StoryClusterDragStateModel.of(context).removeAcceptance(
            config.storyCluster.id,
          );
    } else if (!_inTimeline) {
      StoryClusterDragStateModel.of(context).addAcceptance(
            config.storyCluster.id,
          );
    }

    if (_inTimeline) {
      if (candidates.isEmpty) {
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
          ? candidates
          : <DraggedStoryClusterData, Point>{},
    );
  }

  /// [candidates] are the clusters that are currently
  /// being dragged over this drag target for the prerequesite time period with
  /// their associated local position.
  Widget _buildWithConfirmedCandidates(
    Map<DraggedStoryClusterData, Point> candidates,
  ) {
    candidates.keys.forEach((DraggedStoryClusterData data) {
      if (_trackedCandidates[data.id] == null) {
        _trackedCandidates[data.id] = new CandidateInfo(
          initialLockPoint: candidates[data],
        );
      }
      // Update velocity trackers.
      _trackedCandidates[data.id].updateVelocity(candidates[data]);
    });

    bool hasCandidates = candidates.isNotEmpty;
    if (hasCandidates && !_hadCandidates) {
      _originalClusterLayout = new ClusterLayout.from(config.storyCluster);
      _populateTargets();

      // Invoke onFirstHover callbacks if they exist.
      candidates.keys.forEach(
        (DraggedStoryClusterData data) => data.onFirstHover?.call(),
      );
    }
    _hadCandidates = hasCandidates;

    _updateInlinePreviewScalingSimulation(hasCandidates && _inTimeline);

    Map<StoryCluster, Point> storyClusterCandidates = _getStoryClusterMap(
      candidates,
    );

    _updateStoryBars(hasCandidates);
    _updateClosestTargets(candidates);

    // Scale child to config.scale if we aren't in the timeline
    // and we have a candidate being dragged over us.
    _scale = hasCandidates && !_inTimeline ? config.scale : 1.0;

    List<PanelDragTarget> validTargets = _targets
        .where(
          (PanelDragTarget target) => !storyClusterCandidates.keys.every(
                (StoryCluster key) =>
                    !target.canAccept(key.realStories.length) ||
                    !target.isValidInDirection(
                      _trackedCandidates[key.id].dragDirection,
                    ),
              ),
        )
        .toList();

    // The direction the candidates are being dragged from the perspective of
    // the debug overlays.  If we have no candidates, assume we don't move.
    DragDirection influenceDragDirection = candidates.isEmpty
        ? DragDirection.none
        : _trackedCandidates[candidates.keys.first.id].dragDirection;

    return new ScopedModelDecendant<DebugModel>(
      builder: (BuildContext context, Widget child, DebugModel debugModel) =>
          new TargetInfluenceOverlay(
            enabled:
                debugModel.showTargetInfluenceOverlay && candidates.isNotEmpty,
            targets: validTargets,
            dragDirection: influenceDragDirection,
            closestTargetGetter: (Point point) => _getClosestTarget(
                  influenceDragDirection,
                  point,
                  storyClusterCandidates.keys.isNotEmpty
                      ? storyClusterCandidates.keys.first
                      : null,
                  false,
                ),
            child: new TargetOverlay(
              enabled: debugModel.showTargetOverlay,
              targets: validTargets,
              closestTargetLockPoints:
                  _trackedCandidates.values.map(CandidateInfo.toPoint).toList(),
              candidatePoints: candidates.values.toList(),
              child: child,
            ),
          ),
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
      config.storyCluster.maximizeStoryBars();
    } else {
      config.storyCluster.minimizeStoryBars();
    }
  }

  /// Moves the [stories] corrdinates from whatever space they're in to the
  /// coordinate space of our [PanelDragTargets.child].
  void _transposeToChildCoordinates(List<Story> stories) {
    stories.forEach((Story story) {
      // Get the Story's current global bounds...
      RenderBox storyBox =
          story.positionedKey.currentContext?.findRenderObject();

      // If the Story's positioned widget hasn't been built yet there's nothing
      // to transpose so do nothing.
      if (storyBox == null) {
        return;
      }

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
    Map<DraggedStoryClusterData, Point> candidates,
  ) {
    Map<StoryCluster, Point> storyClusterMap = <StoryCluster, Point>{};
    candidates.keys.forEach((DraggedStoryClusterData data) {
      Point storyClusterPoint = candidates[data];
      StoryCluster storyCluster =
          StoryModel.of(context).getStoryCluster(data.id);
      storyClusterMap[storyCluster] = storyClusterPoint;
    });
    return storyClusterMap;
  }

  /// If [activate] is true, start the inline preview scale simulation.  If
  /// false, reverse the simulation back to its beginning.
  void _updateInlinePreviewScalingSimulation(bool activate) {
    config.storyCluster.inlinePreviewScaleSimulationKey.currentState?.target =
        activate ? 1.0 : 0.0;
    config.storyCluster.inlinePreviewHintScaleSimulationKey.currentState
        ?.target = (activate || _candidateValidityTimer != null) ? 1.0 : 0.0;
  }

  void _updateClosestTargets(Map<DraggedStoryClusterData, Point> candidates) {
    // Remove any candidates that no longer exist.
    _trackedCandidates.keys.toList().forEach((StoryClusterId storyClusterId) {
      if (candidates.keys.every(
          (DraggedStoryClusterData draggedStoryClusterData) =>
              draggedStoryClusterData.id != storyClusterId)) {
        _trackedCandidates.remove(storyClusterId);

        config.storyCluster.removePreviews();
        _normalizeSizes();

        // If no stories have changed, and a candidate was removed we need
        // to revert back to our original layout.
        if (_originalClusterLayout.storyCount ==
            config.storyCluster.stories.length) {
          _originalClusterLayout.restore(config.storyCluster);
        }
      }
    });

    // For each candidate...
    candidates.keys.forEach((DraggedStoryClusterData data) {
      Point storyClusterPoint = candidates[data];

      CandidateInfo candidateInfo = _trackedCandidates[data.id];

      StoryCluster storyCluster = StoryModel.of(context).getStoryCluster(
            data.id,
          );
      PanelDragTarget closestTarget = _getClosestTarget(
        candidateInfo.dragDirection,
        storyClusterPoint,
        storyCluster,
        candidateInfo.closestTarget == null,
      );

      if (candidateInfo.canLock(closestTarget, storyClusterPoint)) {
        _lockClosestTarget(
          candidateInfo: candidateInfo,
          storyCluster: storyCluster,
          point: storyClusterPoint,
          closestTarget: closestTarget,
        );
      }
    });
  }

  void _lockClosestTarget({
    CandidateInfo candidateInfo,
    StoryCluster storyCluster,
    Point point,
    PanelDragTarget closestTarget,
  }) {
    candidateInfo.lock(point, closestTarget);
    _verticalEdgeHoverTimer?.cancel();
    _verticalEdgeHoverTimer = null;
    closestTarget.onHover?.call(context, storyCluster);
    _updateFocusedStoryId(storyCluster);
  }

  PanelDragTarget _getClosestTarget(
    DragDirection dragDirection,
    Point point,
    StoryCluster storyCluster,
    bool initialTarget,
  ) {
    double minScore = double.INFINITY;
    PanelDragTarget closestTarget;
    _targets
        .where((PanelDragTarget target) => storyCluster == null
            ? true
            : target.canAccept(storyCluster.realStories.length))
        .where((PanelDragTarget target) =>
            target.isValidInDirection(dragDirection))
        .where((PanelDragTarget target) => target.withinRange(point))
        .where((PanelDragTarget target) =>
            (!initialTarget || target.initiallyTargetable))
        .forEach((PanelDragTarget target) {
      double targetScore = target.distanceFrom(point);
      targetScore *=
          target.isInDirectionFromPoint(dragDirection, point) ? 1.0 : 2.0;
      if (targetScore < minScore) {
        minScore = targetScore;
        closestTarget = target;
      }
    });
    return closestTarget;
  }

  /// Creates the targets for the configuration of panels represented by
  /// the story cluster's stories.
  ///
  /// Typically this includes the following targets:
  ///   1) Discard story target.
  ///   2) Bring to front target.
  ///   3) Convert to tabs target.
  ///   4) Edge targets on top, bottom, left, and right of the cluster.
  ///   5) Edge targets on top, bottom, left, and right of each panel.
  void _populateTargets() {
    _targets.clear();
    _targets.addAll(_createTargets());
  }

  List<PanelDragTarget> _createTargets() {
    SizeModel sizeModel = SizeModel.of(context);
    List<LineSegment> targets = <LineSegment>[];
    targets.clear();
    double verticalMargin = (1.0 - config.scale) / 2.0 * sizeModel.size.height;
    double horizontalMargin = (1.0 - config.scale) / 2.0 * sizeModel.size.width;

    List<Panel> panels = _originalClusterLayout.panels;
    int availableRows =
        maxRows(sizeModel.size) - _getCurrentRows(panels: panels);
    if (availableRows > 0) {
      // Top edge target.
      targets.add(
        new LineSegment.horizontal(
          name: 'Top edge target',
          y: verticalMargin + _kTopEdgeTargetYOffset,
          left: horizontalMargin + _kStoryEdgeTargetInsetMinDistance,
          right: sizeModel.size.width -
              horizontalMargin -
              _kStoryEdgeTargetInsetMinDistance,
          color: _kTopEdgeTargetColor,
          maxStoriesCanAccept: availableRows,
          validityDistance: kMinPanelHeight,
          directionallyTargetable: true,
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
      targets.add(
        new LineSegment.horizontal(
          name: 'Bottom edge target',
          y: sizeModel.size.height - verticalMargin,
          left: horizontalMargin + _kStoryEdgeTargetInsetMinDistance,
          right: sizeModel.size.width -
              horizontalMargin -
              _kStoryEdgeTargetInsetMinDistance,
          color: _kBottomEdgeTargetColor,
          maxStoriesCanAccept: availableRows,
          validityDistance: kMinPanelHeight,
          directionallyTargetable: true,
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
    int availableColumns =
        maxColumns(sizeModel.size) - _getCurrentColumns(panels: panels);
    if (availableColumns > 0) {
      targets.add(
        new LineSegment.vertical(
          name: 'Left edge target',
          x: horizontalMargin,
          top: verticalMargin +
              _kTopEdgeTargetYOffset +
              _kStoryEdgeTargetInsetMinDistance,
          bottom: sizeModel.size.height -
              verticalMargin -
              _kStoryEdgeTargetInsetMinDistance,
          color: _kLeftEdgeTargetColor,
          maxStoriesCanAccept: availableColumns,
          validityDistance: kMinPanelWidth,
          directionallyTargetable: true,
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
      targets.add(
        new LineSegment.vertical(
          name: 'Right edge target',
          x: sizeModel.size.width - horizontalMargin,
          top: verticalMargin +
              _kTopEdgeTargetYOffset +
              _kStoryEdgeTargetInsetMinDistance,
          bottom: sizeModel.size.height -
              verticalMargin -
              _kStoryEdgeTargetInsetMinDistance,
          color: _kRightEdgeTargetColor,
          maxStoriesCanAccept: availableColumns,
          validityDistance: kMinPanelWidth,
          directionallyTargetable: true,
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

    if (!_inTimeline) {
      // Top discard target.
      targets.add(
        new LineSegment.horizontal(
          name: 'Top discard target',
          initiallyTargetable: false,
          y: verticalMargin + _kDiscardTargetTopEdgeYOffset,
          left: 0.0,
          right: sizeModel.size.width,
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
      targets.add(
        new LineSegment.horizontal(
          name: 'Bottom bring-to-front target',
          initiallyTargetable: false,
          y: sizeModel.size.height -
              verticalMargin +
              _kBringToFrontTargetBottomEdgeYOffset,
          left: 0.0,
          right: sizeModel.size.width,
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

    // Story Bar targets.
    int storyBarTargets = _originalClusterLayout.storyCount + 1;
    double storyBarTargetLeft = 0.0;
    final double storyBarTargetWidth =
        (sizeModel.size.width - 2.0 * horizontalMargin) / storyBarTargets;
    for (int i = 0; i < storyBarTargets; i++) {
      double lineWidth = storyBarTargetWidth +
          ((i == 0 || i == storyBarTargets - 1) ? horizontalMargin : 0.0);
      targets.add(
        new LineSegment.horizontal(
          name: '$_kStoryBarTargetName for index $i',
          y: verticalMargin + _kStoryBarTargetYOffset,
          left: storyBarTargetLeft,
          right: storyBarTargetLeft + lineWidth,
          color: _kStoryBarTargetColor[i % _kStoryBarTargetColor.length],
          validityDistance: verticalMargin + _kStoryBarTargetYOffset,
          maxStoriesCanAccept:
              _kMaxStoriesPerCluster - config.storyCluster.stories.length,
          onHover: (BuildContext context, StoryCluster storyCluster) =>
              _onStoryBarHover(context, storyCluster, i),
          onDrop: (BuildContext context, StoryCluster storyCluster) =>
              _onStoryBarDrop(context, storyCluster, i),
        ),
      );
      storyBarTargetLeft += lineWidth;
    }

    // Story edge targets.
    Point center = new Point(
      sizeModel.size.width / 2.0,
      sizeModel.size.height / 2.0,
    );
    _originalClusterLayout.visitStories((StoryId storyId, Panel storyPanel) {
      Rect bounds = _transform(storyPanel, center, sizeModel.size);

      // If we can split vertically add vertical targets on left and right.
      int verticalSplits =
          _getVerticalSplitCount(storyPanel, sizeModel.size, panels);
      if (verticalSplits > 0) {
        double left = bounds.left + _kStoryEdgeTargetInset;
        double right = bounds.right - _kStoryEdgeTargetInset;
        double top = bounds.top +
            _kStoryEdgeTargetInsetMinDistance +
            (storyPanel.top == 0.0
                ? _kStoryTopEdgeTargetYOffset
                : 2.0 * _kStoryEdgeTargetInset);
        double bottom = bounds.bottom -
            _kStoryEdgeTargetInsetMinDistance -
            _kStoryEdgeTargetInset;

        // Add left target.
        targets.add(
          new LineSegment.vertical(
            name: 'Add left target $storyId',
            x: left,
            top: top,
            bottom: bottom,
            color: _kLeftStoryEdgeTargetColor,
            maxStoriesCanAccept: verticalSplits,
            validityDistance: kMinPanelWidth,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToLeftOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToLeftOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
                ),
          ),
        );

        // Add right target.
        targets.add(
          new LineSegment.vertical(
            name: 'Add right target $storyId',
            x: right,
            top: top,
            bottom: bottom,
            color: _kRightStoryEdgeTargetColor,
            maxStoriesCanAccept: verticalSplits,
            validityDistance: kMinPanelWidth,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToRightOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterToRightOfPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
                ),
          ),
        );
      }

      // If we can split horizontally add horizontal targets on top and bottom.
      int horizontalSplits =
          _getHorizontalSplitCount(storyPanel, sizeModel.size, panels);
      if (horizontalSplits > 0) {
        double top = bounds.top +
            (storyPanel.top == 0.0
                ? _kStoryTopEdgeTargetYOffset
                : _kStoryEdgeTargetInset);
        double left = bounds.left +
            _kStoryEdgeTargetInsetMinDistance +
            _kStoryEdgeTargetInset;
        double right = bounds.right -
            _kStoryEdgeTargetInsetMinDistance -
            _kStoryEdgeTargetInset;
        double bottom = bounds.bottom - _kStoryEdgeTargetInset;

        // Add top target.
        targets.add(
          new LineSegment.horizontal(
            name: 'Add top target $storyId',
            y: top,
            left: left,
            right: right,
            color: _kTopStoryEdgeTargetColor,
            maxStoriesCanAccept: horizontalSplits,
            validityDistance: kMinPanelHeight,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterAbovePanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterAbovePanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
                ),
          ),
        );

        // Add bottom target.
        targets.add(
          new LineSegment.horizontal(
            name: 'Add bottom target $storyId',
            y: bottom,
            left: left,
            right: right,
            color: _kBottomStoryEdgeTargetColor,
            maxStoriesCanAccept: horizontalSplits,
            validityDistance: kMinPanelHeight,
            directionallyTargetable: true,
            onHover: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterBelowPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
                  preview: true,
                ),
            onDrop: (BuildContext context, StoryCluster storyCluster) =>
                _addClusterBelowPanel(
                  context: context,
                  storyCluster: storyCluster,
                  storyId: storyId,
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
      List<LineSegment> scaledTargets = targets
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
                  initiallyTargetable: lineSegment.initiallyTargetable,
                  directionallyTargetable: lineSegment.directionallyTargetable,
                  validityDistance: lerpDouble(
                    0.0,
                    lineSegment.validityDistance,
                    lineSegment.isHorizontal ? verticalScale : horizontalScale,
                  ),
                ),
          )
          .toList();
      return scaledTargets;
    }
    return targets;
  }

  void _onStoryBarHover(
    BuildContext context,
    StoryCluster storyCluster,
    int targetIndex,
  ) {
    _addClusterToRightOfPanels(
      context: context,
      storyCluster: storyCluster,
      preview: true,
      displayMode: DisplayMode.tabs,
    );

    // Update tab positions in target cluster.
    config.storyCluster.movePlaceholderStoriesToIndex(
      storyCluster.realStories,
      targetIndex,
    );

    // Update tab positions in dragged candidate cluster.
    storyCluster.mirrorStoryOrder(config.storyCluster.stories);
  }

  void _onStoryBarDrop(
    BuildContext context,
    StoryCluster storyCluster, [
    int targetIndex = -1,
  ]) {
    targetIndex =
        (targetIndex == -1) ? config.storyCluster.stories.length : targetIndex;
    config.storyCluster.removePreviews();
    storyCluster.removePreviews();
    _cleanup(context: context, preview: true);

    config.storyCluster.displayMode = DisplayMode.tabs;
    config.storyCluster.focusedStoryId = storyCluster.focusedStoryId;

    final List<Story> storiesToMove = storyCluster.realStories;

    StoryModel.of(context).combine(
          source: storyCluster,
          target: config.storyCluster,
        );

    config.storyCluster.maximizeStoryBars();

    config.storyCluster.moveStoriesToIndex(storiesToMove, targetIndex);
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
    if (!preview) {
      StoryModel.of(context).remove(storyCluster);
    }
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

    // 3. Original focused story.
    _originalClusterLayout.restoreFocus(config.storyCluster);
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
    //    in this story cluster.
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

    // 4. Update displaymode.
    draggingStoryCluster.displayMode = displayMode;

    // 5. Normalize sizes.
    draggingStoryCluster.normalizeSizes();
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
      story.maximizeStoryBar();
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
      story.maximizeStoryBar();
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
