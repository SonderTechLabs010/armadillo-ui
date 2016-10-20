// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'armadillo_drag_target.dart';
import 'long_hover_detector.dart';
import 'optional_wrapper.dart';
import 'story.dart';
import 'story_carousel.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_manager.dart';
import 'story_panels.dart';
import 'story_title.dart';

/// The minimum story height.
const double _kMinimumStoryHeight = 200.0;

/// In multicolumn mode, the distance from the parent's edge the largest story
/// will be.
const double _kMultiColumnMargin = 64.0;

/// In multicolumn mode, the aspect ratio of a story.
const double _kWidthToHeightRatio = 16.0 / 9.0;

/// In single column mode, the distance from a story and other UI elements.
const double _kSingleColumnStoryMargin = 8.0;

/// In multicolumn mode, the minimum distance from a story and other UI
/// elements.
const double _kMultiColumnMinimumStoryMargin = 8.0;

/// The height of the vertical gesture detector used to reveal the story bar in
/// full screen mode.
/// TODO(apwilson): Reduce the height of this.  It's large for now for ease of
/// use.
const double _kVerticalGestureDetectorHeight = 32.0;

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kStoryInlineTitleHeight = 20.0;
const double _kDraggedStoryRadius = 75.0;
const int _kMaxStories = 4;
const Color _kTargetOverlayColor = const Color.fromARGB(128, 153, 234, 216);

/// Set to true to use a carousel in single column mode.
const bool _kUseCarousel = false;

/// The visual representation of a [Story].  A [Story] has a default size but
/// will expand to [fullSize] when it comes into focus.  [StoryClusterWidget]s
/// are intended to be children of [StoryList].
class StoryClusterWidget extends StatelessWidget {
  final StoryCluster storyCluster;
  final bool multiColumn;
  final Size fullSize;
  final double focusProgress;
  final VoidCallback onGainFocus;
  StoryClusterWidget({
    Key key,
    this.storyCluster,
    this.multiColumn,
    this.fullSize,
    this.focusProgress,
    this.onGainFocus,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => new OptionalWrapper(
        // Don't accept data if we're focused or focusing.
        useWrapper: _isUnfocused,
        builder: (BuildContext context, Widget child) =>
            new ArmadilloDragTarget<Object>(
              onWillAccept: (Object data, Point point) {
                StoryCluster storyCluster =
                    InheritedStoryManager.of(context).getStoryCluster(data);
                // Don't accept empty data.
                if (storyCluster == null || storyCluster.stories.isEmpty) {
                  return false;
                }

                // Don't accept data that has a story that matches any of our
                // current stories.
                bool result = true;
                storyCluster.stories.forEach((Story s1) {
                  if (result) {
                    this.storyCluster.stories.forEach((Story s2) {
                      if (result && s1.id == s2.id) {
                        result = false;
                      }
                    });
                  }
                });

                return result;
              },
              onAccept: (Object data, Point point) {
                StoryCluster storyCluster =
                    InheritedStoryManager.of(context).getStoryCluster(data);

                InheritedStoryManager.of(context).combine(
                      source: storyCluster,
                      target: this.storyCluster,
                      size: fullSize,
                    );
                onGainFocus();
              },
              builder: (
                BuildContext context,
                Map<Object, Point> candidateData,
                Map<dynamic, Point> rejectedData,
              ) =>
                  _getUnfocusedDragTargetChild(context,
                      hasCandidates: candidateData.isNotEmpty),
            ),
        child: _getStoryClusterWithInlineStoryTitle(context, highlight: false),
      );

  Widget _getUnfocusedDragTargetChild(
    BuildContext context, {
    bool hasCandidates,
  }) =>
      new LongHoverDetector(
        hovering: hasCandidates,
        onLongHover: onGainFocus,
        child: new OptionalWrapper(
          useWrapper: _isUnfocused && !hasCandidates,
          builder: (BuildContext context, Widget child) =>
              new ArmadilloLongPressDraggable(
                key: new GlobalObjectKey(storyCluster.clusterDraggableId),
                data: storyCluster.id,
                childWhenDragging: new Offstage(),
                feedback: new Builder(builder: (BuildContext context) {
                  RenderBox box =
                      new GlobalObjectKey(storyCluster.clusterDragTargetsId)
                          .currentContext
                          .findRenderObject();
                  return new StoryClusterDragFeedback(
                    key: new GlobalObjectKey(storyCluster.dragFeedbackId),
                    storyCluster: storyCluster,
                    fullSize: fullSize,
                    initialSize: box.size,
                  );
                }),
                child: child,
              ),
          child: _getStoryClusterWithInlineStoryTitle(
            context,
            highlight: hasCandidates,
          ),
        ),
      );

  Widget _getStoryClusterWithInlineStoryTitle(
    BuildContext context, {
    bool highlight: false,
  }) =>
      new Stack(
        children: [
          new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              new Flexible(
                  child: _getStoryCluster(context, highlight: highlight)),
              _inlineStoryTitle,
            ],
          ),
          _focusOnTap,
        ],
      );

  /// The Story including its StoryBar.
  Widget _getStoryCluster(
    BuildContext context, {
    bool highlight: false,
  }) =>
      multiColumn || !_kUseCarousel
          ? new StoryPanels(
              storyCluster: storyCluster,
              focusProgress: focusProgress,
              fullSize: fullSize,
              highlight: highlight,
            )
          : new StoryCarousel(
              key: new GlobalObjectKey(storyCluster.carouselId),
              stories: storyCluster.stories,
              focusProgress: focusProgress,
              fullSize: fullSize,
              highlight: highlight,
            );

  /// The Story Title that hovers below the story itself.
  Widget get _inlineStoryTitle => new Container(
        height: _inlineStoryTitleHeight,
        child: new OverflowBox(
          minHeight: _kStoryInlineTitleHeight,
          maxHeight: _kStoryInlineTitleHeight,
          child: new Padding(
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 4.0,
            ),
            child: new Opacity(
              opacity: 1.0 - focusProgress,
              child: new Align(
                alignment: FractionalOffset.bottomLeft,
                child: new StoryTitle(title: storyCluster.title),
              ),
            ),
          ),
        ),
      );

  Widget get _focusOnTap => new Positioned(
        left: 0.0,
        right: 0.0,
        top: 0.0,
        bottom: 0.0,
        child: new Offstage(
          offstage: !_isUnfocused,
          child: new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onGainFocus,
          ),
        ),
      );

  bool get _isUnfocused => focusProgress == 0.0;

  double get _inlineStoryTitleHeight =>
      lerpDouble(_kStoryInlineTitleHeight, 0.0, focusProgress);
}
