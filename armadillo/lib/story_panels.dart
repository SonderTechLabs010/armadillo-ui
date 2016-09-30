// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'optional_wrapper.dart';
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

const double _kStoryBarMinimizedHeight = 12.0;
const double _kStoryBarMaximizedHeight = 48.0;
const double _kUnfocusedStoryMargin = 4.0;
const double _kFocusedStoryMargin = 8.0;
const double _kDraggedStoryRadius = 75.0;
const double _kStorySplitAreaWidth = 64.0;
const int _kMaxStories = 4;

/// Displays up to four stories in a grid-like layout.
class StoryPanels extends StatelessWidget {
  final StoryCluster storyCluster;
  final double focusProgress;
  final Size fullSize;
  StoryPanels({
    this.storyCluster,
    this.focusProgress,
    this.fullSize,
  });

  @override
  Widget build(BuildContext context) => _getDragTarget(
        context: context,
        child: _getPanels(context),
      );

  Widget _getDragTarget({BuildContext context, Widget child}) =>
      new DragTarget<StoryCluster>(
        // We set the key to be based on the specific stories of the StoryCluster
        // because we need to rebuild when the stories in the storyCluster change.
        // Otherwise, when you pick up a story from this cluster we will ignore it
        // on the first onWillAccept call.  This ensures when the clusters are
        // recreated we will call onWillAccept again.
        key: new GlobalObjectKey(Story.storyListHashCode(storyCluster.stories)),
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
          data.stories.forEach((Story story) {
            StoryKeys.storyBarKey(story).currentState?.maximize();
          });
        },
        builder: (
          BuildContext context,
          List<StoryCluster> candidateData,
          List<dynamic> rejectedData,
        ) =>
            new Padding(
              padding: new EdgeInsets.all(
                candidateData.isEmpty
                    ? 0.0
                    : _kStorySplitAreaWidth * focusProgress,
              ),
              child: child,
            ),
      );

  Widget _getPanels(BuildContext context) => new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: new List<Widget>.generate(
          _rowCount,
          (int rowIndex) => new Flexible(
                child: new Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: new List<Widget>.generate(
                    _columnCount(rowIndex),
                    (int columnIndex) => new Flexible(
                          child: new Padding(
                            padding: new EdgeInsets.only(
                              left: columnIndex == 0
                                  ? 0.0
                                  : lerpDouble(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                              right: columnIndex == 1 ||
                                      _columnCount(rowIndex) == 1
                                  ? 0.0
                                  : lerpDouble(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                              top: rowIndex == 0
                                  ? 0.0
                                  : lerpDouble(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                              bottom: rowIndex == 1 || _rowCount == 1
                                  ? 0.0
                                  : lerpDouble(
                                        _kUnfocusedStoryMargin,
                                        _kFocusedStoryMargin,
                                        focusProgress,
                                      ) /
                                      2.0,
                            ),
                            child: _getStory(
                                context,
                                storyCluster.stories[_storyIndex(
                                  rowIndex,
                                  columnIndex,
                                )],
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

  int _columnCount(int rowIndex) =>
      math.min(2, (storyCluster.stories.length - rowIndex * 2));
  int get _rowCount => storyCluster.stories.length > 2 ? 2 : 1;
  int _storyIndex(int rowIndex, int columnIndex) => rowIndex * 2 + columnIndex;

  Size _getSizeFromStoryIndex(int storyIndex) {
    if (storyCluster.stories.length == 1) {
      return fullSize;
    }
    if (storyCluster.stories.length == 2) {
      return new Size(
          (fullSize.width - _kFocusedStoryMargin) / 2.0, fullSize.height);
    }
    if (storyCluster.stories.length == 3) {
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

  Widget _getStoryBarDraggableWrapper({
    BuildContext context,
    Story story,
    Widget child,
  }) =>
      new OptionalWrapper(
        // Don't allow dragging if we're the only story.
        useWrapper: storyCluster.stories.length > 1,
        builder: (BuildContext context, Widget child) => new LongPressDraggable(
              key: new GlobalObjectKey(story.clusterDraggableId),
              data: new StoryCluster.fromStory(story),
              dragAnchor: DragAnchor.pointer,
              maxSimultaneousDrags: 1,
              onDraggableCanceled: (Velocity velocity, Offset offset) {
                // TODO(apwilson): This should eventually never happen.
              },
              childWhenDragging: new Builder(builder: (BuildContext context) {
                scheduleMicrotask(() {
                  InheritedStoryManager
                      .of(context)
                      .split(story: story, from: storyCluster);
                  StoryKeys.storyBarKey(story).currentState?.minimize();
                });
                return new Offstage(offstage: true);
              }),
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
            child: _getStoryContents(context, story, size),
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
          child: story.wideBuilder(context),
        ),
      );
}
