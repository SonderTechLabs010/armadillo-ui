// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

class LongHoverDetector extends StatefulWidget {
  final bool hovering;
  final VoidCallback onLongHover;
  final Widget child;

  LongHoverDetector({this.hovering, this.onLongHover, this.child});

  @override
  LongHoverDetectorState createState() => new LongHoverDetectorState();
}

class LongHoverDetectorState extends State<LongHoverDetector> {
  Timer _hoverTimer;
  @override
  void initState() {
    super.initState();
    if (config.hovering) {
      _startTimer();
    }
  }

  @override
  void didUpdateConfig(LongHoverDetector oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.hovering && _hoverTimer == null) {
      _startTimer();
    }
    if (!config.hovering) {
      _cancelTimer();
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => config.child;

  void _startTimer() {
    _hoverTimer = new Timer(const Duration(milliseconds: 1500), () {
      config.onLongHover?.call();
    });
  }

  void _cancelTimer() {
    _hoverTimer?.cancel();
    _hoverTimer = null;
  }
}
