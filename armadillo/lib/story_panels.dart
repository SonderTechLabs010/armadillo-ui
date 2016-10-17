// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'armadillo_drag_target.dart';
import 'optional_wrapper.dart';
import 'panel.dart';
import 'panel_drag_targets.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_keys.dart';
import 'story_manager.dart';

/// The height of the vertical gesture detector used to reveal the story bar in
/// full screen mode.
/// TODO(apwilson): Reduce the height of this.  It's large for now for ease of
/// use.
const double _kVerticalGestureDetectorHeight = 32.0;

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedStoryMargin = 4.0;
const double _kStoryMargin = 8.0;
const double _kCornerRadius = 12.0;
const double _kDraggedStoryRadius = 75.0;
const double _kStorySplitAreaWidth = 64.0;
const int _kMaxStories = 4;
const Color _kTargetOverlayColor = const Color.fromARGB(128, 153, 234, 216);
const double _kDragScale = 0.8;

/// Displays up to four stories in a grid-like layout.
class StoryPanels extends StatelessWidget {
  final StoryCluster storyCluster;
  final double focusProgress;
  final Size fullSize;
  final bool highlight;

  StoryPanels({
    this.storyCluster,
    this.focusProgress,
    this.fullSize,
    this.highlight,
  }) {
    assert(() {
      Panel.haveFullCoverage(
        storyCluster.stories
            .map(
              (Story story) => story.panel,
            )
            .toList(),
      );
      return true;
    });
  }

  @override
  Widget build(BuildContext context) => _getDragTarget(
        context: context,
        child: _getPanels(context),
      );

  Widget _getDragTarget({BuildContext context, Widget child}) =>
      new PanelDragTargets(
        key: new GlobalObjectKey(storyCluster.clusterDragTargetsId),
        scale: _kDragScale,
        focusProgress: focusProgress,
        fullSize: fullSize,
        storyCluster: storyCluster,
        child: child,
      );

  Widget _getPanels(BuildContext context) => new Container(
        decoration: new BoxDecoration(
          boxShadow: kElevationToShadow[12],
          borderRadius: new BorderRadius.circular(
            lerpDouble(4.0, 0.0, focusProgress),
          ),
        ),
        foregroundDecoration: highlight
            ? new BoxDecoration(
                backgroundColor: _kTargetOverlayColor,
              )
            : null,
        child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              new Stack(
                children: storyCluster.stories
                    .map(
                      (Story story) => _getPositioned(
                            panel: story.panel,
                            currentSize: new Size(
                                constraints.maxWidth, constraints.maxHeight),
                            fullSize: fullSize,
                            child: _getStory(
                              context,
                              story,
                              new Size(
                                fullSize.width * story.panel.width,
                                fullSize.height * story.panel.height,
                              ),
                            ),
                          ),
                    )
                    .toList(),
              ),
        ),
      );

  Positioned _getPositioned({
    Panel panel,
    Size currentSize,
    Size fullSize,
    Widget child,
  }) {
    double heightScale = currentSize.height / fullSize.height;
    double widthScale = currentSize.width / fullSize.width;
    double scaledHorizontalMargin = _kStoryMargin / 2.0 * widthScale;
    double scaledVerticalMargin = _kStoryMargin / 2.0 * heightScale;
    double topMargin = panel.top == 0.0 ? 0.0 : scaledVerticalMargin;
    double leftMargin = panel.left == 0.0 ? 0.0 : scaledHorizontalMargin;
    double bottomMargin = panel.bottom == 1.0 ? 0.0 : scaledVerticalMargin;
    double rightMargin = panel.right == 1.0 ? 0.0 : scaledHorizontalMargin;

    return new Positioned(
      top: currentSize.height * panel.top + topMargin,
      left: currentSize.width * panel.left + leftMargin,
      width: currentSize.width * panel.width - leftMargin - rightMargin,
      height: currentSize.height * panel.height - topMargin - bottomMargin,
      child: new ClipRRect(
          borderRadius: new BorderRadius.all(
            new Radius.elliptical(
              widthScale * _kCornerRadius,
              heightScale * _kCornerRadius,
            ),
          ),
          child: child),
    );
  }

  Widget _getStoryBarDraggableWrapper({
    BuildContext context,
    Story story,
    Widget child,
  }) =>
      new OptionalWrapper(
        // Don't allow dragging if we're the only story.
        useWrapper: storyCluster.stories.length > 1,
        builder: (BuildContext context, Widget child) =>
            new ArmadilloLongPressDraggable(
              key: new GlobalObjectKey(story.clusterDraggableId),
              data: new StoryCluster.fromStory(
                story.copyWith(
                  panel: new Panel(),
                ),
              ),
              onDragStarted: () {
                InheritedStoryManager.of(context).split(
                      storyToSplit: story,
                      from: storyCluster,
                    );
                StoryKeys.storyBarKey(story).currentState?.minimize();
              },
              childWhenDragging: new Offstage(offstage: true),
              feedback: new StoryClusterDragFeedback(
                storyCluster: new StoryCluster.fromStory(story),
                fullSize: fullSize,
                multiColumn: true,
              ),
              child: child,
            ),
        child: child,
      );

  Widget _getStory(BuildContext context, Story story, Size size) => new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The story bar that pushes down the story.
          _getStoryBarDraggableWrapper(
            context: context,
            story: story,
            child: new StoryBar(
              key: StoryKeys.storyBarKey(story),
              story: story,
              minimizedHeight: _kStoryBarMinimizedHeight,
              maximizedHeight: _kStoryBarMaximizedHeight,
            ),
          ),

          // The story itself.
          new Flexible(
            child: new Container(
              decoration: new BoxDecoration(backgroundColor: story.themeColor),
              child: _getStoryContents(context, story, size),
            ),
          ),
        ],
      );

  /// The scaled and clipped story.  When full size, the story will
  /// no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context, Story story, Size size) =>
      new FittedBox(
        fit: ImageFit.cover,
        alignment: FractionalOffset.topCenter,
        child: new SizedBox(
          width: size.width,
          height: size.height - _kStoryBarMaximizedHeight,
          child: story.builder(context),
        ),
      );
}
