// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/aggregate_listener_animation.dart';

typedef void OnQuickSettingsProgressChange(double quickSettingsProgress);

/// Fraction of the minimization animation which should be used for falling away
/// and sliding in of the user context and battery icon.
const double _kFallAwayDurationFraction = 0.35;

/// The distance above the lowest point we can scroll down to when
/// [scrollOffset] is 0.0.
const double _kRestingDistanceAboveLowestPoint = 40.0;

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
  final VoidCallback onButtonTap;
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
      this.onButtonTap,
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

class NowState extends State<Now> {
  /// The controller for the minimization animation.
  final AnimationController _minimizationAnimation =
      new AnimationController(duration: const Duration(milliseconds: 500));

  /// The controller for the quick settings animation.
  final AnimationController _quickSettingsAnimation =
      new AnimationController(duration: const Duration(milliseconds: 500));

  /// As [Now] minimizes the user image goes from bottom center aligned to
  /// center aligned as it shrinks.
  final Tween<FractionalOffset> _userImageAlignment =
      new Tween<FractionalOffset>(
          begin: FractionalOffset.bottomCenter, end: FractionalOffset.center);
  CurvedAnimation _curvedMinimizationAnimation;
  CurvedAnimation _curvedQuickSettingsAnimation;

  NowState() {
    _curvedMinimizationAnimation = new CurvedAnimation(
        parent: _minimizationAnimation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped);
    _curvedQuickSettingsAnimation = new CurvedAnimation(
        parent: _quickSettingsAnimation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped);
  }

  @override
  void initState() {
    super.initState();
    if (config.onQuickSettingsProgressChange != null) {
      _curvedQuickSettingsAnimation.addListener(() {
        config
            .onQuickSettingsProgressChange(_curvedQuickSettingsAnimation.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
      animation: new AggregateListenerAnimation(
          children: [_minimizationAnimation, _quickSettingsAnimation]),
      builder: (BuildContext context, Widget child) => new GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (_minimizationAnimation.status != AnimationStatus.completed &&
                _minimizationAnimation.status != AnimationStatus.forward) {
              if (_quickSettingsAnimation.status != AnimationStatus.completed &&
                  _quickSettingsAnimation.status != AnimationStatus.forward) {
                showQuickSettings();
              } else {
                hideQuickSettings();
              }
            }
          },
          child: new ConstrainedBox(
              constraints: new BoxConstraints.tightFor(
                  height: _nowHeight + math.max(0.0, _scrollOffsetDelta)),
              child: new Padding(
                  padding: new EdgeInsets.symmetric(horizontal: 8.0),
                  child: new Stack(children: [
                    // Quick Settings background.
                    new Positioned(
                        left: 0.0,
                        right: 0.0,
                        bottom: _quickSettingsBackgroundBottomOffset,
                        child: new Center(
                            child: new Container(
                                height: _quickSettingsBackgroundHeight,
                                width: _quickSettingsBackgroundWidth,
                                decoration: new BoxDecoration(
                                    backgroundColor: new Color(0xFFFFFFFF),
                                    borderRadius: new BorderRadius.circular(
                                        _quickSettingsBackgroundBorderRadius))))),

                    // Quick Settings.
                    new Positioned(
                        left: 0.0,
                        right: 0.0,
                        bottom: _quickSettingsBottomOffset,
                        child: new ConstrainedBox(
                            constraints: new BoxConstraints.tightFor(
                                width: _quickSettingsWidth,
                                height: _quickSettingsHeight),
                            child: new Opacity(
                                opacity: _quickSettingsSlideUpProgress,
                                child: config.quickSettings))),

                    // User's Image.
                    new Positioned(
                        left: 0.0,
                        right: 0.0,
                        top: 0.0,
                        bottom: _userImageBottomOffset,
                        child: new Align(
                            alignment: _userImageAlignment
                                .evaluate(_curvedMinimizationAnimation),
                            child: new Stack(children: [
                              new Opacity(
                                  opacity: _curvedQuickSettingsAnimation.value,
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
                            ]))),

                    // User Context Text when maximized.
                    new Positioned(
                        left: 0.0,
                        right: 0.0,
                        bottom: _contextTextBottomOffset,
                        child: new Center(
                            child: new Opacity(
                                opacity: _fallAwayOpacity,
                                child: config.userContextMaximized))),

                    // Important Information when maximized.
                    new Positioned(
                        left: 0.0,
                        right: 0.0,
                        bottom: _batteryBottomOffset,
                        child: new Center(
                            child: new Opacity(
                                opacity: _fallAwayOpacity,
                                child: config.importantInfoMaximized))),

                    // User Context Text when minimized.
                    new Positioned(
                        bottom: 0.0,
                        left: _slideInDistance,
                        right: 0.0,
                        height: config.minHeight,
                        child: new Align(
                            alignment: FractionalOffset.centerLeft,
                            child: new Opacity(
                                opacity: _slideInProgress,
                                child: config.userContextMinimized))),

                    // Important Information when minimized.
                    new Positioned(
                        bottom: 0.0,
                        left: 0.0,
                        right: _slideInDistance,
                        height: config.minHeight,
                        child: new Align(
                            alignment: FractionalOffset.centerRight,
                            child: new Opacity(
                                opacity: _slideInProgress,
                                child: config.importantInfoMinimized))),

                    // Return To Origin Button.  This button is only enabled
                    // when we're nearly fully minimized.
                    new OffStage(
                        offstage: _buttonTapDisabled,
                        child: new Center(
                            child: new GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: config.onButtonTap,
                                child: new Container(
                                    width: config.minHeight,
                                    height: config.minHeight))))
                  ])))));

  void minimize() {
    if (_minimizationAnimation.status != AnimationStatus.completed &&
        _minimizationAnimation.status != AnimationStatus.forward) {
      _minimizationAnimation.forward();
    }
  }

  void maximize() {
    if (_minimizationAnimation.status != AnimationStatus.dismissed &&
        _minimizationAnimation.status != AnimationStatus.reverse) {
      _minimizationAnimation.reverse();
    }
  }

  void showQuickSettings() {
    if (_quickSettingsAnimation.status != AnimationStatus.completed &&
        _quickSettingsAnimation.status != AnimationStatus.forward) {
      _quickSettingsAnimation.forward();
    }
  }

  void hideQuickSettings() {
    if (_quickSettingsAnimation.status != AnimationStatus.dismissed &&
        _quickSettingsAnimation.status != AnimationStatus.reverse) {
      _quickSettingsAnimation.reverse();
    }
  }

  bool get _buttonTapDisabled =>
      _curvedMinimizationAnimation.value < (1.0 - _kFallAwayDurationFraction);

  double get _nowHeight =>
      config.minHeight +
      ((config.maxHeight - config.minHeight) *
          (1.0 - _curvedMinimizationAnimation.value)) +
      config.quickSettingsHeightBump * _quickSettingsAnimation.value;

  double get _userImageSize =>
      100.0 - (88.0 * _curvedMinimizationAnimation.value);

  double get _userImageBorderWidth =>
      2.0 + (4.0 * _curvedMinimizationAnimation.value);

  double get _userImageBottomOffset =>
      160.0 * (1.0 - _curvedMinimizationAnimation.value) +
      _quickSettingsRaiseDistance +
      _scrollOffsetDelta +
      _restingDistanceAboveLowestPoint;

  double get _contextTextBottomOffset =>
      110.0 +
      _fallAwayDistance +
      _quickSettingsRaiseDistance +
      _scrollOffsetDelta +
      _restingDistanceAboveLowestPoint;

  double get _batteryBottomOffset =>
      70.0 +
      _fallAwayDistance +
      _quickSettingsRaiseDistance +
      _scrollOffsetDelta +
      _restingDistanceAboveLowestPoint;

  double get _quickSettingsBackgroundBorderRadius =>
      50.0 - 46.0 * _curvedQuickSettingsAnimation.value;

  double get _quickSettingsBackgroundWidth =>
      424.0 *
      _curvedQuickSettingsAnimation.value *
      (1.0 - _curvedMinimizationAnimation.value);

  double get _quickSettingsBackgroundHeight =>
      (config.quickSettingsHeightBump + 80.0) *
      _curvedQuickSettingsAnimation.value *
      (1.0 - _curvedMinimizationAnimation.value);

  double get _restingDistanceAboveLowestPoint =>
      _kRestingDistanceAboveLowestPoint *
      (1.0 - _curvedQuickSettingsAnimation.value) *
      (1.0 - _curvedMinimizationAnimation.value);

  // TODO(apwilson): Make this calculation sane.  It appears it should depend
  // upon config.quickSettingsHeightBump.
  double get _quickSettingsBackgroundBottomOffset =>
      _userImageBottomOffset +
      (_userImageSize / 2.0) -
      _quickSettingsBackgroundHeight +
      (_userImageSize / 3.0) * (1.0 - _curvedQuickSettingsAnimation.value) +
      (5.0 / 3.0 * _userImageSize * _curvedMinimizationAnimation.value);

  double get _quickSettingsWidth => 400.0 - 32.0;
  double get _quickSettingsHeight =>
      config.quickSettingsHeightBump + 80.0 - 32.0;
  double get _quickSettingsBottomOffset =>
      136.0 + (16.0 * _quickSettingsSlideUpProgress);

  double get _fallAwayDistance => 10.0 * (1.0 - _fallAwayProgress);

  double get _fallAwayOpacity => (1.0 - _fallAwayProgress);

  double get _slideInDistance => 10.0 * (1.0 - _slideInProgress);

  double get _quickSettingsRaiseDistance =>
      config.quickSettingsHeightBump * _curvedQuickSettingsAnimation.value;

  double get _scrollOffsetDelta =>
      (math.max(
                  -_kRestingDistanceAboveLowestPoint,
                  (-1.0 * config.scrollOffset / 3.0) *
                      (1.0 - _curvedMinimizationAnimation.value) *
                      (1.0 - _curvedQuickSettingsAnimation.value)) *
              1000.0)
          .truncateToDouble() /
      1000.0;

  /// We fall away the context text and important information for the initial
  /// portion of the minimization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get _fallAwayProgress => (_minimizationAnimation.status ==
              AnimationStatus.forward
          ? Curves.fastOutSlowIn
          : Curves.fastOutSlowIn.flipped)
      .transform(math.min(
          1.0, (_minimizationAnimation.value / _kFallAwayDurationFraction)));

  /// We slide in the context text and important information for the final
  /// portion of the minimization animation as determined by
  /// [_kFallAwayDurationFraction].
  double get _slideInProgress => (_minimizationAnimation.status ==
              AnimationStatus.forward
          ? Curves.fastOutSlowIn
          : Curves.fastOutSlowIn.flipped)
      .transform(math.max(
          0.0,
          ((_minimizationAnimation.value - (1.0 - _kFallAwayDurationFraction)) /
              _kFallAwayDurationFraction)));

  /// We slide up and fade in the quick settings for the final portion of the
  /// quick settings animation as determined by [_kFallAwayDurationFraction].
  double get _quickSettingsSlideUpProgress =>
      (_curvedQuickSettingsAnimation.status == AnimationStatus.forward
              ? Curves.fastOutSlowIn
              : Curves.fastOutSlowIn.flipped)
          .transform(math.max(
              0.0,
              ((_curvedQuickSettingsAnimation.value -
                      (1.0 - _kFallAwayDurationFraction)) /
                  _kFallAwayDurationFraction)));
}
