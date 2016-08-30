// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// The bar to be shown at the top of a story.
class StoryBar extends StatelessWidget {
  final Color color;
  final double focusProgress;
  StoryBar({this.color, this.focusProgress});

  @override
  Widget build(BuildContext context) => new Container(
      height: 12.0 + 36.0 * focusProgress,
      padding: new EdgeInsets.symmetric(horizontal: 8.0),
      decoration: new BoxDecoration(backgroundColor: color),
      child: new Opacity(
          opacity: focusProgress,
          child: new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Text('icons', style: new TextStyle(color: Colors.black)),
                new Text('title', style: new TextStyle(color: Colors.black)),
                new Text('menu', style: new TextStyle(color: Colors.black)),
              ])));
}
