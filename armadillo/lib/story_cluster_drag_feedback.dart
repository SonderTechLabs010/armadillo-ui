// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'armadillo_overlay.dart';
import 'panel.dart';
import 'simulated_sized_box.dart';
import 'simulated_transform.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
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
  final bool showTitle;
  final bool focused;

  StoryClusterDragFeedback({
    Key key,
    this.overlayKey,
    this.storyCluster,
    this.storyWidgets,
    this.localDragStartPoint,
    this.initialBounds,
    this.showTitle: false,
    this.focused: true,
  })
      : super(key: key);

  @override
  StoryClusterDragFeedbackState createState() =>
      new StoryClusterDragFeedbackState();
}

class StoryClusterDragFeedbackState extends State<StoryClusterDragFeedback> {
  final GlobalKey _childKey = new GlobalKey();
  Map<Object, Panel> _storyPanels = <Object, Panel>{};
  double _widthFactor;
  double _heightFactor;
  DisplayMode _displayModeOverride;
  int _targetClusterStoryCount;

  set storyPanels(Map<Object, Panel> storyPanels) {
    setState(() {
      _storyPanels = new Map<Object, Panel>.from(storyPanels);
      double minLeft = 1.0;
      double minTop = 1.0;
      double maxRight = 0.0;
      double maxBottom = 0.0;
      _storyPanels.values.forEach((Panel panel) {
        minLeft = math.min(minLeft, panel.left);
        minTop = math.min(minTop, panel.top);
        maxRight = math.max(maxRight, panel.right);
        maxBottom = math.max(maxBottom, panel.bottom);
      });
      _widthFactor = maxRight - minLeft;
      _heightFactor = maxBottom - minTop;
      _updateStoryBars();
    });
  }

  set displayMode(DisplayMode displayMode) {
    setState(() {
      _displayModeOverride = displayMode;
      config.storyCluster.displayMode = displayMode;
      config.storyCluster.focusedStoryId = null;
      _updateStoryBars();
    });
  }

  set targetClusterStoryCount(int targetClusterStoryCount) {
    setState(() {
      _targetClusterStoryCount = targetClusterStoryCount;
    });
  }

  void _updateStoryBars() {
    if (!config.focused ||
        (_storyPanels.isEmpty && _displayModeOverride == DisplayMode.panels)) {
      config.storyCluster.stories.forEach((Story story) {
        story.storyBarKey.currentState.minimize();
      });
    } else {
      config.storyCluster.stories.forEach((Story story) {
        story.storyBarKey.currentState.maximize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SizeModel sizeModel = SizeModel.of(context, rebuildOnChange: true);
    double width;
    double height;
    double childScale;
    double focusProgress = config.showTitle
        ? config.storyCluster.focusSimulationKey.currentState?.progress ?? 0.0
        : 1.0;
    double inlinePreviewScale = StoryListRenderBlock.getInlinePreviewScale(
      sizeModel.size,
    );

    if (_displayModeOverride == DisplayMode.tabs) {
      width = (config.focused
              ? sizeModel.size.width
              : config.storyCluster.storyLayout.size.width) *
          (config.storyCluster.stories.length + 1) /
          (_targetClusterStoryCount + 1);
      height = (config.focused
          ? _kStoryBarMaximizedHeight
          : _kStoryBarMinimizedHeight);
      childScale = lerpDouble(inlinePreviewScale, 0.7, focusProgress);
    } else if (_storyPanels.isNotEmpty) {
      width = sizeModel.size.width * _widthFactor;
      height = sizeModel.size.height * _heightFactor;
      childScale = lerpDouble(inlinePreviewScale, 0.7, focusProgress);
    } else {
      width = config.storyCluster.storyLayout.size.width;
      height = config.storyCluster.storyLayout.size.height;
      childScale = 1.0;
    }
    return new SimulatedSizedBox(
      key: _childKey,
      width: (_childKey.currentState == null
              ? config.initialBounds.width
              : width) *
          childScale,
      height: (_childKey.currentState == null
                  ? config.initialBounds.height
                  : height) *
              childScale +
          InlineStoryTitle.getHeight(focusProgress),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Expanded(
            child: new Stack(
              children: <Widget>[
                new SimulatedTransform(
                  initOpacity: 0.0,
                  targetOpacity: 1.0,
                  child: new Container(
                    decoration: new BoxDecoration(
                      boxShadow: kElevationToShadow[12],
                      borderRadius: new BorderRadius.all(
                        new Radius.circular(
                          lerpDouble(
                            _kUnfocusedCornerRadius,
                            _kFocusedCornerRadius,
                            focusProgress,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                new StoryPanels(
                  key: config.storyCluster.panelsKey,
                  storyCluster: config.storyCluster,
                  focusProgress: 0.0,
                  overlayKey: config.overlayKey,
                  storyWidgets: config.storyWidgets,
                ),
              ],
            ),
          ),
          new InlineStoryTitle(
            focusProgress: focusProgress,
            storyCluster: config.storyCluster,
          ),
        ],
      ),
    );
  }
}
