// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'focusable_story.dart';
import 'story.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_manager.dart';

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

const double _kStoryInlineTitleHeight = 20.0;

class StoryList extends StatefulWidget {
  final Key scrollableKey;
  final ScrollListener onScroll;
  final VoidCallback onStoryFocusStarted;
  final EdgeInsets padding;
  final Size parentSize;
  final double quickSettingsHeightBump;
  final bool multiColumn;

  StoryList({
    Key key,
    this.scrollableKey,
    this.padding,
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
  /// When true, list scrolling is disabled and vertical gestures will no longer
  /// be stolen by the [Scrollable] with the key [config.scrollableKey].
  /// This gets set to true when a [Story] comes into focus.
  bool _lockScrolling = false;

  /// When set, this story will begin fully expanded with its story bar
  /// maximized.
  Story _initiallyFocusedStory;

  double _quickSettingsProgress = 0.0;
  double _onFocusScrollOffset = 0.0;

  /// [quickSettingsProgress] ranges from 0.0 to 1.0 and reflects the progress
  /// of [Now]'s animation to reveal quick settings.  This is currently piped
  /// here from [Conductor].
  set quickSettingsProgress(double quickSettingsProgress) {
    // When quick settings starts being shown, scroll to 0.0.
    if (_quickSettingsProgress == 0.0 && quickSettingsProgress > 0.0) {
      GlobalKey<ScrollableState> scrollableKey = config.scrollableKey;
      scrollableKey.currentState.scrollTo(
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

    Story initiallyFocusedStory = _initiallyFocusedStory;
    _initiallyFocusedStory = null;

    return new Stack(
      children: [
        // Recent List.
        new Positioned(
          left: 0.0,
          right: 0.0,
          top: -_quickSettingsHeightDelta,
          bottom: _quickSettingsHeightDelta,
          child: new ScrollConfiguration(
            delegate:
                new LockingScrollConfigurationDelegate(lock: _lockScrolling),
            child: new StoryListBlock(
              scrollableKey: config.scrollableKey,
              padding: config.padding,
              onScroll: config.onScroll,
              parentSize: config.parentSize,
              scrollOffset: _onFocusScrollOffset,
              children: stories.map(
                (Story story) {
                  final stackChildren = <Widget>[
                    new FocusableStory(
                      key: new GlobalObjectKey(story.id),
                      fullSize: config.parentSize,
                      story: story,
                      onStoryFocused: focusStory,
                      onFocusProgressChanged: () => setState(() {}),
                      multiColumn: config.multiColumn,
                      startFocused: initiallyFocusedStory?.id == story.id,
                    ),
                  ];
                  if (!_lockScrolling) {
                    stackChildren.add(
                      new Positioned(
                        left: 0.0,
                        right: 0.0,
                        top: 0.0,
                        bottom: 0.0,
                        child: new GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // Bring tapped story into focus.
                            FocusableStoryState tappedFocusableStoryState =
                                new GlobalObjectKey(story.id).currentState;
                            tappedFocusableStoryState.focused = true;

                            // Lock scrolling.
                            setState(() {
                              _lockScrolling = true;
                              GlobalKey<ScrollableState> scrollableKey =
                                  config.scrollableKey;
                              _onFocusScrollOffset =
                                  scrollableKey.currentState.scrollOffset;
                            });

                            config.onStoryFocusStarted?.call();
                          },
                        ),
                      ),
                    );
                  }
                  return new StoryListChild(
                    story: story,
                    focusProgress:
                        new GlobalObjectKey<FocusableStoryState>(story.id)
                                .currentState
                                ?.focusProgress ??
                            0.0,
                    child: new Stack(children: stackChildren),
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
    InheritedStoryManager.of(context).stories.forEach(
      (Story s) {
        new GlobalObjectKey<FocusableStoryState>(s.id).currentState?.focused =
            false;
      },
    );

    // Unlock scrolling.
    setState(() {
      _lockScrolling = false;
      GlobalKey<ScrollableState> scrollableKey = config.scrollableKey;
      scrollableKey.currentState.scrollTo(0.0);
      _onFocusScrollOffset = 0.0;
    });
  }

  void focusStory(Story story) {
    InheritedStoryManager.of(context).interactionStarted(story);
    setState(() {
      _initiallyFocusedStory = story;
      _lockScrolling = true;
    });
  }

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
  StoryListBlock({
    Key key,
    List<Widget> children,
    EdgeInsets padding,
    ScrollListener onScroll,
    Key scrollableKey,
    this.parentSize,
    this.scrollOffset,
  })
      : super(
          key: key,
          children: children,
          padding: padding,
          scrollDirection: Axis.vertical,
          scrollAnchor: ViewportAnchor.end,
          onScroll: onScroll,
          scrollableKey: scrollableKey,
        ) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  @override
  Widget build(BuildContext context) {
    Widget contents = new StoryListBlockBody(
      children: children,
      parentSize: parentSize,
      scrollOffset: scrollOffset - (padding?.bottom ?? 0.0),
    );
    if (padding != null) {
      contents = new Padding(padding: padding, child: contents);
    }
    return new ScrollableViewport(
      scrollableKey: scrollableKey,
      initialScrollOffset: initialScrollOffset,
      scrollDirection: scrollDirection,
      scrollAnchor: scrollAnchor,
      onScrollStart: onScrollStart,
      onScroll: onScroll,
      onScrollEnd: onScrollEnd,
      child: contents,
    );
  }
}

class StoryListBlockBody extends BlockBody {
  final Size parentSize;
  final double scrollOffset;
  StoryListBlockBody({
    Key key,
    List<Widget> children,
    this.parentSize,
    this.scrollOffset,
  })
      : super(key: key, mainAxis: Axis.vertical, children: children);

  @override
  StoryListRenderBlock createRenderObject(BuildContext context) =>
      new StoryListRenderBlock(
        parentSize: parentSize,
        scrollOffset: scrollOffset,
      );

  @override
  void updateRenderObject(
      BuildContext context, StoryListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
    renderObject.parentSize = parentSize;
    renderObject.scrollOffset = scrollOffset;
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
