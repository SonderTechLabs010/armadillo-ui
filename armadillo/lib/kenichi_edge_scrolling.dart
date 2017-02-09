// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

/// Manages the state for an edge scrolling animation using Kenichi's algorithm.
class KenichiEdgeScrolling {
  static final double a = 1.0;
  static final double b = 0.5;
  static final double c = 1.5;
  static final double d = 0.02;
  static final double e = 2.0;
  static final double th = 120.0;
  static final double th2 = 40.0;

  double _velocity = 0.0;
  double _screenH = 2.0 * th;
  double _p = th;

  /// [p] is the y position of the finger on the screen.
  /// [screenH] the height of the screen.
  void update(double p, double screenH) {
    _p = p;
    _screenH = screenH;
  }

  /// Resets [_p] to a reasonable value for the algorithm.
  void onNoDrag() {
    _p = _screenH / 2.0;
  }

  /// [time] is elapsed time in seconds.
  /// Returns the distance to scroll.
  double getScrollDelta(double time) {
    // If we should scroll up, accelerate upward.
    if (shouldScrollUp) {
      double r = _smoothstep(th, th2, _p);
      _velocity += math.pow(r, a) * b * time * 60;
    }

    // If we should scroll down, accelerate downward.
    if (shouldScrollDown) {
      double r = _smoothstep(th, th2, _screenH - _p);
      _velocity -= math.pow(r, a) * b * time * 60;
    }

    // Apply friction.
    double friction;
    if (_p < _screenH / 2) {
      friction = math.pow(math.max(0.0, _p) / th, c) * d;
    } else {
      friction = math.pow(math.max(0.0, (_screenH - _p)) / th, c) * d;
    }
    _velocity -= _velocity * friction * time * 60;

    // Once we drop below a certian threshold, jump to 0.0.
    if (_velocity.abs() < 0.1) {
      _velocity = 0.0;
    }

    return _velocity * time * 60;
  }

  bool get shouldScrollUp => _p < th;
  bool get shouldScrollDown => _p > _screenH - th;
  bool get isDone => !shouldScrollUp && !shouldScrollDown && _velocity == 0.0;

  static double _smoothstep(double a, double b, double n) {
    double t = (n - a) / (b - a) * 12 - 6;
    return 1 / (1 + math.pow(math.E, -t));
  }
}
