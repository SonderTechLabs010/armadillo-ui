// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/quadrilateral_painter.dart';
import 'package:sysui_widgets/ticking_height_state.dart';

const double _kStartOverlayTransitionHeight = 28.0;

/// The distance the top right corner is inset when peeking.  When hiding, the
/// top left corner will inset the same distance as the overlay becomes
/// fully hidden.
const double _kAngleOffsetY = 0.0;

/// A bottom aligned overlay which peeks up over the bottom.
class PeekingOverlay extends StatefulWidget {
  final double peekHeight;
  final double parentWidth;
  final Widget child;
  final VoidCallback onHide;
  final VoidCallback onShow;
  PeekingOverlay({
    Key key,
    this.peekHeight: _kStartOverlayTransitionHeight,
    this.parentWidth,
    this.onHide,
    this.onShow,
    this.child,
  })
      : super(key: key);

  @override
  PeekingOverlayState createState() => new PeekingOverlayState();

  double get darkeningBackgroundMinHeight => peekHeight;
}

/// A [TickingHeightState] that changes its height to [minHeight] via [hide] and\
/// [maxHeight] via [show].
///
/// As the [height] increases above [minHeight] [PeekingOverlay.child] will grow
/// up from the bottom.  The area not given to that [Widget] will gradually
/// darken.
///
/// The [createWidget] [Widget] will be clipped to [height] but will be given
/// [maxHeight] to be laid out in.
class PeekingOverlayState extends TickingHeightState<PeekingOverlay> {
  static final double kSnapVelocityThreshold = 500.0;
  bool _hiding = true;
  bool _peeking;
  Widget _dragTarget;
  Widget _tapDetector;

  @override
  void initState() {
    super.initState();
    maxHeight = config.peekHeight;
    peek = true;
    _dragTarget = new Positioned(
      top: 0.0,
      left: 0.0,
      right: 0.0,
      height: config.peekHeight,
      child: new GestureDetector(
        onVerticalDragUpdate: onVerticalDragUpdate,
        onVerticalDragEnd: onVerticalDragEnd,
      ),
    );
    _tapDetector = new Listener(
      onPointerUp: (_) => hide(),
      behavior: HitTestBehavior.opaque,
    );
  }

  void hide() {
    if (config.onHide != null) {
      config.onHide();
    }
    _hiding = true;
    setHeight(minHeight);
  }

  void show() {
    if (config.onShow != null) {
      config.onShow();
    }
    _hiding = false;
    setHeight(maxHeight);
  }

  set peek(bool peeking) {
    if (peeking != _peeking) {
      _peeking = peeking;
      minHeight = _peeking ? config.peekHeight : 0.0;
      hide();
    }
  }

  bool get hiding => _hiding;

  /// Tracks how 'peeked' the overlay is taking [_kAngleOffsetY] into account.
  /// This is used to ensure the angle of the overlay is flat as it becomes
  /// fully 'unpeeked'. This tracks from [0.0 to 1.0] for [height]s of
  /// [_kAngleOffsetY to config.peekHeight].
  double get _peekProgress => math.max(
      0.0,
      math.min((height - _kAngleOffsetY) / (config.peekHeight - _kAngleOffsetY),
          1.0));

  void onVerticalDragUpdate(DragUpdateDetails details) =>
      setHeight(height - details.primaryDelta, force: true);

  void onVerticalDragEnd(DragEndDetails details) =>
      snap(details.velocity.pixelsPerSecond.dy);

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
  Widget build(BuildContext context) => new Stack(
        children: <Widget>[
          new IgnorePointer(
            child: new Container(
              decoration: new BoxDecoration(
                backgroundColor: _overlayBackgroundColor,
              ),
            ),
          ),
          new Offstage(
            offstage: hiding,
            child: _tapDetector,
          ),
          new Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            height: height,
            child: new OverflowBox(
              minWidth: config.parentWidth,
              maxWidth: config.parentWidth,
              minHeight: math.max(height, maxHeight),
              maxHeight: math.max(height, maxHeight),
              alignment: FractionalOffset.topCenter,
              child: new Stack(
                children: <Widget>[
                  new CustomPaint(
                    painter: new QuadrilateralPainter(
                      topLeftInset: new Offset(
                        0.0,
                        _kAngleOffsetY * (1.0 - _openingProgress),
                      ),
                      topRightInset: new Offset(
                        0.0,
                        _kAngleOffsetY * (1.0 - _peekProgress),
                      ),
                      color: new Color(0xFFDBE2E5),
                    ),
                  ),
                  config.child,
                  _dragTarget,
                ],
              ),
            ),
          ),
        ],
      );

  double get _openingProgress => (height > config.darkeningBackgroundMinHeight
      ? math.min(
          1.0,
          (height - config.darkeningBackgroundMinHeight) /
              (maxHeight - config.darkeningBackgroundMinHeight))
      : 0.0);

  Color get _overlayBackgroundColor =>
      new Color(((0xD9 * _openingProgress).round() << 24) + 0x00000000);
}
