// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'ticking_height_state.dart';

/// A [TickingHeightState] that changes its height to 0% of the child's height
/// via [hide] and 100% of the child's height via [show].
abstract class DeviceExtensionState<T extends StatefulWidget>
    extends TickingHeightState<T> {
  double parentHeight;

  Widget createWidget(BuildContext context);

  @override
  void initState() {
    super.initState();
    setHeight(0.0, force: true);
    minHeight = 0.0;
    maxHeight = 100.0;
  }

  void hide() {
    setHeight(0.0);
  }

  void show() {
    setHeight(100.0);
  }

  void toggle() => (active) ? hide() : show();

  @override
  Widget build(BuildContext context) {
    return new ClipRect(child: new Align(
        alignment: FractionalOffset.topCenter,
        heightFactor: height / 100.0,
        child: new OffStage(
            offstage: height == 0.0,
            child: new RepaintBoundary(child: createWidget(context)))));
  }

  bool get active => height > minHeight;
}
