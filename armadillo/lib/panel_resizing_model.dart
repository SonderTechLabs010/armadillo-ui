// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'model.dart';
import 'panel.dart';
import 'ticking_model.dart';

export 'model.dart' show ScopedModel, Model;

const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 750.0, friction: 50.0);

enum Side { left, right, top, bottom }

class ResizingSimulation {
  final RK4SpringSimulation simulation = new RK4SpringSimulation(
    initValue: 0.0,
    desc: _kSimulationDesc,
  );

  /// This map defines what [Side]s of what [Panel]s will have their margins be
  /// resized based on the value of [simulation].
  final Map<Side, List<Panel>> sideToPanelsMap;

  ResizingSimulation(this.sideToPanelsMap);
}

/// Tracks panel resizing state, notifying listeners when it changes.
/// Using an [PanelResizingModel] allows the panel resizing state it tracks to
/// be passed down the widget tree using a [ScopedModel].
class PanelResizingModel extends TickingModel {
  final Set<ResizingSimulation> simulations = new Set<ResizingSimulation>();

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static PanelResizingModel of(
    BuildContext context, {
    bool rebuildOnChange: false,
  }) =>
      new ModelFinder<PanelResizingModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  void resizeBegin(ResizingSimulation resizingSimulation) {
    assert(!simulations.contains(resizingSimulation));
    simulations.add(resizingSimulation);
    resizingSimulation.simulation.target = 1.0;
    startTicking();
  }

  void resizeEnd(ResizingSimulation resizingSimulation) {
    assert(simulations.contains(resizingSimulation));
    resizingSimulation.simulation.target = 0.0;
    startTicking();
  }

  double getLeftProgress(Panel panel) => _getProgress(panel, Side.left);

  double getRightProgress(Panel panel) => _getProgress(panel, Side.right);

  double getTopProgress(Panel panel) => _getProgress(panel, Side.top);

  double getBottomProgress(Panel panel) => _getProgress(panel, Side.bottom);

  ResizingSimulation getSimulation(Map<Side, List<Panel>> sideToPanelsMap) {
    List<ResizingSimulation> simulations = this
        .simulations
        .where(
          (ResizingSimulation resizingSimulation) => _areEqual(
                sideToPanelsMap,
                resizingSimulation.sideToPanelsMap,
              ),
        )
        .toList();
    assert(simulations.length <= 1);
    return simulations.isEmpty ? null : simulations.first;
  }

  bool _areEqual(Map<Side, List<Panel>> a, Map<Side, List<Panel>> b) =>
      (a.keys.length != b.keys.length)
          ? false
          : a.keys.every((Side side) {
              List<Panel> aPanels = a[side];
              List<Panel> bPanels = b[side];
              if (bPanels == null) {
                return false;
              }
              if (bPanels.length != aPanels.length) {
                return false;
              }
              for (int i = 0; i < aPanels.length; i++) {
                if (aPanels[i] != bPanels[i]) {
                  return false;
                }
              }
              return true;
            });

  double _getProgress(Panel panel, Side side) {
    List<ResizingSimulation> simulations = this
        .simulations
        .where((ResizingSimulation resizingSimulation) =>
            resizingSimulation.sideToPanelsMap[side]?.contains(panel) ?? false)
        .toList();
    assert(simulations.length <= 1);
    return simulations.isEmpty ? 0.0 : simulations.first.simulation.value;
  }

  @override
  bool handleTick(double elapsedSeconds) {
    bool done = true;
    simulations.toList().forEach((ResizingSimulation resizingSimulation) {
      if (!resizingSimulation.simulation.isDone) {
        resizingSimulation.simulation.elapseTime(elapsedSeconds);
      }
      if (!resizingSimulation.simulation.isDone) {
        done = false;
      } else if (resizingSimulation.simulation.target == 0.0) {
        simulations.remove(resizingSimulation);
      }
    });
    return !done;
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
