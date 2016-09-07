// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'splash_painter.dart';
import 'suggestion_manager.dart';
import 'suggestion_widget.dart';

typedef void OnSuggestionExpanded(Suggestion suggestion);

const RK4SpringDescription _kSweepSimulationDesc =
    const RK4SpringDescription(tension: 150.0, friction: 50.0);
const double _kSweepSimulationTarget = 1000.0;
const RK4SpringDescription _kClearSimulationDesc =
    const RK4SpringDescription(tension: 150.0, friction: 50.0);
const double _kClearSimulationTarget = 1000.0;

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
  RK4SpringSimulation _sweepSimulation;
  RK4SpringSimulation _clearSimulation;
  bool _notified = false;

  /// Returns true if the overlay successfully initiates suggestion expansion.
  bool suggestionSelected({Suggestion suggestion, Rect globalBounds}) {
    if (_suggestion != null) {
      return false;
    }
    _notified = false;
    _suggestion = suggestion;
    _suggestionInitialGlobalBounds = globalBounds;
    _sweepSimulation =
        new RK4SpringSimulation(initValue: 0.0, desc: _kSweepSimulationDesc);
    _sweepSimulation.target = _kSweepSimulationTarget;
    _clearSimulation =
        new RK4SpringSimulation(initValue: 0.0, desc: _kClearSimulationDesc);
    _clearSimulation.target = 0.0;
    startTicking();
    return true;
  }

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        if (_suggestion == null || _clearIsDone) {
          return new Offstage(offstage: true);
        } else {
          RenderBox box = context.findRenderObject();
          Point topLeft = box.localToGlobal(Point.origin);
          Rect shiftedBounds = _suggestionInitialGlobalBounds
              .shift(new Offset(-topLeft.x, -topLeft.y));
          double splashRadius = math.sqrt(
              (shiftedBounds.center.x * shiftedBounds.center.x) +
                  (shiftedBounds.center.y * shiftedBounds.center.y));
          return new Stack(
            children: [
              new Positioned(
                left: shiftedBounds.left,
                top: shiftedBounds.top,
                width: shiftedBounds.width,
                height: shiftedBounds.height,
                child: new Offstage(
                  offstage: _sweepIsDone,
                  child: new SuggestionWidget(suggestion: _suggestion),
                ),
              ),
              new Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                bottom: 0.0,
                child: new Opacity(
                  opacity: _splashOpacity,
                  child: new CustomPaint(
                    painter: new SplashPainter(
                      innerSplashProgress: _clearProgress,
                      outerSplashProgress: _sweepProgress,
                      splashOrigin: shiftedBounds.center,
                      splashColor: _suggestion.themeColor,
                      splashRadius: splashRadius * 1.2,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      });

  @override
  bool handleTick(double elapsedSeconds) {
    bool isDone = true;

    _clearSimulation?.elapseTime(elapsedSeconds);
    if (!_clearIsDone) {
      isDone = false;
    } else {
      _suggestion = null;
      _suggestionInitialGlobalBounds = null;
      _sweepSimulation = null;
    }

    if (!_sweepIsDone) {
      // Tick the simulations.
      _sweepSimulation?.elapseTime(elapsedSeconds);

      // Notify that we've swept the screen.
      if (_sweepIsDone) {
        if (config.onSuggestionExpanded != null && !_notified) {
          config.onSuggestionExpanded(_suggestion);
          _notified = true;
        }
        _clearSimulation.target = _kClearSimulationTarget;
      }

      if (!_sweepIsDone) {
        isDone = false;
      }
    }

    return !isDone;
  }

  double get _sweepProgress =>
      (_sweepSimulation?.value ?? 1.0) / _kSweepSimulationTarget;

  double get _clearProgress =>
      (_clearSimulation?.value ?? 1.0) / _kClearSimulationTarget;

  double get _splashOpacity => (_sweepProgress / 0.7).clamp(0.0, 1.0);

  bool get _clearIsDone => _clearProgress > 0.7;

  bool get _sweepIsDone => _sweepProgress > 0.7;
}
