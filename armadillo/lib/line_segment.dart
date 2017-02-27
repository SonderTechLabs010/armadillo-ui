// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart' as material;
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
  final bool directionallyTargetable;

  /// A [LineSegment] is considered a valid target for accepting stories if
  /// the [distanceFrom] [Point] of the stories in question is within the
  /// [validityDistance] of this [LineSegment].
  final double validityDistance;

  LineSegment(
    Point a,
    Point b, {
    this.color: material.Colors.white,
    this.onHover,
    this.onDrop,
    this.maxStoriesCanAccept: 1,
    this.name,
    this.initiallyTargetable: true,
    this.directionallyTargetable: false,
    this.validityDistance: double.INFINITY,
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
    Color color: material.Colors.white,
    OnPanelEvent onHover,
    OnPanelEvent onDrop,
    int maxStoriesCanAccept: 1,
    String name,
    bool initiallyTargetable: true,
    bool directionallyTargetable: false,
    double validityDistance: double.INFINITY,
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
        directionallyTargetable: directionallyTargetable,
        validityDistance: validityDistance,
      );

  factory LineSegment.horizontal({
    double y,
    double left,
    double right,
    Color color: material.Colors.white,
    OnPanelEvent onHover,
    OnPanelEvent onDrop,
    int maxStoriesCanAccept: 1,
    String name,
    bool initiallyTargetable: true,
    bool directionallyTargetable: false,
    double validityDistance: double.INFINITY,
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
        directionallyTargetable: directionallyTargetable,
        validityDistance: validityDistance,
      );

  bool get isHorizontal => a.y == b.y;
  bool get isVertical => !isHorizontal;
  bool canAccept(StoryCluster storyCluster) =>
      storyCluster.realStories.length <= maxStoriesCanAccept;

  bool isInDirectionFromPoint(DragDirection dragDirection, Point point) {
    if (!directionallyTargetable) {
      return true;
    }
    switch (dragDirection) {
      case DragDirection.left:
        if (isHorizontal) {
          return false;
        } else if (a.x > point.x) {
          return false;
        }
        break;
      case DragDirection.right:
        if (isHorizontal) {
          return false;
        } else if (a.x < point.x) {
          return false;
        }
        break;
      case DragDirection.up:
        if (isVertical) {
          return false;
        } else if (a.y > point.y) {
          return false;
        }
        break;
      case DragDirection.down:
        if (isVertical) {
          return false;
        } else if (a.y < point.y) {
          return false;
        }
        break;
      case DragDirection.none:
      default:
        break;
    }
    return true;
  }

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

  List<Positioned> buildStackChildren({bool highlighted: false}) =>
      validityDistance != double.INFINITY
          ? <Positioned>[
              _buildValidityDistanceWidget(highlighted: highlighted),
              _buildLineWidget(highlighted: highlighted),
            ]
          : <Positioned>[
              _buildLineWidget(highlighted: highlighted),
            ];

  Positioned _buildLineWidget({bool highlighted: false}) => new Positioned(
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

  Positioned _buildValidityDistanceWidget({bool highlighted: false}) =>
      new Positioned(
        left: a.x - _kLineWidth / 2.0 - validityDistance,
        top: a.y - _kLineWidth / 2.0 - validityDistance,
        width: (isHorizontal ? b.x - a.x + _kLineWidth : _kLineWidth) +
            2 * validityDistance,
        height: (isVertical ? b.y - a.y + _kLineWidth : _kLineWidth) +
            2 * validityDistance,
        child: new Container(
          decoration: new BoxDecoration(
            backgroundColor: color.withOpacity(highlighted ? 0.3 : 0.1),
          ),
        ),
      );

  @override
  String toString() =>
      'LineSegment(a: $a, b: $b, color: $color, maxStoriesCanAccept: $maxStoriesCanAccept)';
}
