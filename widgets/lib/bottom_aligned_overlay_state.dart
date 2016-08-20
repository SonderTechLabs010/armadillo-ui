// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'ticking_height_state.dart';

/// A [TickingHeightState] that changes its height to [minHeight] via [hide] and\
/// [maxHeight] via [show].
///
/// As the [height] increases above [minHeight] the [Widget] returned by
/// [createWidget] will grow up from the bottom.  The area not given to that
/// [Widget] will gradually darken until a [height] of
/// [darkeningBackgroundMaxHeight] is reached.
///
/// The [createWidget] [Widget] will be clipped to [height] but will be given
/// [maxHeight] to be laid out in.
abstract class BottomAlignedOverlayState<T extends StatefulWidget>
    extends TickingHeightState<T> {
  static final double kSnapVelocityThreshold = 500.0;
  final double darkeningBackgroundMinHeight;
  final double darkeningBackgroundMaxHeight;
  double parentHeight;

  BottomAlignedOverlayState(
      {this.darkeningBackgroundMinHeight, this.darkeningBackgroundMaxHeight});

  Widget createWidget(BuildContext context);

  void hide() {
    setHeight(minHeight);
  }

  void show() {
    setHeight(maxHeight);
  }

  void toggle() => (active) ? hide() : show();

  void snap(double verticalVelocity) {
    if (verticalVelocity < -kSnapVelocityThreshold) {
      show();
    } else if (verticalVelocity > kSnapVelocityThreshold) {
      hide();
    } else if (height - minHeight < maxHeight - height) {
      hide();
    } else {
      show();
    }
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        parentHeight = constraints.maxHeight;
        final stackChildren = <Widget>[
          new Align(
              alignment: FractionalOffset.bottomCenter,
              child: new ClipRect(
                  child: new ConstrainedBox(
                      constraints: new BoxConstraints(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          minHeight: height,
                          maxHeight: height),
                      child: new OverflowBox(
                          minWidth: constraints.maxWidth,
                          maxWidth: constraints.maxWidth,
                          minHeight: math.max(height, maxHeight),
                          maxHeight: math.max(height, maxHeight),
                          alignment: FractionalOffset.topCenter,
                          child: createWidget(context)))))
        ];

        if (active) {
          stackChildren.insert(
              0,
              new GestureDetector(
                  onTap: () => setHeight(minHeight),
                  onVerticalDragUpdate: (DragUpdateDetails details) =>
                      setHeight(height - details.primaryDelta, force: true),
                  onVerticalDragEnd: (DragEndDetails details) =>
                      snap(details.velocity.pixelsPerSecond.dy),
                  behavior: HitTestBehavior.opaque,
                  child: new Container(
                      decoration: new BoxDecoration(
                          backgroundColor: new Color(
                              ((0xD9 * openingProgress).round() << 24) +
                                  0x00000000)))));
        }
        return new Stack(children: stackChildren);
      });

  double get openingProgress => (height > darkeningBackgroundMinHeight
      ? math.min(
          1.0,
          (height - darkeningBackgroundMinHeight) /
              (darkeningBackgroundMaxHeight - darkeningBackgroundMinHeight))
      : 0.0);
  bool get active => height > darkeningBackgroundMinHeight;
}
