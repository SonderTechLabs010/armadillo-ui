// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'story.dart';
import 'story_list_layout.dart';
import 'story_list_render_block_parent_data.dart';

const double _kStoryInlineTitleHeight = 20.0;

/// Overrides [RenderBlock]'s layout, paint, and hit-test behaviour to allow
/// the following:
///   1) Stories are laid out as specified by [StoryListLayout].
///   2) A story expands as it comes into focus and shrinks when it leaves
///      focus.
///   3) Focused stories are above and overlap non-focused stories.
class StoryListRenderBlock extends RenderBlock {
  StoryListRenderBlock({
    List<RenderBox> children,
    Size parentSize,
    double scrollOffset,
    double bottomPadding,
  })
      : _parentSize = parentSize,
        _scrollOffset = scrollOffset,
        _bottomPadding = bottomPadding,
        super(children: children, mainAxis: Axis.vertical);

  Size get parentSize => _parentSize;
  Size _parentSize;
  set parentSize(Size value) {
    if (_parentSize != value) {
      _parentSize = value;
      markNeedsLayout();
    }
  }

  double get scrollOffset => _scrollOffset;
  double _scrollOffset;
  set scrollOffset(double value) {
    if (_scrollOffset != value) {
      _scrollOffset = value;
      markNeedsLayout();
    }
  }

  double get bottomPadding => _bottomPadding;
  double _bottomPadding;
  set bottomPadding(double value) {
    if (_bottomPadding != value) {
      _bottomPadding = value;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! StoryListRenderBlockParentData) {
      child.parentData = new StoryListRenderBlockParentData(this);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _childrenSortedByFocusProgress.forEach((RenderBox child) {
      final BlockParentData childParentData = child.parentData;
      context.paintChild(child, childParentData.offset + offset);
    });
  }

  @override
  bool hitTestChildren(HitTestResult result, {Point position}) {
    final List<RenderBox> children =
        _childrenSortedByFocusProgress.reversed.toList();
    for (int i = 0; i < children.length; i++) {
      final RenderBox child = children[i];
      final StoryListRenderBlockParentData childParentData = child.parentData;
      Point transformed = new Point(position.x - childParentData.offset.dx,
          position.y - childParentData.offset.dy);
      if (child.hitTest(result, position: transformed)) {
        return true;
      }
    }
    return false;
  }

  @override
  void performLayout() {
    assert(!constraints.hasBoundedHeight);
    assert(constraints.hasBoundedWidth);

    StoryListLayout layout = new StoryListLayout(size: parentSize);

    List<StoryLayout> storyLayout = layout.layout(
      storiesToLayout: _stories,
      currentTime: new DateTime.now(),
    );

    double listHeight = 0.0;
    storyLayout.forEach((StoryLayout storyLayout) {
      listHeight = math.max(listHeight, -storyLayout.offset.dy);
    });

    {
      RenderBox child = firstChild;
      storyLayout.forEach((StoryLayout storyLayout) {
        final StoryListRenderBlockParentData childParentData = child.parentData;
        // Layout the child.
        double childHeight = _lerp(
          storyLayout.size.height +
              _lerp(
                _kStoryInlineTitleHeight,
                0.0,
                childParentData.focusProgress,
              ),
          parentSize.height,
          childParentData.focusProgress,
        );
        child.layout(
          new BoxConstraints.tightFor(
            width: _lerp(
              storyLayout.size.width,
              parentSize.width,
              childParentData.focusProgress,
            ),
            height: childHeight,
          ),
          parentUsesSize: false,
        );
        // Position the child.
        childParentData.offset = new Offset(
          _lerp(
            storyLayout.offset.dx + constraints.maxWidth / 2.0,
            0.0,
            childParentData.focusProgress,
          ),
          _lerp(
            storyLayout.offset.dy + listHeight,
            listHeight - parentSize.height - _scrollOffset + _bottomPadding,
            childParentData.focusProgress,
          ),
        );
        child = childParentData.nextSibling;
      });
    }

    size = constraints.constrain(
      new Size(
        constraints.maxWidth,
        listHeight + _bottomPadding,
      ),
    );

    assert(!size.isInfinite);
  }

  List<RenderBox> get _childrenSortedByFocusProgress {
    final List<RenderBox> children = [];
    RenderBox child = firstChild;
    while (child != null) {
      final BlockParentData childParentData = child.parentData;
      children.add(child);
      child = childParentData.nextSibling;
    }

    children.sort((RenderBox child1, RenderBox child2) {
      final StoryListRenderBlockParentData child1ParentData = child1.parentData;
      final StoryListRenderBlockParentData child2ParentData = child2.parentData;
      return child1ParentData.focusProgress > child2ParentData.focusProgress
          ? 1
          : child1ParentData.focusProgress < child2ParentData.focusProgress
              ? -1
              : 0;
    });
    return children;
  }

  List<Story> get _stories {
    final List<Story> stories = <Story>[];
    {
      RenderBox child = firstChild;
      while (child != null) {
        final StoryListRenderBlockParentData childParentData = child.parentData;
        assert(childParentData.story != null);
        stories.add(childParentData.story);
        child = childParentData.nextSibling;
      }
    }
    return stories;
  }

  double _lerp(double a, double b, double t) {
    return (1.0 - t) * a + t * b;
  }
}
