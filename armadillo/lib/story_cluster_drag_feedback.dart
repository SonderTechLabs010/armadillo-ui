// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'armadillo_overlay.dart';
import 'panel.dart';
import 'simulated_sized_box.dart';
import 'simulated_transform.dart';
import 'size_manager.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_widget.dart';
import 'story_panels.dart';

const double _kStoryBarMaximizedHeight = 48.0;

/// Displays a representation of a StoryCluster while being dragged.
class StoryClusterDragFeedback extends StatefulWidget {
  final StoryCluster storyCluster;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final Map<StoryId, Widget> storyWidgets;
  final Point localDragStartPoint;
  final Rect initialBounds;
  final bool showTitle;

  StoryClusterDragFeedback({
    Key key,
    this.overlayKey,
    this.storyCluster,
    this.storyWidgets,
    this.localDragStartPoint,
    this.initialBounds,
    this.showTitle: false,
  })
      : super(key: key);

  @override
  StoryClusterDragFeedbackState createState() =>
      new StoryClusterDragFeedbackState();
}

class StoryClusterDragFeedbackState extends State<StoryClusterDragFeedback> {
  final GlobalKey _translationKey = new GlobalKey();
  final SizeManager childSizeManager = new SizeManager(Size.zero);
  Map<Object, Panel> _storyPanels = <Object, Panel>{};
  double _widthFactor;
  double _heightFactor;
  DisplayMode _displayModeOverride;
  int _targetClusterStoryCount;
  FractionalOffset _alignment;

  @override
  void initState() {
    super.initState();
    _alignment = new FractionalOffset(
      config.localDragStartPoint.x / config.initialBounds.width,
      config.localDragStartPoint.y / config.initialBounds.height,
    );
  }

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
    if (_storyPanels.isEmpty && _displayModeOverride == DisplayMode.panels) {
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
    SizeManager sizeManager = InheritedSizeManager.of(
      context,
      rebuildOnChange: true,
    );
    double width;
    double height;
    double childScale;
    double opacity;
    if (_displayModeOverride == DisplayMode.tabs) {
      width = sizeManager.size.width *
          (config.storyCluster.stories.length + 1) /
          (_targetClusterStoryCount + 1);
      height = sizeManager.size.height *
          (_kStoryBarMaximizedHeight / sizeManager.size.height);
      childScale = 0.7;
      opacity = 1.0;
    } else if (_storyPanels.isNotEmpty) {
      width = sizeManager.size.width * _widthFactor;
      height = sizeManager.size.height * _heightFactor;
      childScale = 0.7;
      opacity = 1.0;
    } else {
      width = config.storyCluster.storyLayout.size.width;
      height = config.storyCluster.storyLayout.size.height;
      childScale = 1.0;
      opacity = 0.7;
    }
    childSizeManager.size =
        _storyPanels.isNotEmpty ? new Size(width, height) : sizeManager.size;
    double focusProgress = config.showTitle
        ? config.storyCluster.focusSimulationKey.currentState?.progress ?? 0.0
        : 1.0;
    return new SimulatedTransform(
      key: _translationKey,
      targetScale: childScale,
      targetOpacity: opacity,
      alignment: _alignment,
      child: new SimulatedSizedBox(
        width: _translationKey.currentState == null
            ? config.initialBounds.width
            : width,
        height: (_translationKey.currentState == null
                ? config.initialBounds.height
                : height) +
            InlineStoryTitle.getHeight(focusProgress),
        child: new InheritedSizeManager(
          sizeManager: childSizeManager,
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              new Expanded(
                child: new StoryPanels(
                  key: config.storyCluster.panelsKey,
                  storyCluster: config.storyCluster,
                  focusProgress: 0.0,
                  highlight: false,
                  overlayKey: config.overlayKey,
                  storyWidgets: config.storyWidgets,
                ),
              ),
              new InlineStoryTitle(
                focusProgress: focusProgress,
                storyCluster: config.storyCluster,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
