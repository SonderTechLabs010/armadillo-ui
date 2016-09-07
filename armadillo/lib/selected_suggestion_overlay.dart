// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'suggestion_manager.dart';
import 'suggestion_widget.dart';

typedef void OnSuggestionExpanded(Suggestion suggestion);

const RK4SpringDescription _kExpansionSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kExpansionSimulationTarget = 200.0;
const RK4SpringDescription _kOpacitySimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kOpacitySimulationTarget = 1000.0;

/// When a Suggestion is selected, the suggestion is brought into this overlay
/// and an animation fills the overlay such that we can prepare the story that
/// will be displayed after the overlay animation finishes.
class SelectedSuggestionOverlay extends StatefulWidget {
  final OnSuggestionExpanded onSuggestionExpanded;
  final double minimizedNowBarHeight;

  SelectedSuggestionOverlay(
      {Key key, this.minimizedNowBarHeight, this.onSuggestionExpanded})
      : super(key: key);

  @override
  SelectedSuggestionOverlayState createState() =>
      new SelectedSuggestionOverlayState();
}

class SelectedSuggestionOverlayState
    extends TickingState<SelectedSuggestionOverlay> {
  Suggestion _suggestion;
  Rect _suggestionInitialGlobalBounds;
  RK4SpringSimulation _expansionSimulation;
  RK4SpringSimulation _opacitySimulation;

  /// Returns true if the overlay successfully initiates suggestion expansion.
  bool suggestionSelected({Suggestion suggestion, Rect globalBounds}) {
    if (_suggestion != null) {
      return false;
    }
    _suggestion = suggestion;
    _suggestionInitialGlobalBounds = globalBounds;
    _expansionSimulation = new RK4SpringSimulation(
        initValue: 0.0, desc: _kExpansionSimulationDesc);
    _expansionSimulation.target = _kExpansionSimulationTarget;
    _opacitySimulation = new RK4SpringSimulation(
        initValue: _kOpacitySimulationTarget, desc: _kOpacitySimulationDesc);
    _opacitySimulation.target = _kOpacitySimulationTarget;
    startTicking();
    return true;
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (_suggestion == null) {
            // If the overlay doesn't have a suggestion, stay offstage.
            return new Offstage(offstage: true);
          } else {
            // We have a suggestion so lets fill the screen with it.
            // Since we've been given the suggestion's global bounds we first
            // need to shift those bounds into local coordinates (ie. relative
            // to the overlay).
            RenderBox box = context.findRenderObject();
            Point topLeft = box.localToGlobal(Point.origin);
            Rect suggestionBoundsLocalToOverlay = _suggestionInitialGlobalBounds
                .shift(new Offset(-topLeft.x, -topLeft.y));

            return new Stack(
              children: [
                new Positioned(
                  left: (suggestionBoundsLocalToOverlay.left) *
                      (1.0 - _expansionProgress),
                  top: (suggestionBoundsLocalToOverlay.top) *
                      (1.0 - _expansionProgress),
                  width: suggestionBoundsLocalToOverlay.width +
                      (constraints.maxWidth -
                              suggestionBoundsLocalToOverlay.width) *
                          _expansionProgress,
                  height: suggestionBoundsLocalToOverlay.height +
                      (constraints.maxHeight -
                              suggestionBoundsLocalToOverlay.height -
                              config.minimizedNowBarHeight) *
                          _expansionProgress,
                  child: new Opacity(
                    opacity: _opacityProgress,
                    child: new SuggestionWidget(suggestion: _suggestion),
                  ),
                ),
              ],
            );
          }
        },
      );

  @override
  bool handleTick(double elapsedSeconds) {
    bool expansionWasDone = _expansionSimulation?.isDone ?? true;
    bool isDone = expansionWasDone;

    _opacitySimulation.elapseTime(elapsedSeconds);
    if (!_opacitySimulation.isDone) {
      isDone = false;
    } else if (_opacityProgress == 0.0) {
      _suggestion = null;
      _suggestionInitialGlobalBounds = null;
      _expansionSimulation = null;
    }

    if (!expansionWasDone) {
      // Tick the simulations.
      _expansionSimulation.elapseTime(elapsedSeconds);
      bool expansionIsDone = _expansionSimulation.isDone;

      // Notify that the story has come into focus.
      if (expansionIsDone && _expansionProgress == 1.0) {
        if (config.onSuggestionExpanded != null) {
          config.onSuggestionExpanded(_suggestion);
        }
        _opacitySimulation.target = 0.0;
        isDone = false;
      }
    }

    return !isDone;
  }

  double get _expansionProgress =>
      _expansionSimulation.value / _kExpansionSimulationTarget;

  double get _opacityProgress =>
      _opacitySimulation.value / _kOpacitySimulationTarget;
}
