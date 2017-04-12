// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'selected_suggestion_overlay.dart';
import 'suggestion.dart';
import 'suggestion_widget.dart';

/// Called when the [Widget] representing [Suggestion] has fully expanded to
/// fill its parent.
typedef void OnSuggestionExpanded(Suggestion suggestion);

const RK4SpringDescription _kExpansionSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kExpansionSimulationTarget = 200.0;
const RK4SpringDescription _kOpacitySimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kOpacitySimulationTarget = 1000.0;

/// Expands the [suggestion] to fill the screen (modulo the space for the now
/// bar at the bottom) and then fades to reveal what's behind.
class ExpandSuggestion extends ExpansionBehavior {
  /// The margin to not draw into at the bottom of the parent when filling the
  /// parent.
  final double bottomMargin;

  /// The suggestion to expand.
  final Suggestion suggestion;

  /// The initial bounds of the suggestion's [Widget].
  final Rect suggestionInitialGlobalBounds;

  /// Called when the [Widget] representing [suggestion] has fully expanded to
  /// fill its parent.
  final OnSuggestionExpanded onSuggestionExpanded;

  RK4SpringSimulation _expansionSimulation;
  RK4SpringSimulation _opacitySimulation;

  /// Constructor.
  ExpandSuggestion({
    this.bottomMargin,
    this.suggestion,
    this.suggestionInitialGlobalBounds,
    this.onSuggestionExpanded,
  });

  @override
  void start() {
    _expansionSimulation = new RK4SpringSimulation(
        initValue: 0.0, desc: _kExpansionSimulationDesc);
    _expansionSimulation.target = _kExpansionSimulationTarget;
    _opacitySimulation = new RK4SpringSimulation(
        initValue: _kOpacitySimulationTarget, desc: _kOpacitySimulationDesc);
    _opacitySimulation.target = _kOpacitySimulationTarget;
  }

  @override
  bool handleTick(double elapsedSeconds) {
    bool expansionWasDone = _expansionSimulation?.isDone ?? true;
    bool isDone = expansionWasDone;

    _opacitySimulation.elapseTime(elapsedSeconds);
    if (!_opacitySimulation.isDone) {
      isDone = false;
    } else if (_opacityProgress == 0.0) {
      _expansionSimulation = null;
    }

    if (!expansionWasDone) {
      // Tick the simulations.
      _expansionSimulation.elapseTime(elapsedSeconds);
      bool expansionIsDone = _expansionSimulation.isDone;

      // Notify that the story has come into focus.
      if (expansionIsDone && _expansionProgress == 1.0) {
        if (onSuggestionExpanded != null) {
          onSuggestionExpanded(suggestion);
        }
        _opacitySimulation.target = 0.0;
        isDone = false;
      }
    }

    return !isDone;
  }

  @override
  Widget build(BuildContext context, BoxConstraints constraints) {
    RenderBox box = context.findRenderObject();
    Offset topLeft = box.localToGlobal(Offset.zero);
    return new Stack(
      children: <Widget>[
        new Positioned(
          left: (suggestionInitialGlobalBounds.left - topLeft.x) *
              (1.0 - _expansionProgress),
          top: (suggestionInitialGlobalBounds.top - topLeft.y) *
              (1.0 - _expansionProgress),
          width: suggestionInitialGlobalBounds.width +
              (constraints.maxWidth - suggestionInitialGlobalBounds.width) *
                  _expansionProgress,
          height: suggestionInitialGlobalBounds.height +
              (constraints.maxHeight -
                      suggestionInitialGlobalBounds.height -
                      bottomMargin) *
                  _expansionProgress,
          child: new Opacity(
            opacity: _opacityProgress,
            child: new SuggestionWidget(suggestion: suggestion),
          ),
        ),
      ],
    );
  }

  double get _expansionProgress =>
      _expansionSimulation.value / _kExpansionSimulationTarget;

  double get _opacityProgress =>
      _opacitySimulation.value / _kOpacitySimulationTarget;
}
