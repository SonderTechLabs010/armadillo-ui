// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [SizedBox]'s [width] and [height] with a
/// spring simulation.
class SimulatedSizedBox extends StatefulWidget {
  final double width;
  final double height;
  final RK4SpringDescription springDescription;
  final Widget child;

  SimulatedSizedBox({
    Key key,
    this.width,
    this.height,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key);

  @override
  SimulatedSizedBoxState createState() => new SimulatedSizedBoxState();
}

class SimulatedSizedBoxState extends TickingState<SimulatedSizedBox> {
  RK4SpringSimulation _widthSimulation;
  RK4SpringSimulation _heightSimulation;

  @override
  void initState() {
    super.initState();
    _widthSimulation = new RK4SpringSimulation(
      initValue: config.width,
      desc: config.springDescription,
    );
    _heightSimulation = new RK4SpringSimulation(
      initValue: config.height,
      desc: config.springDescription,
    );
  }

  @override
  void didUpdateConfig(SimulatedSizedBox oldConfig) {
    super.didUpdateConfig(oldConfig);
    _widthSimulation.target = config.width;
    _heightSimulation.target = config.height;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new SizedBox(
        width: _widthSimulation.value.clamp(0.0, double.INFINITY),
        height: _heightSimulation.value.clamp(0.0, double.INFINITY),
        child: config.child,
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _widthSimulation.elapseTime(elapsedSeconds);
    _heightSimulation.elapseTime(elapsedSeconds);
    return !(_heightSimulation.isDone && _widthSimulation.isDone);
  }

  set size(Size size) {
    _widthSimulation = new RK4SpringSimulation(
      initValue: size.width,
      desc: config.springDescription,
    );
    _heightSimulation = new RK4SpringSimulation(
      initValue: size.height,
      desc: config.springDescription,
    );
  }
}
