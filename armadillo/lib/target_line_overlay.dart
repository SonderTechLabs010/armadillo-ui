// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'line_segment.dart';

/// When [enabled] is true, this widget draws the given [targetLines]
/// that will accept [candidatePoints] overlaid on top of [child].  The
/// current [Point]s of the [candidatePoints] along with those of the
/// [closestTargetLockPoints] are also drawn on top of [child].
class TargetLineOverlay extends StatelessWidget {
  final Widget child;
  final List<LineSegment> targetLines;
  final List<Point> closestTargetLockPoints;
  final List<Point> candidatePoints;

  /// Set to true to draw target lines.
  final bool enabled;

  TargetLineOverlay({
    this.enabled,
    this.targetLines,
    this.closestTargetLockPoints,
    this.candidatePoints,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> stackChildren = <Widget>[new Positioned.fill(child: child)];

    // When we have a candidate, show the target lines.
    if (enabled && candidatePoints.isNotEmpty) {
      // Add all the lines.
      targetLines.forEach(
        (LineSegment line) => stackChildren.addAll(
              line.buildStackChildren(),
            ),
      );

      // Add candidate points
      stackChildren.addAll(
        candidatePoints.map(
          (Point point) => new Positioned(
                left: point.x - 5.0,
                top: point.y - 5.0,
                width: 10.0,
                height: 10.0,
                child: new Container(
                  decoration: new BoxDecoration(
                    backgroundColor: new Color(0xFFFFFF00),
                  ),
                ),
              ),
        ),
      );
      // Add candidate lockpoints
      stackChildren.addAll(
        closestTargetLockPoints.map(
          (Point point) => new Positioned(
                left: point.x - 5.0,
                top: point.y - 5.0,
                width: 10.0,
                height: 10.0,
                child: new Container(
                  decoration: new BoxDecoration(
                    backgroundColor: new Color(0xFFFF00FF),
                  ),
                ),
              ),
        ),
      );
    }
    return new Stack(children: stackChildren);
  }
}
