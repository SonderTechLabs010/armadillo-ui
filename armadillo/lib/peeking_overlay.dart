// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/bottom_aligned_overlay_state.dart';
import 'package:sysui_widgets/quadrilateral_painter.dart';

const double _kStartOverlayTransitionHeight = 28.0;

/// The distance the top right corner is inset when peeking.  When hiding, the
/// top left corner will inset the same distance as the overlay becomes
/// fully hidden.
const double _kAngleOffsetY = 16.0;

/// A bottom aligned overlay which peeks up over the bottom.
class PeekingOverlay extends StatefulWidget {
  final double peekHeight;
  final Widget child;
  final VoidCallback onHide;
  PeekingOverlay(
      {Key key,
      this.peekHeight: _kStartOverlayTransitionHeight,
      this.onHide,
      this.child})
      : super(key: key);

  @override
  PeekingOverlayState createState() =>
      new PeekingOverlayState(darkeningBackgroundMinHeight: peekHeight);
}

class PeekingOverlayState extends BottomAlignedOverlayState<PeekingOverlay> {
  bool _peeking;

  PeekingOverlayState({double darkeningBackgroundMinHeight})
      : super(darkeningBackgroundMinHeight: darkeningBackgroundMinHeight);

  @override
  void initState() {
    super.initState();
    maxHeight = config.peekHeight;
    peek = true;
  }

  @override
  void hide() {
    if (config.onHide != null) {
      config.onHide();
    }
    super.hide();
  }

  set peek(bool peeking) {
    if (peeking != _peeking) {
      _peeking = peeking;
      minHeight = _peeking ? config.peekHeight : 0.0;
      hide();
    }
  }

  /// Tracks how 'peeked' the overlay is taking [_kAngleOffsetY] into account.
  /// This is used to ensure the angle of the overlay is flat as it becomes
  /// fully 'unpeeked'. This tracks from [0.0 to 1.0] for [height]s of
  /// [_kAngleOffsetY to config.peekHeight].
  double get _peekProgress => math.max(
      0.0,
      math.min((height - _kAngleOffsetY) / (config.peekHeight - _kAngleOffsetY),
          1.0));

  @override
  Widget createWidget(BuildContext context, BoxConstraints constraints) {
    double targetMaxHeight = 0.8 * constraints.maxHeight;
    if (maxHeight != targetMaxHeight && targetMaxHeight != 0.0) {
      maxHeight = targetMaxHeight;
      if (active) {
        show();
      }
    }
    return new Stack(children: [
      new CustomPaint(
          painter: new QuadrilateralPainter(
              topLeftInset:
                  new Offset(0.0, _kAngleOffsetY * (1.0 - openingProgress)),
              topRightInset:
                  new Offset(0.0, _kAngleOffsetY * (1.0 - _peekProgress)),
              color: Colors.white)),
      config.child,
      new Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          height: config.peekHeight,
          child: new GestureDetector(
              onVerticalDragUpdate: onVerticalDragUpdate,
              onVerticalDragEnd: onVerticalDragEnd))
    ]);
  }

  void onVerticalDragUpdate(DragUpdateDetails details) =>
      setHeight(height - details.primaryDelta, force: true);

  void onVerticalDragEnd(DragEndDetails details) =>
      snap(details.velocity.pixelsPerSecond.dy);
}
