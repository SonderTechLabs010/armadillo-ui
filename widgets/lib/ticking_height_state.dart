// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'rk4_spring_simulation.dart';
import 'ticking_state.dart';

const double _kHeightSimulationTension = 450.0;
const double _kHeightSimulationFriction = 50.0;
const RK4SpringDescription _kHeightSimulationDesc = const RK4SpringDescription(
    tension: _kHeightSimulationTension, friction: _kHeightSimulationFriction);

/// A [TickingState] that simulates changes to its height as a RK4 spring.
abstract class TickingHeightState<T extends StatefulWidget>
    extends TickingState<T> {
  final RK4SpringDescription springDescription;
  RK4SpringSimulation _heightSimulation;

  TickingHeightState({this.springDescription: _kHeightSimulationDesc});

  double _minHeight = 0.0;
  double get minHeight => _minHeight;
  set minHeight(double minHeight) {
    _minHeight = minHeight;
    if (height < _minHeight) {
      setHeight(_minHeight);
    }
  }

  double _maxHeight = 0.0;
  double get maxHeight => _maxHeight;
  set maxHeight(double maxHeight) {
    _maxHeight = maxHeight;
    if (height > _maxHeight) {
      setHeight(_maxHeight);
    }
  }

  void setHeight(double height, {bool force: false}) {
    double newHeight = height.clamp(_minHeight, _maxHeight);
    if (force) {
      _heightSimulation = new RK4SpringSimulation(
          initValue: newHeight, desc: springDescription);
    } else {
      if (_heightSimulation == null) {
        _heightSimulation = new RK4SpringSimulation(
            initValue: newHeight, desc: springDescription);
      } else {
        _heightSimulation.target = newHeight;
      }
    }
    startTicking();
  }

  double get height =>
      (_heightSimulation == null || _heightSimulation.value < 0.0)
          ? 0.0
          : _heightSimulation.value;

  @override
  bool handleTick(double elapsedSeconds) {
    bool continueTicking = false;

    if (_heightSimulation != null) {
      if (!_heightSimulation.isDone) {
        _heightSimulation.elapseTime(elapsedSeconds);
        if (!_heightSimulation.isDone) {
          continueTicking = true;
        }
      }
    }
    return continueTicking;
  }
}
