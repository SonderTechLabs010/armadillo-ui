// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Padding]'s [padding] with a spring simulation.
class SimulatedPadding extends StatefulWidget {
  final EdgeInsets padding;
  final RK4SpringDescription springDescription;
  final Widget child;

  SimulatedPadding({
    Key key,
    this.padding,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key);

  @override
  SimulatedPaddingState createState() => new SimulatedPaddingState();
}

class SimulatedPaddingState extends TickingState<SimulatedPadding> {
  RK4SpringSimulation _leftSimulation;
  RK4SpringSimulation _rightSimulation;

  @override
  void initState() {
    super.initState();
    _leftSimulation = new RK4SpringSimulation(
      initValue: config.padding.left,
      desc: config.springDescription,
    );
    _rightSimulation = new RK4SpringSimulation(
      initValue: config.padding.right,
      desc: config.springDescription,
    );
  }

  @override
  void didUpdateConfig(SimulatedPadding oldConfig) {
    super.didUpdateConfig(oldConfig);
    _leftSimulation.target = config.padding.left;
    _rightSimulation.target = config.padding.right;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new Padding(
        padding: new EdgeInsets.only(
          left: _leftSimulation.value,
          right: _rightSimulation.value,
        ),
        child: config.child,
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _leftSimulation.elapseTime(elapsedSeconds);
    _rightSimulation.elapseTime(elapsedSeconds);
    return !_leftSimulation.isDone || !_rightSimulation.isDone;
  }
}
