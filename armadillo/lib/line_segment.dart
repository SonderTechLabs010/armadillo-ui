// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'panel_drag_targets.dart';
import 'story_cluster.dart';

const double _kLineWidth = 4.0;

typedef void OnPanelEvent(BuildContext context, StoryCluster storyCluster);

/// Details about a target used by [PanelDragTargets].
///
/// [LineSegment] specifies a line from [a] to [b].
/// When turned into a widget the [LineSegment] will have the color [color].
/// When the [LineSegment] is being targeted by a draggable [onHover] will be
/// called.
/// When the [LineSegment] is dropped upon with a draggable [onDrop] will be
/// called.
/// This [LineSegment] can only be targeted by [StoryCluster]s with a story
/// count of less than or equal to [maxStoriesCanAccept].
class LineSegment {
  /// [a] always aligns with [b] in either vertically or horizontally.
  /// [a] is always 'less than' [b] in x or y direction.
  final Point a;
  final Point b;
  final Color color;
  final OnPanelEvent onHover;
  final OnPanelEvent onDrop;
  final int maxStoriesCanAccept;
  final String name;
  final bool initiallyTargetable;

  LineSegment(
    Point a,
    Point b, {
    this.color: const Color(0xFFFFFFFF),
    this.onHover,
    this.onDrop,
    this.maxStoriesCanAccept: 1,
    this.name,
    this.initiallyTargetable: true,
  })
      : this.a = (a.x < b.x || a.y < b.y) ? a : b,
        this.b = (a.x < b.x || a.y < b.y) ? b : a {
    // Ensure the line is either vertical or horizontal.
    assert(a.x == b.x || a.y == b.y);
  }

  factory LineSegment.vertical({
    double x,
    double top,
    double bottom,
    Color color,
    OnPanelEvent onHover,
    OnPanelEvent onDrop,
    int maxStoriesCanAccept,
    String name,
    bool initiallyTargetable: true,
  }) =>
      new LineSegment(
        new Point(x, top),
        new Point(x, bottom),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
        name: name,
        initiallyTargetable: initiallyTargetable,
      );

  factory LineSegment.horizontal({
    double y,
    double left,
    double right,
    Color color,
    OnPanelEvent onHover,
    OnPanelEvent onDrop,
    int maxStoriesCanAccept,
    String name,
    bool initiallyTargetable: true,
  }) =>
      new LineSegment(
        new Point(left, y),
        new Point(right, y),
        color: color,
        onHover: onHover,
        onDrop: onDrop,
        maxStoriesCanAccept: maxStoriesCanAccept,
        name: name,
        initiallyTargetable: initiallyTargetable,
      );

  bool get isHorizontal => a.y == b.y;
  bool get isVertical => !isHorizontal;
  bool canAccept(StoryCluster storyCluster) =>
      storyCluster.realStories.length <= maxStoriesCanAccept;

  double distanceFrom(Point p) {
    if (isHorizontal) {
      if (p.x < a.x) {
        return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2));
      } else if (p.x > b.x) {
        return math.sqrt(math.pow(p.x - b.x, 2) + math.pow(p.y - b.y, 2));
      } else {
        return (p.y - a.y).abs();
      }
    } else {
      if (p.y < a.y) {
        return math.sqrt(math.pow(p.x - a.x, 2) + math.pow(p.y - a.y, 2));
      } else if (p.y > b.y) {
        return math.sqrt(math.pow(p.x - b.x, 2) + math.pow(p.y - b.y, 2));
      } else {
        return (p.x - a.x).abs();
      }
    }
  }

  Positioned buildStackChild({bool highlighted: false}) => new Positioned(
        left: a.x - _kLineWidth / 2.0,
        top: a.y - _kLineWidth / 2.0,
        width: isHorizontal ? b.x - a.x + _kLineWidth : _kLineWidth,
        height: isVertical ? b.y - a.y + _kLineWidth : _kLineWidth,
        child: new Container(
          decoration: new BoxDecoration(
            backgroundColor: color.withOpacity(highlighted ? 1.0 : 0.3),
          ),
        ),
      );

  @override
  String toString() =>
      'LineSegment(a: $a, b: $b, color: $color, maxStoriesCanAccept: $maxStoriesCanAccept)';
}
