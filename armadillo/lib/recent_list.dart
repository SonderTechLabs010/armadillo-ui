// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Colors for dummy recents.
const _kDummyRecentColors = const <int>[
  0xFFFF5722,
  0xFFFF9800,
  0xFFFFC107,
  0xFFFFEB3B,
  0xFFCDDC39,
  0xFF8BC34A,
  0xFF4CAF50,
  0xFF009688,
  0xFF00BCD4,
  0xFF03A9F4,
  0xFF2196F3,
  0xFF3F51B5,
  0xFF673AB7,
  0xFF9C27B0,
  0xFFE91E63,
  0xFFF44336
];

/// The minimum story height.
const double _kMinimumStoryHeight = 200.0;

/// The representation fo a Story.  A Story's contents are display as a [Widget]
/// provided by [builder] while the size of a story in the [RecentList] is
/// determined by [lastInteraction] and [cumulativeInteractionDuration].
class Story {
  final WidgetBuilder builder;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;

  Story(
      {this.builder, this.lastInteraction, this.cumulativeInteractionDuration});

  /// A [Story] is bigger if it has been used often and recently.
  double get height {
    double sizeRatio =
        1.0 + (_culmulativeInteractionDurationRatio * _lastInteractionRatio);
    return _kMinimumStoryHeight * sizeRatio;
  }

  double get _culmulativeInteractionDurationRatio =>
      cumulativeInteractionDuration.inMinutes.toDouble() / 60.0;

  double get _lastInteractionRatio =>
      1.0 -
      math.min(
          1.0,
          new DateTime.now().difference(lastInteraction).inMinutes.toDouble() /
              60.0);
}

/// If the width of the [RecentList] exceeds this value it will switch to
/// multicolumn mode.
const double _kMultiColumnWidthThreshold = 600.0;

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

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

class RecentList extends StatelessWidget {
  static final _kDummyStories = _kDummyRecentColors
      .map((int color) => new Story(
          builder: (_) => new Container(
              decoration: new BoxDecoration(backgroundColor: new Color(color))),
          lastInteraction: new DateTime.now()
              .subtract(new Duration(minutes: new math.Random().nextInt(120))),
          cumulativeInteractionDuration:
              new Duration(minutes: new math.Random().nextInt(60))))
      .toList();
  final Key scrollableKey;
  final ScrollListener onScroll;
  final EdgeInsets padding;
  final List<Story> _stories;

  RecentList(
      {Key key,
      this.scrollableKey,
      this.padding,
      this.onScroll,
      List<Story> stories: const <Story>[]})
      : _stories = new List.from(stories),
        super(key: key) {
    // Sort recently interacted with stories to the start of the list.
    _stories.sort((Story a, Story b) =>
        b.lastInteraction.millisecondsSinceEpoch -
        a.lastInteraction.millisecondsSinceEpoch);
  }

  factory RecentList.dummyList(
      {Key key,
      Key scrollableKey,
      EdgeInsets padding,
      ScrollListener onScroll}) {
    return new RecentList(
        key: key,
        scrollableKey: scrollableKey,
        padding: padding,
        onScroll: onScroll,
        stories: _kDummyStories);
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        bool multiColumn = constraints.maxWidth > _kMultiColumnWidthThreshold;
        return new RecentListBlock(
            scrollableKey: scrollableKey,
            padding: padding,
            onScroll: onScroll,
            multiColumn: multiColumn,
            children: _stories.map((Story story) {
              return new Container(
                  height: story.height,
                  width:
                      multiColumn ? story.height * _kWidthToHeightRatio : 0.0,
                  child: new ClipRRect(
                      borderRadius: new BorderRadius.circular(4.0),
                      child: story.builder(context)));
            }).toList());
      });
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
  void setupParentData(RenderBox child) {
    if (child.parentData is! RecentListBlockParentData) {
      child.parentData = new RecentListBlockParentData();
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

    // Find tallest child's height.
    double tallestHeight = 0.0;
    {
      RenderBox child = firstChild;
      while (child != null) {
        tallestHeight =
            math.max(tallestHeight, child.getMaxIntrinsicHeight(0.0));
        final BlockParentData childParentData = child.parentData;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }
    }
    double sizeMultiplier = (innerConstraints.maxWidth - _kMultiColumnMargin) /
        (tallestHeight * _kWidthToHeightRatio);

    // Layout children.
    double leftHeight = 0.0;
    double rightHeight = _kRightBump;
    {
      bool left = true;
      RenderBox child = firstChild;
      while (child != null) {
        child.layout(
            new BoxConstraints.tightFor(
                width: child.getMaxIntrinsicWidth(0.0) * sizeMultiplier,
                height: child.getMaxIntrinsicHeight(0.0) * sizeMultiplier),
            parentUsesSize: true);
        if (left) {
          leftHeight += child.size.height;
        } else {
          rightHeight += child.size.height;
        }
        left = !left;
        final BlockParentData childParentData = child.parentData;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }
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
        final double marginDelta = _kMultiColumnMinimumStoryMargin *
            (1.0 +
                2.0 *
                    (child.size.height / sizeMultiplier / _kMinimumStoryHeight -
                        1.0));
        if (left) {
          leftPosition -= child.size.height;
          childParentData.offset = new Offset(
              innerConstraints.maxWidth -
                  child.size.width -
                  _kMultiColumnMinimumStoryMargin / 2.0,
              leftPosition);
          leftPosition -= marginDelta;
        } else {
          rightPosition -= child.size.height;
          childParentData.offset = new Offset(
              innerConstraints.maxWidth + _kMultiColumnMinimumStoryMargin / 2.0,
              rightPosition);
          rightPosition -= marginDelta;
        }
        left = !left;
        assert(child.parentData == childParentData);
        child = childParentData.nextSibling;
      }
    }
  }

  void _layoutSingleColumn() {
    BoxConstraints innerConstraints = _getInnerConstraints(constraints);

    // Layout children.
    double height = 0.0;
    {
      RenderBox child = firstChild;
      while (child != null) {
        child.layout(
            innerConstraints.deflate(const EdgeInsets.symmetric(
                horizontal: _kSingleColumnStoryMargin)),
            parentUsesSize: true);
        height += child.size.height;
        final BlockParentData childParentData = child.parentData;
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
        childParentData.offset =
            new Offset(_kSingleColumnStoryMargin, position);
        position -= _kSingleColumnStoryMargin;
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

class RecentListBlockParentData extends BlockParentData {}
