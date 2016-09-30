// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'story_carousel.dart';
import 'story_cluster.dart';
import 'story_panels.dart';

const double _kDraggedStoryRadius = 75.0;

/// Displays a representation of a StoryCluster while being dragged.
class StoryClusterDragFeedback extends StatelessWidget {
  final StoryCluster storyCluster;
  final Size fullSize;
  final bool multiColumn;
  StoryClusterDragFeedback({
    this.storyCluster,
    this.fullSize,
    this.multiColumn,
  });

  @override
  Widget build(BuildContext context) => new Transform(
        transform: new Matrix4.translationValues(
            -_kDraggedStoryRadius, -_kDraggedStoryRadius, 0.0),
        child: new ClipOval(
          child: new Container(
            width: 2.0 * _kDraggedStoryRadius,
            height: 2.0 * _kDraggedStoryRadius,
            foregroundDecoration: new BoxDecoration(
              backgroundColor: new Color(0x80FFFF00),
            ),
            child: _getStoryCluster(context),
          ),
        ),
      );

  Widget _getStoryCluster(
    BuildContext context, {
    bool highlight: false,
  }) =>
      new Container(
        decoration: new BoxDecoration(
          boxShadow: kElevationToShadow[12],
          borderRadius: new BorderRadius.circular(4.0),
        ),
        foregroundDecoration: new BoxDecoration(
          backgroundColor: new Color(0x80FFFF00),
        ),
        child: new ClipRRect(
          borderRadius: new BorderRadius.circular(4.0),
          child: multiColumn
              ? new StoryPanels(
                  storyCluster: storyCluster,
                  focusProgress: 0.0,
                  fullSize: fullSize,
                )
              : new StoryCarousel(
                  key: new GlobalObjectKey(storyCluster.carouselId),
                  stories: storyCluster.stories,
                  focusProgress: 0.0,
                  fullSize: fullSize,
                ),
        ),
      );
}
