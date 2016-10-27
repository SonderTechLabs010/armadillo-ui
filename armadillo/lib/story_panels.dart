// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'armadillo_drag_target.dart';
import 'optional_wrapper.dart';
import 'panel.dart';
import 'panel_drag_targets.dart';
import 'simulated_positioned.dart';
import 'simulated_sized_box.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_manager.dart';

/// The height of the vertical gesture detector used to reveal the story bar in
/// full screen mode.
/// TODO(apwilson): Reduce the height of this.  It's large for now for ease of
/// use.
const double _kVerticalGestureDetectorHeight = 32.0;

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedStoryMargin = 4.0;
const double _kStoryMargin = 4.0;
const double _kCornerRadius = 8.0;
const double _kDraggedStoryRadius = 75.0;
const double _kStorySplitAreaWidth = 64.0;
const int _kMaxStories = 4;
const Color _kTargetOverlayColor = const Color.fromARGB(128, 153, 234, 216);
const double _kDragScale = 0.8;

/// Displays up to four stories in a grid-like layout.
class StoryPanels extends StatefulWidget {
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
  StoryPanelsState createState() => new StoryPanelsState();
}

class StoryPanelsState extends State<StoryPanels> {
  @override
  void initState() {
    super.initState();
    config.storyCluster.addPanelListener(_onPanelsChanged);
  }

  @override
  void didUpdateConfig(StoryPanels oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.storyCluster.id != config.storyCluster.id) {
      oldConfig.storyCluster.removePanelListener(_onPanelsChanged);
      config.storyCluster.addPanelListener(_onPanelsChanged);
    }
  }

  @override
  void dispose() {
    config.storyCluster.removePanelListener(_onPanelsChanged);
    super.dispose();
  }

  void _onPanelsChanged() => scheduleMicrotask(() => setState(() {}));

  @override
  Widget build(BuildContext context) => _getDragTarget(
        context: context,
        child: _getPanels(context),
      );

  Widget _getDragTarget({BuildContext context, Widget child}) =>
      new PanelDragTargets(
        key: config.storyCluster.clusterDragTargetsKey,
        scale: _kDragScale,
        focusProgress: config.focusProgress,
        fullSize: config.fullSize,
        storyCluster: config.storyCluster,
        child: child,
      );

  Widget _getPanels(BuildContext context) => new Container(
        foregroundDecoration: config.highlight
            ? new BoxDecoration(
                backgroundColor: _kTargetOverlayColor,
              )
            : null,
        child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              new Stack(
                children: config.storyCluster.stories
                    .map(
                      (Story story) => _getPositioned(
                            story: story,
                            currentSize: new Size(
                                constraints.maxWidth, constraints.maxHeight),
                            fullSize: config.fullSize,
                            child: _getStory(
                              context,
                              story,
                              new Size(
                                config.fullSize.width * story.panel.width,
                                config.fullSize.height * story.panel.height,
                              ),
                            ),
                          ),
                    )
                    .toList(),
              ),
        ),
      );

  Widget _getPositioned({
    Story story,
    Size currentSize,
    Size fullSize,
    Widget child,
  }) {
    Panel panel = story.panel;

    double heightScale = currentSize.height / fullSize.height;
    double widthScale = currentSize.width / fullSize.width;
    double scale = math.min(widthScale, heightScale);
    double scaledHorizontalMargin = _kStoryMargin / 2.0 * scale;
    double scaledVerticalMargin = _kStoryMargin / 2.0 * scale;
    double topMargin = panel.top == 0.0 ? 0.0 : scaledVerticalMargin;
    double leftMargin = panel.left == 0.0 ? 0.0 : scaledHorizontalMargin;
    double bottomMargin = panel.bottom == 1.0 ? 0.0 : scaledVerticalMargin;
    double rightMargin = panel.right == 1.0 ? 0.0 : scaledHorizontalMargin;

    BorderRadius borderRadius = new BorderRadius.all(
      new Radius.circular(scale * _kCornerRadius),
    );

    return story.isPlaceHolder
        ? new Offstage()
        : new SimulatedPositioned(
            key: story.positionedKey,
            top: currentSize.height * panel.top + topMargin,
            left: currentSize.width * panel.left + leftMargin,
            width: currentSize.width * panel.width - leftMargin - rightMargin,
            height:
                currentSize.height * panel.height - topMargin - bottomMargin,
            child: new Container(
              decoration: new BoxDecoration(
                boxShadow: kElevationToShadow[3],
                borderRadius: borderRadius,
              ),
              child: new ClipRRect(
                borderRadius: borderRadius,
                child: child,
              ),
            ),
          );
  }

  Widget _getStoryBarDraggableWrapper({
    BuildContext context,
    Story story,
    Widget child,
  }) =>
      new OptionalWrapper(
        // Don't allow dragging if we're the only story.
        useWrapper: config.storyCluster.stories.length > 1,
        builder: (BuildContext context, Widget child) =>
            new ArmadilloLongPressDraggable<StoryClusterId>(
              key: story.clusterDraggableKey,
              data: story.clusterId,
              onDragStarted: () {
                InheritedStoryManager.of(context).split(
                      storyToSplit: story,
                      from: config.storyCluster,
                    );
                story.storyBarKey.currentState?.minimize();
              },
              childWhenDragging: new Offstage(),
              feedback: new Builder(
                builder: (BuildContext context) {
                  StoryCluster storyCluster = InheritedStoryManager
                      .of(context)
                      .getStoryCluster(story.clusterId);
                  return new StoryClusterDragFeedback(
                    key: storyCluster.dragFeedbackKey,
                    storyCluster: storyCluster,
                    fullSize: config.fullSize,
                    initialSize: new Size(400.0, 300.0),
                  );
                },
              ),
              child: child,
            ),
        child: child,
      );

  Widget _getStory(BuildContext context, Story story, Size size) =>
      story.isPlaceHolder
          ? new Offstage()
          : new Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The story bar that pushes down the story.
                _getStoryBarDraggableWrapper(
                  context: context,
                  story: story,
                  child: new StoryBar(
                    key: story.storyBarKey,
                    story: story,
                    minimizedHeight: _kStoryBarMinimizedHeight,
                    maximizedHeight: _kStoryBarMaximizedHeight,
                  ),
                ),

                // The story itself.
                new Flexible(
                  child: new Container(
                    decoration:
                        new BoxDecoration(backgroundColor: story.themeColor),
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
        child: new SimulatedSizedBox(
          key: story.containerKey,
          width: size.width,
          height: size.height - _kStoryBarMaximizedHeight,
          child: story.builder(context),
        ),
      );
}
