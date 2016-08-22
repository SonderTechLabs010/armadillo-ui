// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A [State] that manages the ticking part of a ticking simulation for its
/// subclass.
abstract class TickingState<T extends StatefulWidget> extends State<T> {
  Ticker _ticker;
  Duration _lastTick;

  /// Returns false if [_ticker] should stop ticking after this tick.
  bool handleTick(double elapsedSeconds);

  void startTicking() {
    if (_ticker?.isTicking ?? false) {
      return;
    }
    _ticker = new Ticker(_onTick);
    _lastTick = Duration.ZERO;
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker?.stop();
    _ticker = null;
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final double elapsedSeconds =
        (elapsed.inMicroseconds - _lastTick.inMicroseconds) / 1000000.0;
    _lastTick = elapsed;

    setState(() {
      bool continueTicking = handleTick(elapsedSeconds);
      if (!continueTicking) {
        _ticker?.stop();
        _ticker = null;
      }
    });
  }
}
