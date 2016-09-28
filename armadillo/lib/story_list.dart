// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'simulation_builder.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster_widget.dart';
import 'story_keys.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_manager.dart';

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

const double _kStoryInlineTitleHeight = 20.0;

const double _kStoryBarMinimizedHeight = 12.0;
const double _kStoryBarMaximizedHeight = 48.0;

typedef void OnStoryFocusCompleted(Story story);

class StoryList extends StatelessWidget {
  final ScrollListener onScroll;
  final VoidCallback onStoryFocusStarted;
  final OnStoryFocusCompleted onStoryFocusCompleted;
  final double bottomPadding;
  final Size parentSize;
  final double quickSettingsHeightBump;
  final bool multiColumn;
  final Key scrollableKey;

  StoryList({
    Key key,
    this.scrollableKey,
    this.bottomPadding,
    this.onScroll,
    this.onStoryFocusStarted,
    this.onStoryFocusCompleted,
    this.parentSize,
    this.quickSettingsHeightBump,
    this.multiColumn: false,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Story> stories = new List<Story>.from(
      InheritedStoryManager.of(context).stories,
    );

    // Remove inactive stories.
    stories.removeWhere((Story a) => a.inactive);

    // Sort recently interacted with stories to the start of the list.
    stories.sort((Story a, Story b) =>
        b.lastInteraction.millisecondsSinceEpoch -
        a.lastInteraction.millisecondsSinceEpoch);

    return new StoryListBlock(
      scrollableKey: scrollableKey,
      bottomPadding: bottomPadding,
      onScroll: onScroll,
      parentSize: parentSize,
      children: stories
          .map((Story story) => _createFocusableStory(stories, story))
          .toList(),
    );
  }

  Widget _createFocusableStory(List<Story> stories, Story story) =>
      new SimulationBuilder(
        key: StoryKeys.storyFocusSimulationKey(story),
        onSimulationChanged: (double progress, bool isDone) {
          if (progress == 1.0 && isDone) {
            onStoryFocusCompleted?.call(story);
          }
        },
        builder: (BuildContext context, double progress) => new StoryListChild(
              story: story,
              focusProgress: progress,
              child: _createStory(stories, story, progress),
            ),
      );

  Widget _createStory(List<Story> stories, Story story, double progress) =>
      new StoryWidget(
          focusProgress: progress,
          fullSize: parentSize,
          story: story,
          multiColumn: multiColumn,
          storyBar: new StoryBar(
            key: StoryKeys.storyBarKey(story),
            story: story,
            minimizedHeight: _kStoryBarMinimizedHeight,
            maximizedHeight: _kStoryBarMaximizedHeight,
          ),
          onGainFocus: () {
            bool storyInFocus = false;
            stories.forEach((Story s) {
              if (_inFocus(s)) {
                storyInFocus = true;
              }
            });

            if (!storyInFocus) {
              // Bring tapped story into focus.
              StoryKeys.storyFocusSimulationKey(story).currentState?.forward();
              StoryKeys.storyBarKey(story).currentState?.maximize();

              onStoryFocusStarted?.call();
            }
          });

  bool _inFocus(Story s) =>
      (StoryKeys.storyFocusSimulationKey(s).currentState?.progress ?? 0.0) >
      0.0;
}

class StoryListBlock extends Block {
  final Size parentSize;
  final double bottomPadding;
  StoryListBlock({
    Key key,
    List<Widget> children,
    this.bottomPadding,
    ScrollListener onScroll,
    Key scrollableKey,
    this.parentSize,
  })
      : super(
          key: key,
          children: children,
          scrollDirection: Axis.vertical,
          scrollAnchor: ViewportAnchor.end,
          onScroll: onScroll,
          scrollableKey: scrollableKey,
        ) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  @override
  Widget build(BuildContext context) => new ScrollableViewport(
        scrollableKey: scrollableKey,
        initialScrollOffset: initialScrollOffset,
        scrollDirection: scrollDirection,
        scrollAnchor: scrollAnchor,
        onScrollStart: onScrollStart,
        onScroll: onScroll,
        onScrollEnd: onScrollEnd,
        child: new StoryListBlockBody(
          children: children,
          parentSize: parentSize,
          scrollOffset: (scrollableKey as GlobalKey<ScrollableState>)
                  .currentState
                  ?.scrollOffset ??
              0.0,
          bottomPadding: bottomPadding,
        ),
      );
}

class StoryListBlockBody extends BlockBody {
  final Size parentSize;
  final double scrollOffset;
  final double bottomPadding;
  StoryListBlockBody({
    Key key,
    List<Widget> children,
    this.parentSize,
    this.scrollOffset,
    this.bottomPadding,
  })
      : super(key: key, mainAxis: Axis.vertical, children: children);

  @override
  StoryListRenderBlock createRenderObject(BuildContext context) =>
      new StoryListRenderBlock(
        parentSize: parentSize,
        scrollOffset: scrollOffset,
        bottomPadding: bottomPadding,
      );

  @override
  void updateRenderObject(
      BuildContext context, StoryListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
    renderObject.parentSize = parentSize;
    renderObject.scrollOffset = scrollOffset;
    renderObject.bottomPadding = bottomPadding;
  }
}

class StoryListChild extends ParentDataWidget<StoryListBlockBody> {
  final Story story;
  final double focusProgress;
  StoryListChild({
    Widget child,
    this.story,
    this.focusProgress,
  })
      : super(child: child);
  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListRenderBlockParentData);
    final StoryListRenderBlockParentData parentData = renderObject.parentData;
    parentData.story = story;
    parentData.focusProgress = focusProgress;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('story: $story, focusProgress: $focusProgress');
  }
}
