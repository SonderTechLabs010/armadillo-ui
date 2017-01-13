// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

/// Constants for the simulation.
const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

typedef void ProgressListener(double progress, bool isDone);
typedef Widget ProgressBuilder(BuildContext context, double progress);

/// Manages a simulation for the [Widget] built via [builder] allowing it to be
/// stateless.
class SimulationBuilder extends StatefulWidget {
  final ProgressListener onSimulationChanged;
  final double initValue;
  final double targetValue;
  final ProgressBuilder builder;
  SimulationBuilder({
    Key key,
    this.onSimulationChanged,
    this.initValue: 0.0,
    this.targetValue: 0.0,
    this.builder,
  })
      : super(key: key);

  @override
  SimulationBuilderState createState() => new SimulationBuilderState();
}

class SimulationBuilderState extends TickingState<SimulationBuilder> {
  RK4SpringSimulation _simulation;

  @override
  void initState() {
    super.initState();
    _simulation = new RK4SpringSimulation(
      initValue: config.initValue,
      desc: _kSimulationDesc,
    );
    _simulation.target = config.targetValue;
    startTicking();
  }

  @override
  void didUpdateConfig(SimulationBuilder oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (oldConfig.targetValue != config.targetValue) {
      _simulation.target = config.targetValue;
      startTicking();
    }
  }

  void resetTo(double initValue, double target) {
    setState(() {
      _simulation = new RK4SpringSimulation(
        initValue: initValue,
        desc: _kSimulationDesc,
      );
    });
    this.target = target;
  }

  set target(double target) {
    if (_simulation.target != target) {
      _simulation.target = target;
      startTicking();
    }
  }

  double get progress => _simulation.value;

  @override
  bool handleTick(double elapsedSeconds) {
    bool wasDone = _simulation.isDone;
    if (wasDone) {
      return false;
    }

    // Tick the simulation.
    _simulation.elapseTime(elapsedSeconds);

    // Notify listeners of progress change.
    config.onSimulationChanged?.call(progress, _simulation.isDone);

    return !_simulation.isDone;
  }

  @override
  Widget build(BuildContext context) => config.builder(context, progress);
}
