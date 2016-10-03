// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'carousel.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_keys.dart';

/// The height of the vertical gesture detector used to reveal the story bar in
/// full screen mode.
/// TODO(apwilson): Reduce the height of this.  It's large for now for ease of
/// use.
const double _kVerticalGestureDetectorHeight = 32.0;

const double _kStoryBarMinimizedHeight = 4.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedStoryMargin = 4.0;
const double _kFocusedStoryMargin = 8.0;
const Color _kTargetOverlayColor = const Color.fromARGB(128, 153, 234, 216);

/// Displays up to four stories in a carousel layout.
class StoryCarousel extends StatelessWidget {
  final List<Story> stories;
  final double focusProgress;
  final Size fullSize;
  final bool highlight;
  StoryCarousel({
    Key key,
    this.stories,
    this.focusProgress,
    this.fullSize,
    this.highlight,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => new Carousel(
        children: stories
            .map((Story story) => _getStory(context, story, fullSize))
            .toList(),
        itemExtent: fullSize.width,
        onItemChanged: (int index) {},
        onItemSelected: (int index) {},
        locked: stories.length == 1,
      );

  Widget _getStory(BuildContext context, Story story, Size size) =>
      new Container(
        decoration: new BoxDecoration(
          boxShadow: kElevationToShadow[12],
          borderRadius:
              new BorderRadius.circular(lerpDouble(4.0, 0.0, focusProgress)),
        ),
        foregroundDecoration: highlight
            ? new BoxDecoration(
                backgroundColor: _kTargetOverlayColor,
              )
            : null,
        child: new ClipRRect(
          borderRadius:
              new BorderRadius.circular(lerpDouble(4.0, 0.0, focusProgress)),
          child: new Column(
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
                    _getStoryContents(context, story, size),
                    _getTouchDetectorToHideStoryBar(story),
                    _getVerticalDragDetectorToShowStoryBar(story),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  /// The scaled and clipped story.
  ///
  /// When full size, the story will no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context, Story story, Size size) =>
      new FittedBox(
        fit: ImageFit.cover,
        alignment: FractionalOffset.topCenter,
        child: new SizedBox(
          width: size.width,
          height: size.height,
          child: story.builder(context),
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

  bool get _storyBarIsImmutable => (focusProgress != 1.0);
}
