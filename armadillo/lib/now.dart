// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

typedef void OnQuickSettingsProgressChange(double quickSettingsProgress);

/// Fraction of the minimization animation which should be used for falling away
/// and sliding in of the user context and battery icon.
const double _kFallAwayDurationFraction = 0.35;

/// The distance above the lowest point we can scroll down to when
/// [scrollOffset] is 0.0.
const double _kRestingDistanceAboveLowestPoint = 80.0;

/// Shows the user, the user's context, and important settings.  When minimized
/// also shows an affordance for seeing missed interruptions.
class Now extends StatefulWidget {
  final double minHeight;
  final double maxHeight;

  /// [scrolloffset] effects the bottom padding of the user and text elements
  /// as well as the overall height of [Now] while maximized.
  final double scrollOffset;
  final double quickSettingsHeightBump;
  final OnQuickSettingsProgressChange onQuickSettingsProgressChange;
  final VoidCallback onQuickSettingsOverlayButtonTap;
  final VoidCallback onReturnToOriginButtonTap;
  final VoidCallback onInterruptionsOverlayButtonTap;

  /// [onBarVerticalDragUpdate] and [onBarVerticalDragEnd] will be called only
  /// when a vertical drag occurs on [Now] when in its fully minimized bar
  /// state.
  final GestureDragUpdateCallback onBarVerticalDragUpdate;
  final GestureDragEndCallback onBarVerticalDragEnd;

  final Widget user;
  final Widget userContextMaximized;
  final Widget userContextMinimized;
  final Widget importantInfoMaximized;
  final Widget importantInfoMinimized;
  final Widget quickSettings;

  Now(
      {Key key,
      this.minHeight,
      this.maxHeight,
      this.scrollOffset,
      this.quickSettingsHeightBump,
      this.onQuickSettingsProgressChange,
      this.onQuickSettingsOverlayButtonTap,
      this.onReturnToOriginButtonTap,
      this.onInterruptionsOverlayButtonTap,
      this.onBarVerticalDragUpdate,
      this.onBarVerticalDragEnd,
      this.user,
      this.userContextMaximized,
      this.userContextMinimized,
      this.importantInfoMaximized,
      this.importantInfoMinimized,
      this.quickSettings})
      : super(key: key);

  @override
  NowState createState() => new NowState();
}

/// Spring description used by the minimization and quick settings reveal
/// simulations.
const RK4SpringDescription _kSimulationDesc =
    const RK4SpringDescription(tension: 600.0, friction: 50.0);

const double _kMinimizationSimulationTarget = 400.0;
const double _kQuickSettingsSimulationTarget = 100.0;

class NowState extends TickingState<Now> {
  /// The simulation for the minimization to a bar.
  final RK4SpringSimulation _minimizationSimulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kSimulationDesc);

  /// The simulation for the inline quick settings reveal.
  final RK4SpringSimulation _quickSettingsSimulation =
      new RK4SpringSimulation(initValue: 0.0, desc: _kSimulationDesc);

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          new Container(
              margin: new EdgeInsets.only(
                  top: math.max(0.0, constraints.maxHeight - _nowHeight)),
              child: new Stack(children: [
                // Quick Settings Background.
                new Positioned(
                    left: 8.0,
                    right: 8.0,
                    top: _quickSettingsTopOffset,
                    child: new Center(
                        child: new Container(
                            height: _quickSettingsBackgroundHeight,
                            width: _quickSettingsBackgroundWidth,
                            decoration: new BoxDecoration(
                                backgroundColor: new Color(0xFFFFFFFF),
                                borderRadius: new BorderRadius.circular(
                                    _quickSettingsBackgroundBorderRadius))))),

                // User Image, User Context Text, and Important Information when maximized.
                new Positioned(
                    left: 8.0,
                    right: 8.0,
                    top: _userImageTopOffset,
                    child: new Center(
                        child: new Column(children: [
                      new Stack(children: [
                        new Opacity(
                            opacity: _quickSettingsProgress,
                            child: new Container(
                                width: _userImageSize,
                                height: _userImageSize,
                                decoration: new BoxDecoration(
                                    boxShadow: kElevationToShadow[12],
                                    shape: BoxShape.circle))),
                        new ClipOval(
                            child: new Container(
                                width: _userImageSize,
                                height: _userImageSize,
                                foregroundDecoration: new BoxDecoration(
                                    border: new Border.all(
                                        color: new Color(0xFFFFFFFF),
                                        width: _userImageBorderWidth),
                                    shape: BoxShape.circle),
                                child: config.user))
                      ]),
                      new Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: new Opacity(
                              opacity: _fallAwayOpacity,
                              child: config.userContextMaximized)),
                      new Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: new Opacity(
                              opacity: _fallAwayOpacity,
                              child: config.importantInfoMaximized)),
                    ]))),

                // User Context Text and Important Information when minimized.
                new Align(
                    alignment: FractionalOffset.bottomCenter,
                    child: new Container(
                        height: config.minHeight,
                        padding: new EdgeInsets.symmetric(
                            horizontal: 8.0 + _slideInDistance),
                        child: new Opacity(
                            opacity: _slideInProgress,
                            child: new Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  config.userContextMinimized,
                                  config.importantInfoMinimized
                                ])))),

                // Button bar.  These buttons are only enabled when we're nearly
                // fully minimized.
                new Offstage(
                    offstage: _buttonTapDisabled,
                    child: new GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: config.onBarVerticalDragUpdate,
                        onVerticalDragEnd: config.onBarVerticalDragEnd,
                        child: new Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Toggle Quick Settings Overlay Button.
                              new Flexible(
                                  flex: 1,
                                  child: new GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: config
                                          .onQuickSettingsOverlayButtonTap)),

                              // Return To Origin Button.
                              new Flexible(
                                  flex: 2,
                                  child: new GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: config.onReturnToOriginButtonTap)),

                              // Toggle Interruptions Overlay Button.
                              new Flexible(
                                  flex: 1,
                                  child: new GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: config
                                          .onInterruptionsOverlayButtonTap))
                            ]))),

                // Inline Quick Settings Toggle.
                new Positioned(
                    top: config.scrollOffset * 2.0 / 3.0,
                    bottom: 0.0,
                    left: 0.0,
                    right: 0.0,
                    child: new Offstage(
                        offstage: !_buttonTapDisabled,
                        child: new GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () {
                              if (!_revealingQuickSettings) {
                                showQuickSettings();
                              } else {
                                hideQuickSettings();
                              }
                            }))),

                // Quick Settings.
                new Positioned(
                    left: 8.0,
                    right: 8.0,
                    top: _quickSettingsTopOffset +
                        32.0 * (1.0 - _quickSettingsSlideUpProgress) +
                        128.0,
                    child: new Center(
                        child: new Container(
                            height: math.max(
                                0.0, _quickSettingsBackgroundHeight - 128.0),
                            width: _quickSettingsBackgroundWidth,
                            child: new Opacity(
                                opacity: _quickSettingsSlideUpProgress,
                                child: config.quickSettings)))),
              ])));

  @override
  bool handleTick(double elapsedSeconds) {
    bool continueTicking = false;

    // Tick the minimization simulation.
    _minimizationSimulation.elapseTime(elapsedSeconds);
    if (!_minimizationSimulation.isDone) {
      continueTicking = true;
    }

    // Tick the quick settings simulation.
    if (!_quickSettingsSimulation.isDone) {
      _quickSettingsSimulation.elapseTime(elapsedSeconds);
      if (!_quickSettingsSimulation.isDone) {
        continueTicking = true;
      }
      if (config.onQuickSettingsProgressChange != null) {
        config.onQuickSettingsProgressChange(_quickSettingsProgress);
      }
    }

    return continueTicking;
  }

  void minimize() {
    if (!_minimizing) {
      _minimizationSimulation.target = _kMinimizationSimulationTarget;
      startTicking();
    }
  }

  void maximize() {
    if (_minimizing) {
      _minimizationSimulation.target = 0.0;
      startTicking();
    }
  }

  void showQuickSettings() {
    if (!_revealingQuickSettings) {
      _quickSettingsSimulation.target = _kQuickSettingsSimulationTarget;
      startTicking();
    }
  }

  void hideQuickSettings() {
    if (_revealingQuickSettings) {
      _quickSettingsSimulation.target = 0.0;
      startTicking();
    }
  }

  double get _quickSettingsProgress =>
      _quickSettingsSimulation.value / _kQuickSettingsSimulationTarget;

  double get _minimizationProgress =>
      _minimizationSimulation.value / _kMinimizationSimulationTarget;

  bool get _minimizing =>
      _minimizationSimulation.target == _kMinimizationSimulationTarget;

  bool get _revealingQuickSettings =>
      _quickSettingsSimulation.target == _kQuickSettingsSimulationTarget;

  bool get _buttonTapDisabled =>
      _minimizationProgress < (1.0 - _kFallAwayDurationFraction);

  double get _nowHeight => math.max(
      config.minHeight,
      config.minHeight +
          ((config.maxHeight - config.minHeight) *
              (1.0 - _minimizationProgress)) +
          _quickSettingsRaiseDistance +
          _scrollOffsetDelta);

  double get _userImageSize => 100.0 - (88.0 * _minimizationProgress);

  double get _userImageBorderWidth => 2.0 + (4.0 * _minimizationProgress);

  double get _userImageTopOffset =>
      (100.0 + _quickSettingsRaiseDistance - _quickSettingsProgress * 200.0) *
          (1.0 - _minimizationProgress) +
      ((config.minHeight - _userImageSize) / 2.0) * _minimizationProgress;

  double get _quickSettingsTopOffset =>
      _userImageTopOffset + ((_userImageSize / 2.0) * _quickSettingsProgress);

  double get _quickSettingsBackgroundBorderRadius =>
      50.0 - 46.0 * _quickSettingsProgress;

  double get _quickSettingsBackgroundWidth =>
      424.0 * _quickSettingsProgress * (1.0 - _minimizationProgress);

  double get _quickSettingsBackgroundHeight =>
      (config.quickSettingsHeightBump + 80.0) *
      _quickSettingsProgress *
      (1.0 - _minimizationProgress);

  double get _fallAwayOpacity => (1.0 - _fallAwayProgress);

  double get _slideInDistance => 10.0 * (1.0 - _slideInProgress);

  double get _quickSettingsRaiseDistance =>
      config.quickSettingsHeightBump * _quickSettingsProgress;

  double get _scrollOffsetDelta =>
      (math.max(
                  -_kRestingDistanceAboveLowestPoint,
                  (-1.0 * config.scrollOffset / 3.0) *
                      (1.0 - _minimizationProgress) *
                      (1.0 - _quickSettingsProgress)) *
              1000.0)
          .truncateToDouble() /
      1000.0;

  /// We fall away the context text and important information for the initial
  /// portion of the minimization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get _fallAwayProgress =>
      math.min(1.0, (_minimizationProgress / _kFallAwayDurationFraction));

  /// We slide in the context text and important information for the final
  /// portion of the minimization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get _slideInProgress =>
      (((_minimizationProgress - (1.0 - _kFallAwayDurationFraction)) /
              _kFallAwayDurationFraction))
          .clamp(0.0, 1.0);

  /// We slide up and fade in the quick settings for the final portion of the
  /// quick settings animation as determined by [_kFallAwayDurationFraction].
  double get _quickSettingsSlideUpProgress => math.max(
      0.0,
      ((_quickSettingsProgress - (1.0 - _kFallAwayDurationFraction)) /
          _kFallAwayDurationFraction));
}
