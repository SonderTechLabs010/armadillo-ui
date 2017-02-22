// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'model.dart';
import 'ticking_model.dart';

export 'model.dart' show ScopedModel, Model;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

/// Tracks panel resizing state, notifying listeners when it changes.
/// Using an [PanelResizingModel] allows the panel resizing state it tracks to
/// be passed down the widget tree using a [ScopedModel].
class PanelResizingModel extends TickingModel {
  final RK4SpringSimulation _resizingSimulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kSimulationDesc,
  );
  int _resizingCount = 0;

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static PanelResizingModel of(
    BuildContext context, {
    bool rebuildOnChange: false,
  }) =>
      new ModelFinder<PanelResizingModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  bool get resizing => _resizingCount > 0;

  void resizeBegin() {
    _resizingCount++;
    if (_resizingCount == 1) {
      _resizingSimulation.target = 1.0;
      startTicking();
    }
  }

  void resizeEnd() {
    _resizingCount--;
    assert(_resizingCount >= 0);
    if (_resizingCount == 0) {
      _resizingSimulation.target = 0.0;
      startTicking();
    }
  }

  double get progress => _resizingSimulation.value;

  @override
  bool handleTick(double elapsedSeconds) {
    _resizingSimulation.elapseTime(elapsedSeconds);
    return !_resizingSimulation.isDone;
  }
}

typedef Widget ScopedPanelResizingWidgetBuilder(
  BuildContext context,
  Widget child,
  PanelResizingModel panelResizingModel,
);

class ScopedPanelResizingWidget extends StatelessWidget {
  final ScopedPanelResizingWidgetBuilder builder;
  final Widget child;
  ScopedPanelResizingWidget({this.builder, this.child});

  @override
  Widget build(BuildContext context) => builder(
        context,
        child,
        PanelResizingModel.of(context, rebuildOnChange: true),
      );
}
