// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'focusable_story.dart';
import 'story_manager.dart';

export 'focusable_story.dart' show Story, OnStoryFocused;

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

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
    // Sort recently interacted with stories to the start of the list.
    stories.sort((Story a, Story b) =>
        b.lastInteraction.millisecondsSinceEpoch -
        a.lastInteraction.millisecondsSinceEpoch);

    Story initiallyFocusedStory = _initiallyFocusedStory;
    _initiallyFocusedStory = null;

    return new Stack(
      children: [
        // Story List.
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
              multiColumn: config.multiColumn,
              children: stories.map(
                (Story story) {
                  final stackChildren = <Widget>[
                    new FocusableStory(
                      key: new GlobalObjectKey(story.id),
                      fullSize: config.parentSize,
                      story: story,
                      onStoryFocused: focusStory,
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

                            // Since the tapped story is now coming into focus, scroll
                            // the list such that the bottom of the story will align
                            // with the bottom of the parent.
                            RenderBox listBox = context.findRenderObject();
                            Point listTopLeft =
                                listBox.localToGlobal(Point.origin);
                            RenderBox storyBox = new GlobalObjectKey(story.id)
                                .currentContext
                                .findRenderObject();
                            Point storyTopLeft =
                                storyBox.localToGlobal(Point.origin);
                            double scrollDelta =
                                (listBox.size.height + listTopLeft.y) -
                                    (storyTopLeft.y + storyBox.size.height);

                            GlobalKey<ScrollableState> scrollableKey =
                                config.scrollableKey;

                            FocusGainScroller scroller = new FocusGainScroller(
                              initialScrollOffset:
                                  scrollableKey.currentState.scrollOffset,
                              scrollDelta: scrollDelta,
                              scrollableKey: scrollableKey,
                              focusableStoryKey: new GlobalObjectKey(story.id),
                            );
                            scroller.startListening();

                            // Lock scrolling.
                            setState(() {
                              _lockScrolling = true;
                            });

                            if (config.onStoryFocusStarted != null) {
                              config.onStoryFocusStarted();
                            }
                          },
                        ),
                      ),
                    );
                  }
                  return new Stack(children: stackChildren);
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
    InheritedStoryManager.of(context).stories.forEach((Story s) {
      FocusableStoryState untappedFocusableStoryState =
          new GlobalObjectKey(s.id).currentState;
      untappedFocusableStoryState.focused = false;
    });

    // Unlock scrolling.
    setState(() {
      _lockScrolling = false;
    });
  }

  void focusStory(Story story) {
    InheritedStoryManager.of(context).interactionStarted(story);
    GlobalKey<ScrollableState> scrollableKey = config.scrollableKey;
    scrollableKey.currentState.scrollTo(config.padding.bottom);
    setState(() {
      _initiallyFocusedStory = story;
      _lockScrolling = true;
    });
  }

  double get _quickSettingsHeightDelta =>
      _quickSettingsProgress * config.quickSettingsHeightBump;
}

/// When started, adds itself as a listener to the [FocusableStory] with key
/// [focusableStoryKey] and then removes itself when that story becomes fully in
/// focus.  Uses the [FocusableStory]'s focus progress (which goes from 0 to 1)
/// to set the scroll offset.
/// As the story comes into focus the [Scrollable] with a key of
/// [scrollableKey]'s scrollOffset will be set to:
/// [initialScrollOffset] + [scrollDelta].
class FocusGainScroller {
  final double initialScrollOffset;
  final double scrollDelta;
  final GlobalKey<ScrollableState> scrollableKey;
  final GlobalKey<FocusableStoryState> focusableStoryKey;

  FocusGainScroller(
      {this.initialScrollOffset,
      this.scrollDelta,
      this.scrollableKey,
      this.focusableStoryKey});

  void startListening() {
    focusableStoryKey.currentState.addProgressListener(onProgress);
  }

  void stopListening() {
    focusableStoryKey.currentState.removeProgressListener(onProgress);
  }

  void onProgress(double progress, bool isDone) {
    if (isDone && progress == 1.0) {
      stopListening();
    }
    scrollableKey.currentState
        ?.scrollTo(initialScrollOffset + scrollDelta * progress);
  }
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
  LockedUnboundedBehavior(
      {double contentExtent: double.INFINITY,
      double containerExtent: 0.0,
      TargetPlatform platform})
      : super(
            contentExtent: contentExtent,
            containerExtent: containerExtent,
            platform: platform);

  @override
  bool get isScrollable => false;
}

class StoryListBlock extends Block {
  final bool multiColumn;
  StoryListBlock(
      {Key key,
      List<Widget> children,
      EdgeInsets padding,
      ScrollListener onScroll,
      Key scrollableKey,
      this.multiColumn: false})
      : super(
            key: key,
            children: children,
            padding: padding,
            scrollDirection: Axis.vertical,
            scrollAnchor: ViewportAnchor.end,
            onScroll: onScroll,
            scrollableKey: scrollableKey) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  @override
  Widget build(BuildContext context) {
    Widget contents =
        new StoryListBlockBody(multiColumn: multiColumn, children: children);
    if (padding != null)
      contents = new Padding(padding: padding, child: contents);
    return new ScrollableViewport(
        scrollableKey: scrollableKey,
        initialScrollOffset: initialScrollOffset,
        scrollDirection: scrollDirection,
        scrollAnchor: scrollAnchor,
        onScrollStart: onScrollStart,
        onScroll: onScroll,
        onScrollEnd: onScrollEnd,
        child: contents);
  }
}

class StoryListBlockBody extends BlockBody {
  final bool multiColumn;
  StoryListBlockBody({Key key, this.multiColumn, List<Widget> children})
      : super(key: key, mainAxis: Axis.vertical, children: children);

  @override
  StoryListRenderBlock createRenderObject(BuildContext context) =>
      new StoryListRenderBlock(multiColumn: multiColumn);

  @override
  void updateRenderObject(
      BuildContext context, StoryListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
    renderObject.multiColumn = multiColumn;
  }
}

class StoryListRenderBlock extends RenderBlock {
  StoryListRenderBlock({List<RenderBox> children, bool multiColumn})
      : _multiColumn = multiColumn,
        super(children: children, mainAxis: Axis.vertical);

  /// Whether children should be laid out as multiple columns or not.
  bool get multiColumn => _multiColumn;
  bool _multiColumn;
  set multiColumn(bool value) {
    if (_multiColumn != value) {
      _multiColumn = value;
      markNeedsLayout();
    }
  }

  @override
  void performLayout() {
    assert(!constraints.hasBoundedHeight);
    assert(constraints.hasBoundedWidth);

    if (_multiColumn) {
      _layoutMultiColumn();
    } else {
      _layoutSingleColumn();
    }

    size =
        constraints.constrain(new Size(constraints.maxWidth, _mainAxisExtent));

    assert(!size.isInfinite);
  }

  void _layoutMultiColumn() {
    BoxConstraints innerConstraints =
        new BoxConstraints(maxWidth: constraints.maxWidth);

    // Layout children.
    double leftHeight = 0.0;
    double rightHeight = _kRightBump;
    double leftMaxWidth = 0.0;
    double rightMaxWidth = 0.0;
    {
      bool left = true;
      RenderBox child = firstChild;
      while (child != null) {
        child.layout(innerConstraints, parentUsesSize: true);
        if (left) {
          leftHeight += child.size.height;
          leftMaxWidth = math.max(leftMaxWidth, child.size.width);
        } else {
          rightHeight += child.size.height;
          rightMaxWidth = math.max(rightMaxWidth, child.size.width);
        }
        left = !left;
        final BlockParentData childParentData = child.parentData;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }
    }
    double centerLine = constraints.maxWidth / 2.0;
    assert(leftMaxWidth <= centerLine || rightMaxWidth <= centerLine);
    if (leftMaxWidth > centerLine) {
      centerLine = leftMaxWidth;
    }
    if (rightMaxWidth > centerLine) {
      centerLine -= (rightMaxWidth - centerLine);
    }

    // Position children.
    {
      double height = math.max(leftHeight, rightHeight);
      bool left = true;
      double leftPosition = height;
      double rightPosition = height - _kRightBump;
      RenderBox child = firstChild;
      while (child != null) {
        final BlockParentData childParentData = child.parentData;
        if (left) {
          leftPosition -= child.size.height;
          childParentData.offset =
              new Offset(centerLine - child.size.width, leftPosition);
        } else {
          rightPosition -= child.size.height;
          childParentData.offset = new Offset(centerLine, rightPosition);
        }
        left = !left;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }
    }
  }

  void _layoutSingleColumn() {
    BoxConstraints innerConstraints =
        new BoxConstraints.tightFor(width: constraints.maxWidth);

    // Layout children.
    double height = 0.0;
    {
      RenderBox child = firstChild;
      while (child != null) {
        final BlockParentData childParentData = child.parentData;
        child.layout(innerConstraints, parentUsesSize: true);
        height += child.size.height;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }
    }

    // Position children.
    {
      double position = height;
      RenderBox child = firstChild;
      while (child != null) {
        final BlockParentData childParentData = child.parentData;
        position -= child.size.height;
        childParentData.offset = new Offset(0.0, position);
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }
    }
  }

  double get _mainAxisExtent {
    RenderBox child = firstChild;
    if (child == null) return 0.0;
    BoxParentData parentData = child.parentData;
    return parentData.offset.dy + child.size.height;
  }
}
