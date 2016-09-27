// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'story.dart';
import 'story_bar.dart';
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

/// The visual representation of a [Story].  A [Story] has a default size but
/// will expand to [fullSize] when it comes into focus.  [StoryWidget]s are
/// intended to be children of [StoryList].
class StoryWidget extends StatelessWidget {
  final Story story;
  final bool multiColumn;
  final Size fullSize;
  final double focusProgress;
  final StoryBar storyBar;
  final GlobalKey<StoryBarState> storyBarKey;
  final VoidCallback onGainFocus;
  StoryWidget({
    Key key,
    this.story,
    this.multiColumn,
    this.fullSize,
    this.focusProgress,
    StoryBar storyBar,
    this.onGainFocus,
  })
      : this.storyBar = storyBar,
        this.storyBarKey = storyBar.key,
        super(key: key);

  @override
  Widget build(BuildContext context) => new DragTarget<Story>(
        onWillAccept: (Story data) {
          // TODO(apwilson): Don't accept if we already have too many stories.
          return data.id != story.id;
        },
        onAccept: (Story data) {
          // TODO(apwilson): Join the story with the others.
        },
        builder: (
          BuildContext context,
          List<Story> candidateData,
          List<dynamic> rejectedData,
        ) =>
            new LongPressDraggable(
              data: story,
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
                    child: _getStoryWithInlineStoryTitle(context),
                  ),
                ),
              ),
              child: _getStoryWithInlineStoryTitle(context),
            ),
      );

  Widget _getStoryWithInlineStoryTitle(BuildContext context) => new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _getStory(context),
          _inlineStoryTitle,
        ],
      );

  /// The Story including its StoryBar.
  Widget _getStory(BuildContext context) => new Flexible(
        child: new ClipRRect(
          borderRadius: new BorderRadius.circular(4.0 * (1.0 - focusProgress)),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The story bar that pushes down the story.
              storyBar,

              // The story itself.
              new Flexible(
                child: new Stack(
                  children: [
                    _getStoryContents(context),
                    _touchDetectorToHideStoryBar,
                    _verticalDragDetectorToShowStoryBar,
                    _focusOnTap,
                  ],
                ),
              ),
            ],
          ),
        ),
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
                child: new StoryTitle(title: story.title),
              ),
            ),
          ),
        ),
      );

  /// The scaled and clipped story.  When full size, the story will
  /// no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context) => new FittedBox(
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
  Widget get _touchDetectorToHideStoryBar => new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        bottom: 0.0,
        child: new Offstage(
          offstage: _storyBarIsImmutable,
          child: new Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => storyBarKey.currentState.hide(),
          ),
        ),
      );

  /// Vertical gesture detector that activates in full screen
  /// mode.  When a drag down from top of screen occurs we
  /// show the story bar.
  Widget get _verticalDragDetectorToShowStoryBar => new Positioned(
        top: 0.0,
        left: 0.0,
        right: 0.0,
        height: _kVerticalGestureDetectorHeight,
        child: new Offstage(
          offstage: _storyBarIsImmutable,
          child: new GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (_) => storyBarKey.currentState.show(),
          ),
        ),
      );

  bool get _storyBarIsImmutable => (focusProgress != 1.0 || multiColumn);

  double get _inlineStoryTitleHeight =>
      _kStoryInlineTitleHeight * (1.0 - focusProgress);
}
