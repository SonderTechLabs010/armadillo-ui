// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Shows a blinking line with the given [color] and [height] and blink
/// [duration].
class BlinkingCursor extends StatefulWidget {
  final Color color;
  final double height;
  final Duration duration;

  BlinkingCursor({this.color, this.duration, this.height});

  @override
  BlinkingCursorState createState() => new BlinkingCursorState();
}

/// [State] for [BlinkingCursor].
class BlinkingCursorState extends State<BlinkingCursor> {
  Timer _timer;
  bool _on = true;

  @override
  void initState() {
    super.initState();
    _timer = new Timer.periodic(config.duration, (_) {
      if (mounted) {
        setState(() {
          _on = !_on;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  Widget build(_) => new Container(
      width: 1.0,
      height: config.height,
      decoration: new BoxDecoration(
          backgroundColor: _on ? config.color : new Color(0x00000000)));
}
