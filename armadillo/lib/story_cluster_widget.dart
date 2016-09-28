// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'long_hover_detector.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster.dart';
import 'story_keys.dart';
import 'story_manager.dart';
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

const double _kStoryBarMinimizedHeight = 12.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kStoryInlineTitleHeight = 20.0;
const double _kDraggedStoryRadius = 75.0;
const int _kMaxStories = 4;
const Color _kTargetOverlayColor = const Color.fromARGB(128, 153, 234, 216);

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
  Widget build(BuildContext context) => new DragTarget<StoryCluster>(
        onWillAccept: (StoryCluster data) {
          // Don't accept empty data.
          if (data == null || data.stories.isEmpty) {
            return false;
          }

          // Don't accept data if it would put us over the story limit.
          if (storyCluster.stories.length + data.stories.length >
              _kMaxStories) {
            return false;
          }

          // Don't accept data that has a story that matches any of our current
          // stories.
          bool result = true;
          data.stories.forEach((Story s1) {
            if (result) {
              storyCluster.stories.forEach((Story s2) {
                if (result && s1.id == s2.id) {
                  result = false;
                }
              });
            }
          });

          return result;
        },
        onAccept: (StoryCluster data) {
          InheritedStoryManager
              .of(context)
              .combine(source: data, target: storyCluster);
        },
        builder: (
          BuildContext context,
          List<StoryCluster> candidateData,
          List<dynamic> rejectedData,
        ) =>
            new LongHoverDetector(
              hovering: candidateData.isNotEmpty,
              onLongHover: onGainFocus,
              child: new LongPressDraggable(
                data: storyCluster,
                feedbackOffset:
                    new Offset(-_kDraggedStoryRadius, -_kDraggedStoryRadius),
                dragAnchor: DragAnchor.pointer,
                maxSimultaneousDrags: 1,
                onDraggableCanceled: (Velocity velocity, Offset offset) {
                  // TODO(apwilson): Somehow animate back the 'childWhenDragging.
                },
                childWhenDragging: new Container(),
                feedback: new Transform(
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
                ),
                child: _getStoryClusterWithInlineStoryTitle(
                  context,
                  highlight: candidateData.isNotEmpty,
                ),
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
      new Container(
        decoration: new BoxDecoration(
          boxShadow: kElevationToShadow[12],
          borderRadius:
              new BorderRadius.circular(_lerp(4.0, 0.0, focusProgress)),
        ),
        foregroundDecoration: highlight
            ? new BoxDecoration(
                backgroundColor: _kTargetOverlayColor,
              )
            : null,
        child: new ClipRRect(
          borderRadius:
              new BorderRadius.circular(_lerp(4.0, 0.0, focusProgress)),
          child: new Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: storyCluster.stories
                .map((Story story) => new Flexible(
                      child: new Padding(
                        padding: new EdgeInsets.only(
                          left: storyCluster.stories[0] == story
                              ? 0.0
                              : _lerp(4.0, 8.0, focusProgress),
                        ),
                        child: _getStory(context, story),
                      ),
                    ))
                .toList(),
          ),
        ),
      );

  Widget _getStory(BuildContext context, Story story) => new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The story bar that pushes down the story.
          new StoryBar(
            key: StoryKeys.storyBarKey(story),
            story: story,
            minimizedHeight: _kStoryBarMinimizedHeight,
            maximizedHeight: _kStoryBarMaximizedHeight,
          ),

          // The story itself.
          new Flexible(
            child: new Stack(
              children: [
                _getStoryContents(context, story),
                _getTouchDetectorToHideStoryBar(story),
                _getVerticalDragDetectorToShowStoryBar(story),
              ],
            ),
          ),
        ],
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

  /// The scaled and clipped story.  When full size, the story will
  /// no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context, Story story) => new FittedBox(
        fit: ImageFit.cover,
        alignment: FractionalOffset.topCenter,
        child: new SizedBox(
          width: fullSize.width,
          height:
              fullSize.height - (multiColumn ? _kStoryBarMaximizedHeight : 0.0),
          child:
              multiColumn ? story.wideBuilder(context) : story.builder(context),
        ),
      );

  Widget get _focusOnTap => new Positioned(
        left: 0.0,
        right: 0.0,
        top: 0.0,
        bottom: 0.0,
        child: new Offstage(
          offstage: focusProgress > 0.0,
          child: new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onGainFocus,
          ),
        ),
      );

  /// Touch listener that activates in full screen mode.
  /// When a touch comes in we hide the story bar.
  Widget _getTouchDetectorToHideStoryBar(Story story) => new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        bottom: 0.0,
        child: new Offstage(
          offstage: _storyBarIsImmutable,
          child: new Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) =>
                StoryKeys.storyBarKey(story).currentState.hide(),
          ),
        ),
      );

  /// Vertical gesture detector that activates in full screen
  /// mode.  When a drag down from top of screen occurs we
  /// show the story bar.
  Widget _getVerticalDragDetectorToShowStoryBar(Story story) => new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        height: _kVerticalGestureDetectorHeight,
        child: new Offstage(
          offstage: _storyBarIsImmutable,
          child: new GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (_) =>
                StoryKeys.storyBarKey(story).currentState.show(),
          ),
        ),
      );

  bool get _storyBarIsImmutable => (focusProgress != 1.0 || multiColumn);

  double get _inlineStoryTitleHeight =>
      _lerp(_kStoryInlineTitleHeight, 0.0, focusProgress);

  double _lerp(double a, double b, double t) => (1.0 - t) * a + t * b;
}
