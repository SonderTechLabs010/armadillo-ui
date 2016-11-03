// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

/// Fade out slowly.
const RK4SpringDescription _kFadeOutSimulationDesc =
    const RK4SpringDescription(tension: 100.0, friction: 50.0);

/// Fade in quickly.
const RK4SpringDescription _kFadeInSimulationDesc =
    const RK4SpringDescription(tension: 900.0, friction: 50.0);

class NowMinimizedInfoFader {
  final VoidCallback onChange;
  RK4SpringSimulation _fadeSimulation;
  Timer _fadeTimer;
  Ticker _ticker;
  Duration _lastTick;

  NowMinimizedInfoFader({this.onChange});

  void fadeIn({bool force: false}) {
    _fadeSimulation = new RK4SpringSimulation(
        initValue: force ? 1.0 : _fadeSimulation?.value ?? 0.0,
        desc: _kFadeInSimulationDesc);
    _fadeSimulation.target = 1.0;

    _startTicking();

    // Start a timer for fading out.
    _fadeTimer?.cancel();
    _fadeTimer = new Timer(const Duration(milliseconds: 1500), _fadeOut);
  }

  void _fadeOut() {
    _fadeSimulation = new RK4SpringSimulation(
        initValue: _fadeSimulation?.value ?? 0.0,
        desc: _kFadeOutSimulationDesc);
    _fadeSimulation.target = 0.0;

    _startTicking();
  }

  void reset() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _ticker?.stop();
    _ticker = null;
    _fadeSimulation = null;
  }

  // Returns the opacity that should be used to fade the minimized info.
  double get opacity => (_fadeSimulation?.value ?? 0.0).clamp(0.0, 1.0);

  bool _handleTick(double elapsedSeconds) {
    _fadeSimulation.elapseTime(elapsedSeconds);
    return !_fadeSimulation.isDone;
  }

  void _startTicking() {
    if (_ticker?.isTicking ?? false) {
      return;
    }
    _ticker = new Ticker(_onTick);
    _lastTick = Duration.ZERO;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final double elapsedSeconds =
        (elapsed.inMicroseconds - _lastTick.inMicroseconds) / 1000000.0;
    _lastTick = elapsed;

    bool continueTicking = _handleTick(elapsedSeconds);
    if (!continueTicking) {
      _ticker?.stop();
      _ticker = null;
    }
    onChange?.call();
  }
}

class Fader extends StatefulWidget {
  final Widget child;

  Fader({Key key, this.child}) : super(key: key);

  @override
  FaderState createState() => new FaderState();
}

class FaderState extends State<Fader> {
  NowMinimizedInfoFader _nowMinimizedInfoFader;

  @override
  void initState() {
    super.initState();
    _nowMinimizedInfoFader = new NowMinimizedInfoFader(
      onChange: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _nowMinimizedInfoFader.reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new Opacity(
        opacity: _nowMinimizedInfoFader.opacity,
        child: config.child,
      );

  void fadeIn({bool force: false}) => _nowMinimizedInfoFader.fadeIn(
        force: force,
      );
}
