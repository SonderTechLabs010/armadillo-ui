// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'scroll_locker.dart';
import 'simulation_builder.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_keys.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_manager.dart';
import 'story_widget.dart';

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

const double _kStoryInlineTitleHeight = 20.0;

const double _kStoryBarMinimizedHeight = 12.0;
const double _kStoryBarMaximizedHeight = 48.0;

class StoryList extends StatefulWidget {
  final ScrollListener onScroll;
  final VoidCallback onStoryFocusStarted;
  final double bottomPadding;
  final Size parentSize;
  final double quickSettingsHeightBump;
  final bool multiColumn;

  StoryList({
    Key key,
    this.bottomPadding,
    this.onScroll,
    this.onStoryFocusStarted,
    this.parentSize,
    this.quickSettingsHeightBump,
    this.multiColumn: false,
  })
      : super(key: key);

  @override
  StoryListState createState() => new StoryListState();
}

class StoryListState extends State<StoryList> {
  final GlobalKey<ScrollableState> _scrollableKey =
      new GlobalKey<ScrollableState>();
  final GlobalKey<ScrollLockerState> _scrollLockerKey =
      new GlobalKey<ScrollLockerState>();

  double _quickSettingsProgress = 0.0;
  double _onFocusScrollOffset = 0.0;

  /// [quickSettingsProgress] ranges from 0.0 to 1.0 and reflects the progress
  /// of [Now]'s animation to reveal quick settings.  This is currently piped
  /// here from [Conductor].
  set quickSettingsProgress(double quickSettingsProgress) {
    // When quick settings starts being shown, scroll to 0.0.
    if (_quickSettingsProgress == 0.0 && quickSettingsProgress > 0.0) {
      _scrollableKey.currentState.scrollTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    }
    _quickSettingsProgress = quickSettingsProgress;
  }

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

    return new Stack(
      children: [
        // Recent List.
        new Positioned(
          left: 0.0,
          right: 0.0,
          top: -_quickSettingsHeightDelta,
          bottom: _quickSettingsHeightDelta,
          child: new ScrollLocker(
            key: _scrollLockerKey,
            child: new StoryListBlock(
              scrollableKey: _scrollableKey,
              bottomPadding: config.bottomPadding,
              onScroll: config.onScroll,
              parentSize: config.parentSize,
              scrollOffset: _onFocusScrollOffset,
              children: stories.map(
                (Story story) {
                  return new StoryListChild(
                    story: story,
                    focusProgress: StoryKeys
                            .storyFocusSimulationKey(story)
                            .currentState
                            ?.progress ??
                        0.0,
                    child: new Stack(
                      children: <Widget>[
                        new SimulationBuilder(
                          key: StoryKeys.storyFocusSimulationKey(story),
                          initialSimulationProgress: 0.0,
                          builder: (BuildContext context, double progress) =>
                              new StoryWidget(
                                focusProgress: progress,
                                fullSize: config.parentSize,
                                story: story,
                                multiColumn: config.multiColumn,
                                storyBar: new StoryBar(
                                  key: StoryKeys.storyBarKey(story),
                                  story: story,
                                  minimizedHeight: _kStoryBarMinimizedHeight,
                                  maximizedHeight: _kStoryBarMaximizedHeight,
                                ),
                              ),
                          onSimulationChanged: (double progress, bool isDone) {
                            setState(() {});
                            if (progress == 1.0 && isDone) {
                              focusStory(story);
                            }
                          },
                        ),
                        new Positioned(
                          left: 0.0,
                          right: 0.0,
                          top: 0.0,
                          bottom: 0.0,
                          child: new Offstage(
                            offstage: _inFocus(story),
                            child: new GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                bool storyInFocus = false;
                                stories.forEach((Story s) {
                                  if (_inFocus(s)) {
                                    storyInFocus = true;
                                  }
                                });

                                if (!storyInFocus) {
                                  // Bring tapped story into focus.
                                  StoryKeys
                                      .storyFocusSimulationKey(story)
                                      .currentState
                                      ?.forward();
                                  StoryKeys
                                      .storyBarKey(story)
                                      .currentState
                                      ?.maximize();

                                  // Lock scrolling.
                                  _scrollLockerKey.currentState.lock();
                                  setState(() {
                                    _onFocusScrollOffset = _scrollableKey
                                        .currentState.scrollOffset;
                                  });

                                  config.onStoryFocusStarted?.call();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void defocus() {
    // Unfocus all stories.
    InheritedStoryManager.of(context).stories.forEach(_unfocusStory);

    // Unlock scrolling.
    _scrollLockerKey.currentState.unlock();
    setState(() {
      _scrollableKey.currentState.scrollTo(0.0);
      _onFocusScrollOffset = 0.0;
    });
  }

  void focusStory(Story story) {
    InheritedStoryManager
        .of(context)
        .stories
        .where((Story s) => s.id != story.id)
        .forEach(_unfocusStory);
    InheritedStoryManager.of(context).interactionStarted(story);
    StoryKeys
        .storyFocusSimulationKey(story)
        .currentState
        ?.forward(jumpToFinish: true);
    StoryKeys.storyBarKey(story).currentState?.maximize(jumpToFinish: true);
    _scrollLockerKey.currentState.lock();
  }

  void _unfocusStory(Story s) {
    StoryKeys.storyFocusSimulationKey(s).currentState?.reverse();
    StoryKeys.storyBarKey(s).currentState?.minimize();
  }

  bool _inFocus(Story s) =>
      (StoryKeys.storyFocusSimulationKey(s).currentState?.progress ?? 0.0) >
      0.0;

  double get _quickSettingsHeightDelta =>
      _quickSettingsProgress * config.quickSettingsHeightBump;
}

class LockingScrollConfigurationDelegate extends ScrollConfigurationDelegate {
  final bool lock;
  const LockingScrollConfigurationDelegate({this.lock: false});

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  ExtentScrollBehavior createScrollBehavior() {
    return lock
        ? new LockedUnboundedBehavior(platform: platform)
        : new OverscrollWhenScrollableBehavior(platform: platform);
  }

  @override
  bool updateShouldNotify(LockingScrollConfigurationDelegate old) {
    return lock != old.lock;
  }
}

class LockedUnboundedBehavior extends UnboundedBehavior {
  LockedUnboundedBehavior({
    double contentExtent: double.INFINITY,
    double containerExtent: 0.0,
    TargetPlatform platform,
  })
      : super(
          contentExtent: contentExtent,
          containerExtent: containerExtent,
          platform: platform,
        );

  @override
  bool get isScrollable => false;
}

class StoryListBlock extends Block {
  final Size parentSize;
  final double scrollOffset;
  final double bottomPadding;
  StoryListBlock({
    Key key,
    List<Widget> children,
    this.bottomPadding,
    ScrollListener onScroll,
    Key scrollableKey,
    this.parentSize,
    this.scrollOffset,
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
          scrollOffset: scrollOffset,
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
