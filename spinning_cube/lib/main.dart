// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'spinning_cube_gem.dart';

class _TickerProviderImpl implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => new Ticker(onTick);
}

const Duration _kCubeRotationAnimationPeriod = const Duration(
  milliseconds: 12000,
);

Future<Null> main() async {
  AnimationController controller = new AnimationController(
    vsync: new _TickerProviderImpl(),
    duration: _kCubeRotationAnimationPeriod,
  );
  runApp(
    new FractionallySizedBox(
      alignment: FractionalOffset.center,
      widthFactor: 0.75,
      heightFactor: 0.75,
      child: new Center(
        child: new SpinningCubeGem(
          controller: controller,
        ),
      ),
    ),
  );
  controller.repeat();
}
