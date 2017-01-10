// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'armadillo_drag_target.dart';
import 'armadillo_overlay.dart';
import 'long_hover_detector.dart';
import 'nothing.dart';
import 'optional_wrapper.dart';
import 'panel_drag_targets.dart';
import 'story.dart';
import 'story_carousel.dart';
import 'story_cluster.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_id.dart';
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

const double _kStoryInlineTitleHeight = 20.0;
const double _kDraggedStoryRadius = 75.0;
const int _kMaxStories = 4;
const Color _kTargetOverlayColor = const Color.fromARGB(128, 153, 234, 216);

/// Set to true to use a carousel in single column mode.
const bool _kUseCarousel = false;

const double _kDragScale = 0.8;

/// The visual representation of a [Story].  A [Story] has a default size but
/// will expand to [fullSize] when it comes into focus.  [StoryClusterWidget]s
/// are intended to be children of [StoryList].
class StoryClusterWidget extends StatelessWidget {
  final StoryCluster storyCluster;
  final bool multiColumn;
  final double focusProgress;
  final VoidCallback onGainFocus;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final Map<StoryId, Widget> storyWidgets;

  StoryClusterWidget({
    Key key,
    this.storyCluster,
    this.multiColumn,
    this.focusProgress,
    this.onGainFocus,
    this.overlayKey,
    this.storyWidgets,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget widget = new OptionalWrapper(
      // Don't accept data if we're focused or focusing.
      useWrapper: _isUnfocused,
      builder: (BuildContext context, Widget child) =>
          new ArmadilloDragTarget<StoryClusterId>(
            onWillAccept: (StoryClusterId storyClusterId, Point point) {
              StoryCluster storyCluster = InheritedStoryManager
                  .of(context)
                  .getStoryCluster(storyClusterId);
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
            onAccept: (StoryClusterId storyClusterId, Point point) {
              InheritedStoryManager.of(context).combine(
                    source: InheritedStoryManager
                        .of(context)
                        .getStoryCluster(storyClusterId),
                    target: storyCluster,
                  );
              onGainFocus();
            },
            builder: (
              BuildContext context,
              Map<StoryClusterId, Point> candidateData,
              Map<dynamic, Point> rejectedData,
            ) =>
                _getUnfocusedDragTargetChild(context,
                    hasCandidates: candidateData.isNotEmpty),
          ),
      child: _getStoryClusterWithInlineStoryTitle(context, highlight: false),
    );
    return widget;
  }

  Widget _getUnfocusedDragTargetChild(
    BuildContext context, {
    bool hasCandidates,
  }) =>
      new OptionalWrapper(
        useWrapper: _isUnfocused && !hasCandidates,
        builder: (BuildContext context, Widget child) =>
            new ArmadilloLongPressDraggable<StoryClusterId>(
              key: storyCluster.clusterDraggableKey,
              overlayKey: overlayKey,
              data: storyCluster.id,
              childWhenDragging: Nothing.widget,
              feedback: new StoryClusterDragFeedback(
                key: storyCluster.dragFeedbackKey,
                storyCluster: storyCluster,
                storyWidgets: storyWidgets,
              ),
              child: child,
            ),
        child: _getStoryClusterWithInlineStoryTitle(
          context,
          highlight: hasCandidates,
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
              new Expanded(
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
          ? new PanelDragTargets(
              key: storyCluster.clusterDragTargetsKey,
              scale: _kDragScale,
              focusProgress: focusProgress,
              storyCluster: storyCluster,
              child: new StoryPanels(
                storyCluster: storyCluster,
                focusProgress: focusProgress,
                highlight: highlight,
                overlayKey: overlayKey,
                storyWidgets: storyWidgets,
              ),
            )
          : new StoryCarousel(
              key: storyCluster.carouselKey,
              stories: storyCluster.stories,
              focusProgress: focusProgress,
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
            child: new Align(
              alignment: FractionalOffset.bottomLeft,
              child: new StoryTitle(
                title: storyCluster.title,
                opacity: 1.0 - focusProgress,
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
