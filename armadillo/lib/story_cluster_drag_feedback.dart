// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'armadillo_overlay.dart';
import 'panel.dart';
import 'simulated_sized_box.dart';
import 'simulated_translation_transform.dart';
import 'size_manager.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

const double _kStoryBarMaximizedHeight = 48.0;

/// Displays a representation of a StoryCluster while being dragged.
class StoryClusterDragFeedback extends StatefulWidget {
  final StoryCluster storyCluster;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final Map<StoryId, Widget> storyWidgets;

  StoryClusterDragFeedback({
    Key key,
    this.overlayKey,
    this.storyCluster,
    this.storyWidgets,
  })
      : super(key: key);

  @override
  StoryClusterDragFeedbackState createState() =>
      new StoryClusterDragFeedbackState();
}

class StoryClusterDragFeedbackState extends State<StoryClusterDragFeedback> {
  final GlobalKey _translationKey = new GlobalKey();
  final GlobalKey _boxKey = new GlobalKey();
  final SizeManager childSizeManager = new SizeManager(Size.zero);
  Map<Object, Panel> _storyPanels = new Map<Object, Panel>();
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

    return new SimulatedTranslationTransform(
      key: _translationKey,
      dx: -width / 2.0,
      dy: -height / 2.0,
      child: new Transform(
        transform: new Matrix4.identity().scaled(childScale, childScale),
        alignment: FractionalOffset.center,
        child: new SimulatedSizedBox(
          key: _boxKey,
          width: width,
          height: height,
          child: new InheritedSizeManager(
            sizeManager: childSizeManager,
            child: new Opacity(
              opacity: opacity,
              child: new StoryPanels(
                storyCluster: config.storyCluster,
                focusProgress: 0.0,
                highlight: false,
                overlayKey: config.overlayKey,
                storyWidgets: config.storyWidgets,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
