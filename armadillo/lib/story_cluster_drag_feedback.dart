// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'panel.dart';
import 'simulated_sized_box.dart';
import 'simulated_translation_transform.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

/// Displays a representation of a StoryCluster while being dragged.
class StoryClusterDragFeedback extends StatefulWidget {
  final StoryCluster storyCluster;
  final Size fullSize;
  final Size initialSize;

  StoryClusterDragFeedback({
    Key key,
    this.storyCluster,
    this.fullSize,
    this.initialSize,
  })
      : super(key: key);

  @override
  StoryClusterDragFeedbackState createState() =>
      new StoryClusterDragFeedbackState();
}

class StoryClusterDragFeedbackState extends State<StoryClusterDragFeedback> {
  final GlobalKey _translationKey = new GlobalKey();
  final GlobalKey _boxKey = new GlobalKey();
  Map<Object, Panel> _storyPanels = new Map<Object, Panel>();
  double _widthFactor;
  double _heightFactor;

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
      if (_storyPanels.isEmpty) {
        config.storyCluster.stories.forEach((Story story) {
          story.storyBarKey.currentState.minimize();
        });
      } else {
        config.storyCluster.stories.forEach((Story story) {
          story.storyBarKey.currentState.maximize();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width;
    double height;
    if (_storyPanels.isNotEmpty) {
      width = config.fullSize.width * _widthFactor * 0.7;
      height = config.fullSize.height * _heightFactor * 0.7;
    } else {
      width = config.initialSize.width;
      height = config.initialSize.height;
    }

    return new SimulatedTranslationTransform(
      key: _translationKey,
      dx: -width / 2.0,
      dy: -height / 2.0,
      child: new Opacity(
        opacity: _storyPanels.isNotEmpty ? 1.0 : 0.7,
        child: new SimulatedSizedBox(
          key: _boxKey,
          width: width,
          height: height,
          child: new StoryPanels(
            storyCluster: config.storyCluster,
            focusProgress: 0.0,
            fullSize: _storyPanels.isNotEmpty
                ? new Size(width, height)
                : config.fullSize,
            highlight: false,
          ),
        ),
      ),
    );
  }
}
