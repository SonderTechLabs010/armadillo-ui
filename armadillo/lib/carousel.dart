// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const _kDuration = const Duration(milliseconds: 200);
const _kCurve = Curves.ease;

/// A horizontally-scrolling widget centering one of its children.
///
/// Similar to [PageableList] except that it can display more than one child at
/// a time.
class Carousel extends Scrollable {
  /// The widgets to scroll through.
  final List<Widget> children;

  /// Width of each child.
  final double itemExtent;

  /// Called when the carousel settles on a child.
  final ValueChanged<int> onItemChanged;

  /// Called when the child the carousel settled on was tapped.
  final ValueChanged<int> onItemSelected;

  /// If true, disables scrolling.
  final bool locked;

  Carousel(
      {Key key,
      this.children,
      this.itemExtent,
      this.onItemChanged,
      this.onItemSelected,
      this.locked})
      : super(key: key, scrollDirection: Axis.horizontal) {
    assert(children != null);
    assert(itemExtent != null);
  }

  @override
  CarouselState createState() => new CarouselState();
}

/// State for a [Carousel] widget.
class CarouselState extends ScrollableState<Carousel> {
  ExtentScrollBehavior _scrollBehavior;

  @override
  initState() {
    super.initState();
    _updateScrollBehavior();
  }

  @override
  void didUpdateConfig(Carousel oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.children.length != oldConfig.children.length) {
      _updateScrollBehavior();
    }
  }

  @override
  Widget buildContent(BuildContext context) => new CustomMultiChildLayout(
      delegate: new CarouselLayoutDelegate(
          config.children, config.itemExtent, _pixelOffset),
      children: new List<Widget>.generate(
          config.children.length, (index) => _createChildWrapper(index)));

  /// Generates a wrapper widget for the child at [index].
  Widget _createChildWrapper(int index) {
    return new LayoutId(
        id: index,
        child: new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _notifyItemSelected(index),
            child: config.children[index]));
  }

  _updateScrollBehavior() {
    if (config.locked) {
      _scrollBehavior = new LockedUnboundedBehavior(
        platform: defaultTargetPlatform,
      );
    } else {
      _scrollBehavior = new OverscrollBehavior(
        platform: defaultTargetPlatform,
      );
    }
    didUpdateScrollBehavior(scrollBehavior.updateExtents(
        contentExtent: config.children.length.toDouble(),
        containerExtent: 1.0,
        scrollOffset: scrollOffset));
  }

  @override
  ScrollBehavior<double, double> createScrollBehavior() {
    return _scrollBehavior;
  }

  @override
  ExtentScrollBehavior get scrollBehavior {
    if (_scrollBehavior == null) {
      if (config.locked) {
        _scrollBehavior = new LockedUnboundedBehavior(
          platform: defaultTargetPlatform,
        );
      } else {
        _scrollBehavior = new OverscrollBehavior(
          platform: defaultTargetPlatform,
        );
      }
    }
    return _scrollBehavior;
  }

  /// The number of actual pixels scrolled by unit of scroll offset.
  double get _pixelsPerScrollUnit {
    return config.itemExtent;
  }

  @override
  double pixelOffsetToScrollOffset(double pixelOffset) {
    final pixelsPerScrollUnit = _pixelsPerScrollUnit;
    return super.pixelOffsetToScrollOffset(
        pixelsPerScrollUnit == 0.0 ? 0.0 : pixelOffset / pixelsPerScrollUnit);
  }

  @override
  double scrollOffsetToPixelOffset(double scrollOffset) {
    return super.scrollOffsetToPixelOffset(scrollOffset * _pixelsPerScrollUnit);
  }

  /// The scroll offset expressed in pixels.
  double get _pixelOffset => scrollOffsetToPixelOffset(scrollOffset);

  @override
  bool get shouldSnapScrollOffset => true;

  @override
  Future<Null> fling(double scrollVelocity) {
    // Snap to the closest item.
    final double newScrollOffset =
        snapScrollOffset(scrollOffset + scrollVelocity.sign).clamp(
            snapScrollOffset(scrollOffset - 0.5),
            snapScrollOffset(scrollOffset + 0.5));
    return scrollTo(newScrollOffset, duration: _kDuration, curve: _kCurve)
        .then(_notifyItemChanged);
  }

  @override
  double snapScrollOffset(double newScrollOffset) {
    final double previousItemOffset = newScrollOffset.floorToDouble();
    final double nextItemOffset = newScrollOffset.ceilToDouble();
    return (newScrollOffset - previousItemOffset < 0.5
            ? previousItemOffset
            : nextItemOffset)
        .clamp(scrollBehavior.minScrollOffset, scrollBehavior.maxScrollOffset);
  }

  @override
  Future<Null> settleScrollOffset() {
    return scrollTo(snapScrollOffset(scrollOffset),
            duration: _kDuration, curve: _kCurve)
        .then(_notifyItemChanged);
  }

  /// The index of the currently-centered page.
  ///
  /// Not very useful if there's an active scrolling session.
  int get _pageIndex {
    final size = config.children.length;
    if (size == 0) {
      return 0;
    }
    return scrollOffset.floor() % size;
  }

  _notifyItemChanged(_) {
    if (config.onItemChanged != null) {
      config.onItemChanged(_pageIndex);
    }
  }

  _notifyItemSelected(int index) {
    if (config.onItemSelected != null && index == _pageIndex) {
      config.onItemSelected(index);
    }
  }
}

/// Places the children of a [Carousel].
///
/// The index of each child in the list is used as the child's id.
class CarouselLayoutDelegate extends MultiChildLayoutDelegate {
  /// The widgets to lay out.
  final List<Widget> _items;

  /// Current scroll offset.
  final double _scrollOffset;

  /// The width of each child.
  final double _itemExtent;

  CarouselLayoutDelegate(this._items, this._itemExtent, this._scrollOffset);

  @override
  performLayout(Size size) {
    final centerOffset = (size.width - _itemExtent) / 2;
    for (int index = 0; index < _items.length; index++) {
      final id = index;
      layoutChild(
          id, new BoxConstraints.tight(new Size(_itemExtent, size.height)));
      positionChild(id,
          new Offset(centerOffset + index * _itemExtent + _scrollOffset, 0.0));
    }
  }

  @override
  bool shouldRelayout(CarouselLayoutDelegate oldDelegate) {
    if (_items.length != oldDelegate._items.length) {
      return true;
    }
    for (int i = 0; i < _items.length; i++) {
      if (_items[i] != oldDelegate._items[i]) {
        return true;
      }
    }
    return _scrollOffset != oldDelegate._scrollOffset ||
        _itemExtent != oldDelegate._itemExtent;
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
