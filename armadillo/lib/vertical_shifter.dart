// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Shifts by [verticalShift] as [VerticalShifterState.shiftProgress] goes to
/// 1.0.
class VerticalShifter extends StatefulWidget {
  final double verticalShift;
  final Widget child;

  VerticalShifter({Key key, this.verticalShift, this.child}) : super(key: key);

  @override
  VerticalShifterState createState() => new VerticalShifterState();
}

class VerticalShifterState extends State<VerticalShifter> {
  double _shiftProgress = 0.0;

  /// The distance to shift up.
  set shiftProgress(double shiftProgress) {
    _shiftProgress = shiftProgress;
  }

  @override
  Widget build(BuildContext context) => new Stack(
        children: [
          // Recent List.
          new Positioned(
            left: 0.0,
            right: 0.0,
            top: -_shiftAmount,
            bottom: _shiftAmount,
            child: config.child,
          ),
        ],
      );

  double get _shiftAmount => _shiftProgress * config.verticalShift;
}
