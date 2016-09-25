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
  StoryWidget({
    Key key,
    this.story,
    this.multiColumn,
    this.fullSize,
    this.focusProgress,
    StoryBar storyBar,
  })
      : this.storyBar = storyBar,
        this.storyBarKey = storyBar.key,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Offstage(
      offstage: story.inactive,
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Story.
          new Flexible(
            child: new ClipRRect(
              borderRadius:
                  new BorderRadius.circular(4.0 * (1.0 - focusProgress)),
              child: new Container(
                decoration:
                    new BoxDecoration(backgroundColor: new Color(0xFFFF0000)),
                child: new Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The story bar that pushes down the story.
                    storyBar,

                    // The scaled and clipped story.  When full size, the story will
                    // no longer be scaled or clipped due to the nature of the
                    // calculations of scale, width, height, and margins above.
                    new Flexible(
                      child: new Stack(
                        children: [
                          // Touch listener that activates in full screen mode.
                          // When a touch comes in we hide the story bar.
                          new Listener(
                            onPointerDown:
                                (focusProgress == 1.0 && !multiColumn)
                                    ? (PointerDownEvent event) {
                                        storyBarKey.currentState.hide();
                                      }
                                    : null,
                            behavior: HitTestBehavior.translucent,
                            child: new ClipRect(
                              child: new FittedBox(
                                fit: ImageFit.cover,
                                alignment: FractionalOffset.topCenter,
                                child: new SizedBox(
                                  width: fullSize.width,
                                  height: fullSize.height -
                                      (multiColumn
                                          ? _kStoryBarMaximizedHeight
                                          : 0.0),
                                  child: multiColumn
                                      ? story.wideBuilder(context)
                                      : story.builder(context),
                                ),
                              ),
                            ),
                          ),

                          // Vertical gesture detector that activates in full screen
                          // mode.  When a drag down from top of screen occurs we
                          // show the story bar.
                          new Positioned(
                            top: 0.0,
                            left: 0.0,
                            right: 0.0,
                            height: _kVerticalGestureDetectorHeight,
                            child: new GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragUpdate:
                                  (focusProgress == 1.0 && !multiColumn)
                                      ? (DragUpdateDetails details) {
                                          storyBarKey.currentState.show();
                                        }
                                      : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Inline Story Title.
          new Container(
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
          ),
        ],
      ),
    );
  }

  double get _inlineStoryTitleHeight =>
      _kStoryInlineTitleHeight * (1.0 - focusProgress);
}
