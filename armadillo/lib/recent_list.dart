// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'focusable_story.dart';

export 'focusable_story.dart' show Story, OnStoryFocused;

/// If the width of the [RecentList] exceeds this value it will switch to
/// multicolumn mode.
const double _kMultiColumnWidthThreshold = 600.0;

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

class RecentList extends StatefulWidget {
  final Key scrollableKey;
  final ScrollListener onScroll;
  final OnStoryFocused onStoryFocused;
  final EdgeInsets padding;
  final List<Story> stories;
  final Size parentSize;

  RecentList(
      {Key key,
      this.scrollableKey,
      this.padding,
      this.onScroll,
      this.onStoryFocused,
      this.parentSize,
      List<Story> stories: const <Story>[]})
      : this.stories = new List<Story>.from(stories),
        super(key: key) {
    // Sort recently interacted with stories to the start of the list.
    this.stories.sort((Story a, Story b) =>
        b.lastInteraction.millisecondsSinceEpoch -
        a.lastInteraction.millisecondsSinceEpoch);
  }

  @override
  RecentListState createState() => new RecentListState();
}

class RecentListState extends State<RecentList> {
  /// When true, list scrolling is disabled and vertical gestures will no longer
  /// be stolen by the [Scrollable] with the key [config.scrollableKey].
  /// This gets set to true when a [Story] comes into focus.
  bool _lockScrolling = false;

  @override
  Widget build(BuildContext context) {
    bool multiColumn = config.parentSize.width > _kMultiColumnWidthThreshold;
    return new ScrollConfiguration(
      delegate: new LockingScrollConfigurationDelegate(lock: _lockScrolling),
      child: new RecentListBlock(
        scrollableKey: config.scrollableKey,
        padding: config.padding,
        onScroll: config.onScroll,
        multiColumn: multiColumn,
        children: config.stories.map(
          (Story story) {
            final stackChildren = <Widget>[
              new FocusableStory(
                key: new GlobalObjectKey(story.id),
                fullSize: config.parentSize,
                story: story,
                onStoryFocused: config.onStoryFocused,
                multiColumn: multiColumn,
              ),
            ];
            if (!_lockScrolling) {
              stackChildren.add(
                new GestureDetector(
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
                    Point listTopLeft = listBox.localToGlobal(Point.origin);
                    RenderBox storyBox = new GlobalObjectKey(story.id)
                        .currentContext
                        .findRenderObject();
                    Point storyTopLeft = storyBox.localToGlobal(Point.origin);
                    double scrollDelta = (listBox.size.height + listTopLeft.y) -
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
                  },
                ),
              );
            }
            return new Stack(children: stackChildren);
          },
        ).toList(),
      ),
    );
  }

  void defocus() {
    // Unfocus all stories.
    config.stories.forEach((Story s) {
      FocusableStoryState untappedFocusableStoryState =
          new GlobalObjectKey(s.id).currentState;
      untappedFocusableStoryState.focused = false;
    });

    // Unlock scrolling.
    setState(() {
      _lockScrolling = false;
    });
  }
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

class RecentListBlock extends Block {
  final bool multiColumn;
  RecentListBlock(
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
        new RecentListBlockBody(multiColumn: multiColumn, children: children);
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

class RecentListBlockBody extends BlockBody {
  final bool multiColumn;
  RecentListBlockBody({Key key, this.multiColumn, List<Widget> children})
      : super(key: key, mainAxis: Axis.vertical, children: children);

  @override
  RecentListRenderBlock createRenderObject(BuildContext context) =>
      new RecentListRenderBlock(multiColumn: multiColumn);

  @override
  void updateRenderObject(
      BuildContext context, RecentListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
    renderObject.multiColumn = multiColumn;
  }
}

class RecentListRenderBlock extends RenderBlock {
  RecentListRenderBlock({List<RenderBox> children, bool multiColumn})
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
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);

    // Layout children.
    double leftHeight = 0.0;
    double rightHeight = _kRightBump;
    double leftMaxWidth = 0.0;
    double rightMaxWidth = 0.0;
    {
      bool left = true;
      RenderBox child = firstChild;
      while (child != null) {
        child.layout(
            new BoxConstraints.tightFor(
                width: child.getMaxIntrinsicWidth(0.0),
                height: child.getMaxIntrinsicHeight(0.0)),
            parentUsesSize: true);
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
    double centerLine = innerConstraints.maxWidth;
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
    // Layout children.
    double height = 0.0;
    {
      RenderBox child = firstChild;
      while (child != null) {
        final BlockParentData childParentData = child.parentData;
        child.layout(
            new BoxConstraints.tightFor(
                height: child.getMaxIntrinsicHeight(0.0),
                width: child.getMaxIntrinsicWidth(0.0)),
            parentUsesSize: true);
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

  BoxConstraints _getInnerConstraints(BoxConstraints constraints) {
    return _multiColumn
        ? new BoxConstraints(maxWidth: constraints.maxWidth / 2.0)
        : new BoxConstraints.tightFor(width: constraints.maxWidth);
  }

  double get _mainAxisExtent {
    RenderBox child = firstChild;
    if (child == null) return 0.0;
    BoxParentData parentData = child.parentData;
    return parentData.offset.dy + child.size.height;
  }
}
