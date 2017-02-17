// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'line_segment.dart';
import 'story_cluster.dart';

const double _kStepSize = 5.0;

/// When [enabled] is true, this widget draws the influence of the given
/// [targetLines] by drawing a bunch of points that will accept
/// [storyClusterCandidates] overlaid on top of [child].
class TargetLineInfluenceOverlay extends StatelessWidget {
  final Widget child;
  final Set<LineSegment> targetLines;
  final Map<StoryCluster, Point> storyClusterCandidates;

  /// Set to true to draw influence.
  final bool enabled;

  TargetLineInfluenceOverlay({
    this.enabled,
    this.targetLines,
    this.storyClusterCandidates,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = <Widget>[new Positioned.fill(child: child)];

    // When we have a candidate, show the target lines.
    if (enabled && storyClusterCandidates.isNotEmpty) {
      // Add all the lines.
      List<LineSegment> validTargetLines = targetLines
          .where(
            (LineSegment line) => !storyClusterCandidates.keys.every(
                  (StoryCluster key) => !line.canAccept(key),
                ),
          )
          .toList();
      stackChildren.add(
        new Positioned.fill(
          child: new RepaintBoundary(
            child: new CustomPaint(
              painter: new InfluencePainter(
                lines: validTargetLines,
              ),
            ),
          ),
        ),
      );
    }
    return new Stack(children: stackChildren);
  }
}

class InfluencePainter extends CustomPainter {
  final List<LineSegment> lines;

  InfluencePainter({this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    int xSteps = (size.width / _kStepSize).round();
    int ySteps = (size.height / _kStepSize).round();
    List<List<LineSegment>> lines = new List<List<LineSegment>>.generate(
      xSteps,
      (int xStep) => new List<LineSegment>.generate(
            ySteps,
            (int yStep) => _getClosestLine(
                  new Point((xStep + 1) * _kStepSize, (yStep + 1) * _kStepSize),
                ),
          ),
    );
    for (int i = 0; i < xSteps; i++) {
      for (int j = 0; j < ySteps; j++) {
        double leftShift =
            i > 0 && lines[i][j] != lines[i - 1][j] ? _kStepSize / 4.0 : 0.0;
        double rightShift = (i < (xSteps - 1)) && lines[i][j] != lines[i + 1][j]
            ? -_kStepSize / 4.0
            : 0.0;
        double topShift =
            j > 0 && lines[i][j] != lines[i][j - 1] ? _kStepSize / 4.0 : 0.0;
        double bottomShift =
            (j < (ySteps - 1)) && lines[i][j] != lines[i][j + 1]
                ? -_kStepSize / 4.0
                : 0.0;
        canvas.drawOval(
          new Rect.fromLTRB(
            ((i + 1) * _kStepSize) - _kStepSize / 2.0 + leftShift,
            ((j + 1) * _kStepSize) - _kStepSize / 2.0 + topShift,
            ((i + 1) * _kStepSize) + _kStepSize / 2.0 + rightShift,
            ((j + 1) * _kStepSize) + _kStepSize / 2.0 + bottomShift,
          ),
          new Paint()..color = lines[i][j]?.color ?? new Color(0x00000000),
        );
      }
    }
  }

  @override
  bool shouldRepaint(InfluencePainter oldDelegate) {
    if (oldDelegate.lines.length != lines.length) {
      return true;
    }
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].color != oldDelegate.lines[i].color) {
        return true;
      }
      if (lines[i].a != oldDelegate.lines[i].a) {
        return true;
      }
      if (lines[i].b != oldDelegate.lines[i].b) {
        return true;
      }
    }

    return false;
  }

  @override
  bool hitTest(Point position) => false;

  LineSegment _getClosestLine(Point point) {
    LineSegment closestLine;
    double minDistance = double.INFINITY;
    lines
        .where((LineSegment line) =>
            line.distanceFrom(point) < line.validityDistance)
        .forEach((LineSegment line) {
      double targetLineDistance = line.distanceFrom(point);
      if (targetLineDistance < minDistance) {
        minDistance = targetLineDistance;
        closestLine = line;
      }
    });
    return closestLine;
  }
}
