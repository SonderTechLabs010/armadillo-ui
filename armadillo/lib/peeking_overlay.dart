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
  PeekingOverlay(
      {Key key, this.peekHeight: _kStartOverlayTransitionHeight, this.child})
      : super(key: key);

  @override
  PeekingOverlayState createState() =>
      new PeekingOverlayState(darkeningBackgroundMinHeight: peekHeight);
}

class PeekingOverlayState extends BottomAlignedOverlayState<PeekingOverlay> {
  static final double _kFinishOverlayTransitionHeight = 400.0;

  bool _peeking;

  PeekingOverlayState({double darkeningBackgroundMinHeight})
      : super(
            darkeningBackgroundMinHeight: darkeningBackgroundMinHeight,
            darkeningBackgroundMaxHeight: _kFinishOverlayTransitionHeight);

  @override
  void initState() {
    super.initState();
    maxHeight = _defaultMaxHeight;
    peek = true;
  }

  @override
  void hide() {
    if (maxHeight != _defaultMaxHeight) {
      maxHeight = _defaultMaxHeight;
      setHeight(maxHeight);
    }

    super.hide();
  }

  double get _defaultMaxHeight => parentHeight != null
      ? math.min(parentHeight, _kFinishOverlayTransitionHeight)
      : _kFinishOverlayTransitionHeight;

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
  Widget createWidget(BuildContext context) {
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
          height: 100.0,
          child: new GestureDetector(
              onTap: () => show(),
              onVerticalDragUpdate: (DragUpdateDetails details) =>
                  setHeight(height - details.primaryDelta, force: true),
              onVerticalDragEnd: (DragEndDetails details) =>
                  snap(details.velocity.pixelsPerSecond.dy)))
    ]);
  }
}
