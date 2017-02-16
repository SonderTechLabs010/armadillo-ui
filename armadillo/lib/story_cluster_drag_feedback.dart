// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'armadillo_overlay.dart';
import 'simulated_sized_box.dart';
import 'simulated_transform.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_widget.dart';
import 'story_list_render_block.dart';
import 'story_panels.dart';

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedCornerRadius = 4.0;
const double _kFocusedCornerRadius = 8.0;

/// Displays a representation of a StoryCluster while being dragged.
class StoryClusterDragFeedback extends StatefulWidget {
  final StoryCluster storyCluster;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final Map<StoryId, Widget> storyWidgets;
  final Point localDragStartPoint;
  final Rect initialBounds;
  final double focusProgress;
  final double initDx;

  StoryClusterDragFeedback({
    Key key,
    this.overlayKey,
    this.storyCluster,
    this.storyWidgets,
    this.localDragStartPoint,
    this.initialBounds,
    this.focusProgress,
    this.initDx: 0.0,
  })
      : super(key: key);

  @override
  StoryClusterDragFeedbackState createState() =>
      new StoryClusterDragFeedbackState();
}

class StoryClusterDragFeedbackState extends State<StoryClusterDragFeedback> {
  final GlobalKey<SimulatedSizedBoxState> _childKey =
      new GlobalKey<SimulatedSizedBoxState>();
  StoryClusterDragStateModel _storyClusterDragStateModel;
  List<Story> _originalStories;
  DisplayMode _originalDisplayMode;

  @override
  void initState() {
    super.initState();
    _storyClusterDragStateModel = StoryClusterDragStateModel.of(context);
    _storyClusterDragStateModel.addListener(_updateStoryBars);

    // Store off original stories and display state and on change to
    // isAccepted, revert to initial story locations and
    // display state.
    _originalStories = config.storyCluster.stories;
    _originalDisplayMode = config.storyCluster.displayMode;
    config.storyCluster.addPanelListener(_onPanelsChanged);
  }

  @override
  void didUpdateConfig(StoryClusterDragFeedback oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.storyCluster.id != config.storyCluster.id) {
      oldConfig.storyCluster.removePanelListener(_onPanelsChanged);
      config.storyCluster.addPanelListener(_onPanelsChanged);
    }
  }

  @override
  void dispose() {
    config.storyCluster.removePanelListener(_onPanelsChanged);
    _storyClusterDragStateModel.removeListener(_updateStoryBars);
    super.dispose();
  }

  /// Since we shift the drag feedback based on [DisplayMode] of
  /// [StoryClusterDragFeedback.storyCluster] we need to [setState] when that
  /// change occurs.  [StoryClusterDragFeedback.storyCluster.addPanelListener]
  /// with this function accomplishes this.
  void _onPanelsChanged() => scheduleMicrotask(
        () {
          if (mounted) {
            setState(() {});
          }
        },
      );

  void _updateStoryBars() {
    if (!mounted) {
      return;
    }
    if (!StoryClusterDragStateModel.of(context).isDragging) {
      return;
    }

    if (StoryClusterDragStateModel.of(context).isAcceptable &&
        config.storyCluster.previewStories.isNotEmpty) {
      config.storyCluster.maximizeStoryBars();
    } else {
      config.storyCluster..minimizeStoryBars();

      // Revert to initial story locations and display state.
      config.storyCluster.removePreviews();
      _originalStories.forEach((Story story) {
        config.storyCluster.replaceStoryPanel(
          storyId: story.id,
          withPanel: story.panel,
        );
      });
      config.storyCluster.displayMode = _originalDisplayMode;
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateStoryBars();

    SizeModel sizeModel = SizeModel.of(context, rebuildOnChange: true);
    double width;
    double height;
    double childScale;
    double inlinePreviewScale = StoryListRenderBlock.getInlinePreviewScale(
      sizeModel.size,
    );
    bool isAcceptable = StoryClusterDragStateModel
        .of(
          context,
          rebuildOnChange: true,
        )
        .isAcceptable;

    if (isAcceptable && config.storyCluster.previewStories.isNotEmpty) {
      width = sizeModel.size.width;
      height = sizeModel.size.height;
      childScale = lerpDouble(inlinePreviewScale, 0.7, config.focusProgress);
    } else {
      width = config.storyCluster.storyLayout.size.width;
      height = config.storyCluster.storyLayout.size.height;
      childScale = 1.0;
    }
    double targetWidth =
        (_childKey.currentState == null ? config.initialBounds.width : width) *
            childScale;
    double targetHeight = (_childKey.currentState == null
            ? config.initialBounds.height
            : height) *
        childScale;

    // Determine the fractional bounds of the real stories in this cluster.
    // We do this so we can properly position the drag feedback under the user's
    // finger when in preview mode.
    double realStoriesFractionalLeft = 1.0;
    double realStoriesFractionalRight = 0.0;
    double realStoriesFractionalTop = 1.0;
    double realStoriesFractionalBottom = 0.0;

    config.storyCluster.realStories.forEach((Story story) {
      realStoriesFractionalLeft =
          math.min(realStoriesFractionalLeft, story.panel.left);
      realStoriesFractionalRight =
          math.max(realStoriesFractionalRight, story.panel.right);
      realStoriesFractionalTop =
          math.min(realStoriesFractionalTop, story.panel.top);
      realStoriesFractionalBottom =
          math.max(realStoriesFractionalBottom, story.panel.bottom);
    });

    double realStoriesFractionalCenterX = realStoriesFractionalLeft +
        (realStoriesFractionalRight - realStoriesFractionalLeft) / 2.0;
    double realStoriesFractionalCenterY = realStoriesFractionalTop +
        (realStoriesFractionalBottom - realStoriesFractionalTop) / 2.0;
    double realStoriesFractionalTopY = realStoriesFractionalTop;

    // Since the user begins the drag at config.localDragStartPoint and we want
    // to move the story to a better visual position when previewing we animate
    // its translation when isAcceptable is true.
    // In tab mode we center on the story's story bar.
    // In panel mode we center on the story itself.
    double newDx = isAcceptable || config.localDragStartPoint.x > targetWidth
        ? config.localDragStartPoint.x -
            targetWidth * realStoriesFractionalCenterX
        : 0.0;
    double newDy = isAcceptable || config.localDragStartPoint.y > targetHeight
        ? config.storyCluster.displayMode == DisplayMode.tabs
            ? config.localDragStartPoint.y -
                targetHeight * realStoriesFractionalTopY -
                childScale * _kStoryBarMaximizedHeight
            : config.localDragStartPoint.y -
                targetHeight * realStoriesFractionalCenterY
        : 0.0;

    Size simulatedSizedBoxCurrentSize = _childKey.currentState?.size;
    Size panelsCurrentSize = simulatedSizedBoxCurrentSize == null
        ? new Size(targetWidth, targetHeight)
        : new Size(
            simulatedSizedBoxCurrentSize.width,
            simulatedSizedBoxCurrentSize.height -
                InlineStoryTitle.getHeight(config.focusProgress),
          );

    return new SimulatedTransform(
      initDx: config.initDx,
      targetDx: newDx,
      targetDy: newDy,
      child: new SimulatedSizedBox(
        key: _childKey,
        width: targetWidth,
        height: targetHeight + InlineStoryTitle.getHeight(config.focusProgress),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Expanded(
              child: new StoryPanels(
                key: config.storyCluster.panelsKey,
                storyCluster: config.storyCluster,
                focusProgress: 0.0,
                overlayKey: config.overlayKey,
                storyWidgets: config.storyWidgets,
                paintShadows: true,
                currentSize: panelsCurrentSize,
              ),
            ),
            new InlineStoryTitle(
              focusProgress: config.focusProgress,
              storyCluster: config.storyCluster,
            ),
          ],
        ),
      ),
    );
  }
}
