// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'story.dart';
import 'story_bar.dart';
import 'story_keys.dart';

/// The height of the vertical gesture detector used to reveal the story bar in
/// full screen mode.
/// TODO(apwilson): Reduce the height of this.  It's large for now for ease of
/// use.
const double _kVerticalGestureDetectorHeight = 32.0;

const double _kStoryBarMinimizedHeight = 12.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedStoryMargin = 4.0;
const double _kFocusedStoryMargin = 8.0;

/// Displays up to four stories in a grid-like layout.
class StoryPanels extends StatelessWidget {
  final List<Story> stories;
  final double focusProgress;
  final bool multiColumn;
  final Size fullSize;
  StoryPanels({
    this.stories,
    this.focusProgress,
    this.multiColumn,
    this.fullSize,
  });

  @override
  Widget build(BuildContext context) => new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: new List<Widget>.generate(
          _rowCount,
          (int rowIndex) => new Flexible(
                child: new Row(
                  children: new List<Widget>.generate(
                    _columnCount(rowIndex),
                    (int columnIndex) => new Flexible(
                          child: new Padding(
                            padding: new EdgeInsets.only(
                              left: columnIndex == 0
                                  ? 0.0
                                  : _lerp(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                              right: columnIndex == 1 ||
                                      _columnCount(rowIndex) == 1
                                  ? 0.0
                                  : _lerp(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                              top: rowIndex == 0
                                  ? 0.0
                                  : _lerp(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                              bottom: rowIndex == 1 || _rowCount == 1
                                  ? 0.0
                                  : _lerp(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                            ),
                            child: _getStory(
                                context,
                                stories[_storyIndex(rowIndex, columnIndex)],
                                _getSizeFromStoryIndex(
                                  _storyIndex(rowIndex, columnIndex),
                                )),
                          ),
                        ),
                  ),
                ),
              ),
        ),
      );

  int _columnCount(int rowIndex) => (stories.length - rowIndex * 2);
  int get _rowCount => stories.length > 2 ? 2 : 1;
  int _storyIndex(int rowIndex, int columnIndex) => rowIndex * 2 + columnIndex;

  Size _getSizeFromStoryIndex(int storyIndex) {
    if (stories.length == 1) {
      return fullSize;
    }
    if (stories.length == 2) {
      return new Size(
          (fullSize.width - _kFocusedStoryMargin) / 2.0, fullSize.height);
    }
    if (stories.length == 3) {
      if (storyIndex < 2) {
        return new Size(
            (fullSize.width - _kFocusedStoryMargin) / 2.0, fullSize.height);
      }
      return new Size(
          fullSize.width, (fullSize.height - _kFocusedStoryMargin) / 2.0);
    } else {
      return new Size((fullSize.width - _kFocusedStoryMargin) / 2.0,
          (fullSize.height - _kFocusedStoryMargin) / 2.0);
    }
  }

  Widget _getStory(BuildContext context, Story story, Size size) => new Column(
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
      );

  /// The scaled and clipped story.  When full size, the story will
  /// no longer be scaled or clipped.
  Widget _getStoryContents(BuildContext context, Story story, Size size) =>
      new FittedBox(
        fit: ImageFit.cover,
        alignment: FractionalOffset.topCenter,
        child: new SizedBox(
          width: size.width,
          height: size.height - (multiColumn ? _kStoryBarMaximizedHeight : 0.0),
          child:
              multiColumn ? story.wideBuilder(context) : story.builder(context),
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

  double _lerp(double a, double b, double t) => (1.0 - t) * a + t * b;
}
