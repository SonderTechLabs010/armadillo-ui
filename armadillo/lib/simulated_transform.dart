// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Transform]'s translation [dx] and [dy], [scale] and opacity
/// with a spring simulation.  When first built this widget's opacity will start
/// with [initOpacity] and will animate to [targetOpacity].  Rebuilds of this
/// widget will animate from the current opacity value to [targetOpacity]
/// instead of animating from [initOpacity].
class SimulatedTransform extends StatefulWidget {
  final double dx;
  final double dy;
  final double scale;
  final double initOpacity;
  final double targetOpacity;
  final RK4SpringDescription springDescription;
  final Widget child;

  SimulatedTransform({
    Key key,
    this.dx,
    this.dy,
    this.scale: 1.0,
    this.initOpacity: 1.0,
    this.targetOpacity: 1.0,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key);

  @override
  SimulatedTranslationTransformState createState() =>
      new SimulatedTranslationTransformState();
}

class SimulatedTranslationTransformState
    extends TickingState<SimulatedTransform> {
  RK4SpringSimulation _dxSimulation;
  RK4SpringSimulation _dySimulation;
  RK4SpringSimulation _scaleSimulation;
  RK4SpringSimulation _opacitySimulation;

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
    _scaleSimulation = new RK4SpringSimulation(
      initValue: config.scale,
      desc: config.springDescription,
    );
    _opacitySimulation = new RK4SpringSimulation(
      initValue: config.initOpacity,
      desc: config.springDescription,
    );
    _opacitySimulation.target = config.targetOpacity;
    startTicking();
  }

  @override
  void didUpdateConfig(SimulatedTransform oldConfig) {
    super.didUpdateConfig(oldConfig);
    _dxSimulation.target = config.dx;
    _dySimulation.target = config.dy;
    _scaleSimulation.target = config.scale;
    _opacitySimulation.target = config.targetOpacity;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new Transform(
      transform: new Matrix4.translationValues(
        _dxSimulation.value,
        _dySimulation.value,
        0.0,
      ),
      child: new Transform(
        transform: new Matrix4.identity().scaled(
          _scaleSimulation.value,
          _scaleSimulation.value,
        ),
        alignment: FractionalOffset.center,
        child: new Opacity(
          opacity: _opacitySimulation.value.clamp(0.0, 1.0),
          child: config.child,
        ),
      ));

  @override
  bool handleTick(double elapsedSeconds) {
    _dxSimulation.elapseTime(elapsedSeconds);
    _dySimulation.elapseTime(elapsedSeconds);
    _scaleSimulation.elapseTime(elapsedSeconds);
    _opacitySimulation.elapseTime(elapsedSeconds);
    return !_dxSimulation.isDone ||
        !_dySimulation.isDone ||
        !_scaleSimulation.isDone ||
        !_opacitySimulation.isDone;
  }
}
