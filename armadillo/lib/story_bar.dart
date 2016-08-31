// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/ticking_state.dart';

const double _kHeightInCardMode = 12.0;
const double _kHeightInFullScreenMode = 48.0;
const RK4SpringDescription _kHeightSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);

/// The bar to be shown at the top of a story.
class StoryBar extends StatefulWidget {
  final Color color;
  StoryBar({Key key, this.color}) : super(key: key);

  @override
  StoryBarState createState() => new StoryBarState();
}

class StoryBarState extends TickingState<StoryBar> {
  final RK4SpringSimulation _heightSimulation = new RK4SpringSimulation(
      initValue: _kHeightInCardMode, desc: _kHeightSimulationDesc);
  double _showHeight = _kHeightInCardMode;

  @override
  Widget build(BuildContext context) => new Container(
      height: _height,
      padding: new EdgeInsets.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: config.color),
      child: new Opacity(
          opacity: _opacity,
          child: new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Text('icons', style: new TextStyle(color: Colors.black)),
                new Text('title', style: new TextStyle(color: Colors.black)),
                new Text('menu', style: new TextStyle(color: Colors.black)),
              ])));

  @override
  bool handleTick(double elapsedSeconds) {
    if (_heightSimulation.isDone) {
      return false;
    }

    // Tick the height simulation.
    _heightSimulation.elapseTime(elapsedSeconds);

    return !_heightSimulation.isDone;
  }

  void show() {
    _heightSimulation.target = _showHeight;
    startTicking();
  }

  void hide() {
    _heightSimulation.target = 0.0;
    startTicking();
  }

  void maximize() {
    _showHeight = _kHeightInFullScreenMode;
    show();
  }

  void minimize() {
    _showHeight = _kHeightInCardMode;
    show();
  }

  double get _opacity => math.max(
      0.0,
      (_height - _kHeightInCardMode) /
          (_kHeightInFullScreenMode - _kHeightInCardMode));

  double get _height => _heightSimulation.value;
}
