// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Positioned]'s [Positioned.left], [Positioned.top],
/// [Positioned.width], and [Positioned.height] with a
/// spring simulation based on the given [size] and fractional coordinates
/// within that [size] specified by [fractionalTop], [fractionalLeft],
/// [fractionalWidth], and [fractionalHeight].
/// If [fractionalTop] and [fractionalLeft] are both null, a [SizedBox] will
/// be used instead of a [Positioned].
class SimulatedFractional extends StatefulWidget {
  final double fractionalTop;
  final double fractionalLeft;
  final double fractionalWidth;
  final double fractionalHeight;
  final Size size;
  final RK4SpringDescription springDescription;
  final Widget child;

  SimulatedFractional({
    Key key,
    this.fractionalTop,
    this.fractionalLeft,
    this.fractionalWidth,
    this.fractionalHeight,
    this.size,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key) {
    assert(fractionalWidth != null);
    assert(fractionalHeight != null);
    assert(size != null);
    assert(springDescription != null);
    assert(child != null);
    assert((fractionalTop == null && fractionalLeft == null) ||
        (fractionalTop != null && fractionalLeft != null));
  }

  @override
  SimulatedFractionalState createState() => new SimulatedFractionalState();
}

class SimulatedFractionalState extends TickingState<SimulatedFractional> {
  RK4SpringSimulation _fractionalTopSimulation;
  RK4SpringSimulation _fractionalLeftSimulation;
  RK4SpringSimulation _fractionalWidthSimulation;
  RK4SpringSimulation _fractionalHeightSimulation;

  @override
  void initState() {
    super.initState();
    if (config.fractionalTop != null) {
      _fractionalTopSimulation = new RK4SpringSimulation(
        initValue: config.fractionalTop,
        desc: config.springDescription,
      );
      _fractionalLeftSimulation = new RK4SpringSimulation(
        initValue: config.fractionalLeft,
        desc: config.springDescription,
      );
    }
    _fractionalWidthSimulation = new RK4SpringSimulation(
      initValue: config.fractionalWidth,
      desc: config.springDescription,
    );
    _fractionalHeightSimulation = new RK4SpringSimulation(
      initValue: config.fractionalHeight,
      desc: config.springDescription,
    );
  }

  @override
  void didUpdateConfig(SimulatedFractional oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.fractionalTop != null) {
      _fractionalTopSimulation.target = config.fractionalTop;
      _fractionalLeftSimulation.target = config.fractionalLeft;
    } else {
      _fractionalTopSimulation = null;
      _fractionalLeftSimulation = null;
    }
    _fractionalWidthSimulation.target = config.fractionalWidth;
    _fractionalHeightSimulation.target = config.fractionalHeight;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => _fractionalTopSimulation == null
      ? new SizedBox(
          width: _fractionalWidthSimulation.value * config.size.width,
          height: _fractionalHeightSimulation.value * config.size.height,
          child: config.child,
        )
      : new Positioned(
          top: _fractionalTopSimulation.value * config.size.height,
          left: _fractionalLeftSimulation.value * config.size.width,
          width: _fractionalWidthSimulation.value * config.size.width,
          height: _fractionalHeightSimulation.value * config.size.height,
          child: config.child,
        );

  @override
  bool handleTick(double elapsedSeconds) {
    _fractionalTopSimulation?.elapseTime(elapsedSeconds);
    _fractionalLeftSimulation?.elapseTime(elapsedSeconds);
    _fractionalWidthSimulation.elapseTime(elapsedSeconds);
    _fractionalHeightSimulation.elapseTime(elapsedSeconds);
    return !((_fractionalTopSimulation?.isDone ?? true) &&
        (_fractionalLeftSimulation?.isDone ?? true) &&
        _fractionalWidthSimulation.isDone &&
        _fractionalHeightSimulation.isDone);
  }

  void jumpFractionalHeight(double fractionalHeight) {
    _fractionalHeightSimulation = new RK4SpringSimulation(
      initValue: fractionalHeight,
      desc: config.springDescription,
    );
  }

  void jump(Rect bounds, Size newSize) {
    _fractionalTopSimulation = new RK4SpringSimulation(
      initValue: bounds.topLeft.y / newSize.height,
      desc: config.springDescription,
    );
    _fractionalLeftSimulation = new RK4SpringSimulation(
      initValue: bounds.topLeft.x / newSize.width,
      desc: config.springDescription,
    );
    _fractionalWidthSimulation = new RK4SpringSimulation(
      initValue: bounds.width / newSize.width,
      desc: config.springDescription,
    );
    _fractionalHeightSimulation = new RK4SpringSimulation(
      initValue: bounds.height / newSize.height,
      desc: config.springDescription,
    );
  }

  @override
  String toString() =>
      'SimulatedFractionalState(top: $_fractionalTopSimulation, '
      'left: $_fractionalLeftSimulation, '
      'width: $_fractionalWidthSimulation, '
      'height: $_fractionalHeightSimulation)';
}
