// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

/// Constants for the simulation.
const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kSimulationTarget = 200.0;
const double _kJumpAlmostToFinishDelta = 1.0;

typedef void ProgressListener(double progress, bool isDone);
typedef Widget ProgressBuilder(BuildContext context, double progress);

/// Manages a simulation for the [Widget] built via [builder] allowing it to be
/// stateless.
class SimulationBuilder extends StatefulWidget {
  final ProgressListener onSimulationChanged;
  final double initialSimulationProgress;
  final ProgressBuilder builder;
  SimulationBuilder({
    Key key,
    this.onSimulationChanged,
    this.initialSimulationProgress: 0.0,
    this.builder,
  })
      : super(key: key);

  @override
  SimulationBuilderState createState() => new SimulationBuilderState();
}

class SimulationBuilderState extends TickingState<SimulationBuilder> {
  RK4SpringSimulation _simulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kSimulationDesc);

  @override
  void initState() {
    super.initState();
    _simulation = new RK4SpringSimulation(
      initValue: config.initialSimulationProgress * _kSimulationTarget,
      desc: _kSimulationDesc,
    );
    _simulation.target = _kSimulationTarget;
  }

  /// If [jumpAlmostToFinish] is true we jump almost to the end of the
  /// simulation. We jump *almost* to finish so the secondary size simulations
  /// jump almost to finish as well (otherwise they would animate from unfocused
  /// size).
  void forward({bool jumpAlmostToFinish: false}) {
    if (jumpAlmostToFinish) {
      _simulation = new RK4SpringSimulation(
        initValue: _kSimulationTarget - _kJumpAlmostToFinishDelta,
        desc: _kSimulationDesc,
      );
    }
    _simulation.target = _kSimulationTarget;
    startTicking();
  }

  void reverse() {
    _simulation.target = 0.0;
    startTicking();
  }

  double get progress => _simulation.value / _kSimulationTarget;

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
