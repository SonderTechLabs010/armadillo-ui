// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

/// Animates a [Transform]'s translations [dx] and [dy] with a
/// spring simulation.
class SimulatedTranslationTransform extends StatefulWidget {
  final double dx;
  final double dy;
  final RK4SpringDescription springDescription;
  final Widget child;

  SimulatedTranslationTransform({
    Key key,
    this.dx,
    this.dy,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key);

  @override
  SimulatedTranslationTransformState createState() =>
      new SimulatedTranslationTransformState();
}

class SimulatedTranslationTransformState
    extends TickingState<SimulatedTranslationTransform> {
  RK4SpringSimulation _dxSimulation;
  RK4SpringSimulation _dySimulation;

  @override
  void initState() {
    super.initState();
    _dxSimulation = new RK4SpringSimulation(
      initValue: config.dx,
      desc: config.springDescription,
    );
    _dySimulation = new RK4SpringSimulation(
      initValue: config.dy,
      desc: config.springDescription,
    );
  }

  @override
  void didUpdateConfig(SimulatedTranslationTransform oldConfig) {
    super.didUpdateConfig(oldConfig);
    _dxSimulation.target = config.dx;
    _dySimulation.target = config.dy;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new Transform(
      transform: new Matrix4.translationValues(
        _dxSimulation.value,
        _dySimulation.value,
        0.0,
      ),
      child: config.child);

  @override
  bool handleTick(double elapsedSeconds) {
    _dxSimulation.elapseTime(elapsedSeconds);
    _dySimulation.elapseTime(elapsedSeconds);
    return !_dxSimulation.isDone || !_dySimulation.isDone;
  }
}
