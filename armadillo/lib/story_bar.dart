// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';
import 'package:sysui_widgets/three_column_aligned_layout_delegate.dart';
import 'package:sysui_widgets/ticking_state.dart';

import 'focusable_story.dart';

const RK4SpringDescription _kHeightSimulationDesc =
    const RK4SpringDescription(tension: 450.0, friction: 50.0);
const double _kPartMargin = 8.0;

/// The bar to be shown at the top of a story.
class StoryBar extends StatefulWidget {
  final Story story;
  final double minimizedHeight;
  final double maximizedHeight;
  StoryBar({Key key, this.story, this.minimizedHeight, this.maximizedHeight})
      : super(key: key);

  @override
  StoryBarState createState() => new StoryBarState();
}

class StoryBarState extends TickingState<StoryBar> {
  RK4SpringSimulation _heightSimulation;
  double _showHeight;

  @override
  void initState() {
    super.initState();
    _heightSimulation = new RK4SpringSimulation(
        initValue: config.minimizedHeight, desc: _kHeightSimulationDesc);
    _showHeight = config.minimizedHeight;
  }

  @override
  Widget build(BuildContext context) => new Container(
        height: _height,
        padding: new EdgeInsets.symmetric(horizontal: 8.0),
        decoration: new BoxDecoration(backgroundColor: config.story.themeColor),
        child: new OverflowBox(
          minHeight: config.maximizedHeight,
          maxHeight: config.maximizedHeight,
          alignment: FractionalOffset.topCenter,
          child: new Opacity(
            opacity: _opacity,
            child: new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: new CustomMultiChildLayout(
                delegate: new ThreeColumnAlignedLayoutDelegate(
                  partMargin: _kPartMargin,
                ),
                children: [
                  new LayoutId(
                    id: ThreeColumnAlignedLayoutDelegateParts.left,
                    child: new Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: config.story.icons
                          .map((WidgetBuilder builder) => builder(context))
                          .toList(),
                    ),
                  ),
                  new LayoutId(
                    id: ThreeColumnAlignedLayoutDelegateParts.center,
                    child: new Text(
                      config.story.title.toUpperCase(),
                      style: new TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                      ),
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  new LayoutId(
                    id: ThreeColumnAlignedLayoutDelegateParts.right,
                    child: new Icon(
                      Icons.account_circle,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

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
    _showHeight = config.maximizedHeight;
    show();
  }

  void minimize() {
    _showHeight = config.minimizedHeight;
    show();
  }

  double get _opacity => math.max(
      0.0,
      (_height - config.minimizedHeight) /
          (config.maximizedHeight - config.minimizedHeight));

  double get _height => _heightSimulation.value;
}
