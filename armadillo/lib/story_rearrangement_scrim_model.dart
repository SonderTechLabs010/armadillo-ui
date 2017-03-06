// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'model.dart';
import 'story_cluster_drag_state_model.dart';
import 'ticking_model.dart';

export 'model.dart' show ScopedModel, Model;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Base class for [Model]s that depend on a Ticker.
class StoryRearrangementScrimModel extends TickingModel {
  final RK4SpringSimulation _opacitySimulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kSimulationDesc,
  );

  void onDragAcceptableStateChanged(bool isAcceptable) {
    _opacitySimulation.target = isAcceptable ? 0.6 : 0.0;
    startTicking();
  }

  Color get scrimColor => Colors.black.withOpacity(_opacitySimulation.value);
  double get progress => _opacitySimulation.value / 0.6;

  @override
  bool handleTick(double elapsedSeconds) {
    _opacitySimulation.elapseTime(elapsedSeconds);
    return !_opacitySimulation.isDone;
  }

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static StoryRearrangementScrimModel of(
    BuildContext context, {
    bool rebuildOnChange: false,
  }) =>
      new ModelFinder<StoryRearrangementScrimModel>().of(
        context,
        rebuildOnChange: rebuildOnChange,
      );
}
