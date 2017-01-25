// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'simulated_sized_box.dart';

const RK4SpringDescription _kDefaultSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Animates a [Positioned]'s [left], [top], [width], and [height] with a
/// spring simulation.
class SimulatedPositioned extends StatefulWidget {
  final double top;
  final double left;
  final double width;
  final double height;
  final RK4SpringDescription springDescription;
  final Widget child;

  SimulatedPositioned({
    Key key,
    this.top,
    this.left,
    this.width,
    this.height,
    this.springDescription: _kDefaultSimulationDesc,
    this.child,
  })
      : super(key: key);

  @override
  SimulatedPositionedState createState() => new SimulatedPositionedState();
}

class SimulatedPositionedState extends TickingState<SimulatedPositioned> {
  final GlobalKey<SimulatedSizedBoxState> _sizedBoxKey =
      new GlobalKey<SimulatedSizedBoxState>();
  RK4SpringSimulation _leftSimulation;
  RK4SpringSimulation _topSimulation;

  @override
  void initState() {
    super.initState();
    _leftSimulation = new RK4SpringSimulation(
      initValue: config.left,
      desc: config.springDescription,
    );
    _topSimulation = new RK4SpringSimulation(
      initValue: config.top,
      desc: config.springDescription,
    );
  }

  @override
  void didUpdateConfig(SimulatedPositioned oldConfig) {
    super.didUpdateConfig(oldConfig);
    _leftSimulation.target = config.left;
    _topSimulation.target = config.top;
    startTicking();
  }

  @override
  Widget build(BuildContext context) => new Positioned(
        left: _leftSimulation.value,
        top: _topSimulation.value,
        child: new SimulatedSizedBox(
          key: _sizedBoxKey,
          width: config.width,
          height: config.height,
          springDescription: config.springDescription,
          child: config.child,
        ),
      );

  @override
  bool handleTick(double elapsedSeconds) {
    _leftSimulation.elapseTime(elapsedSeconds);
    _topSimulation.elapseTime(elapsedSeconds);
    return !(_leftSimulation.isDone && _topSimulation.isDone);
  }

  set bounds(Rect bounds) {
    _leftSimulation = new RK4SpringSimulation(
      initValue: bounds.topLeft.x,
      desc: config.springDescription,
    );
    _topSimulation = new RK4SpringSimulation(
      initValue: bounds.topLeft.y,
      desc: config.springDescription,
    );
    _sizedBoxKey.currentState.size = new Size(bounds.width, bounds.height);
  }
}
