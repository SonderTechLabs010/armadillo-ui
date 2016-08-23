// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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

class RecentList extends StatelessWidget {
  final Key scrollableKey;
  final ScrollListener onScroll;
  final EdgeInsets padding;

  RecentList({Key key, this.scrollableKey, this.padding, this.onScroll})
      : super(key: key);

  @override
  Widget build(BuildContext context) => new RecentListBlock(
      scrollableKey: scrollableKey,
      padding: padding,
      scrollAnchor: ViewportAnchor.end,
      onScroll: onScroll,
      children: _kDummyRecentColors.reversed
          .map((int color) => new Container(
              margin:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              // 'Randomize' heights a bit.
              height: 200.0 + (color % 201).toDouble(),
              decoration: new BoxDecoration(
                  backgroundColor: new Color(color),
                  borderRadius: new BorderRadius.circular(4.0))))
          .toList());
}

class RecentListBlock extends Block {
  RecentListBlock(
      {Key key,
      List<Widget> children,
      EdgeInsets padding,
      ViewportAnchor scrollAnchor,
      ScrollListener onScroll,
      Key scrollableKey})
      : super(
            key: key,
            children: children,
            padding: padding,
            scrollAnchor: scrollAnchor,
            onScroll: onScroll,
            scrollableKey: scrollableKey) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  @override
  Widget build(BuildContext context) {
    Widget contents =
        new RecentListBlockBody(children: children, mainAxis: scrollDirection);
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
  RecentListBlockBody({Key key, Axis mainAxis, List<Widget> children})
      : super(key: key, mainAxis: mainAxis, children: children) {
    assert(mainAxis != null);
  }

  @override
  RecentListRenderBlock createRenderObject(BuildContext context) =>
      new RecentListRenderBlock(mainAxis: mainAxis);

  @override
  void updateRenderObject(
      BuildContext context, RecentListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
  }
}

class RecentListRenderBlock extends RenderBlock {
  RecentListRenderBlock({List<RenderBox> children, Axis mainAxis})
      : super(children: children, mainAxis: mainAxis);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! RecentListBlockParentData)
      child.parentData = new RecentListBlockParentData();
  }
}

class RecentListBlockParentData extends BlockParentData {}
