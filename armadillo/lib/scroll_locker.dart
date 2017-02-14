// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Locks and unlocks scrolling in its [child] and its decendants.
class ScrollLocker extends StatefulWidget {
  final Widget child;

  ScrollLocker({Key key, this.child}) : super(key: key);

  @override
  ScrollLockerState createState() => new ScrollLockerState();
}

class ScrollLockerState extends State<ScrollLocker> {
  /// When true, list scrolling is disabled.
  bool _lockScrolling = false;

  @override
  Widget build(BuildContext context) => new ScrollConfiguration2(
        behavior: new LockingScrollBehavior(lock: _lockScrolling),
        child: config.child,
      );

  void lock() {
    setState(() {
      _lockScrolling = true;
    });
  }

  void unlock() {
    setState(() {
      _lockScrolling = false;
    });
  }
}

class LockingScrollBehavior extends ScrollBehavior2 {
  final bool lock;
  const LockingScrollBehavior({this.lock: false});

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => lock
      ? const LockedScrollPhysics(parent: const BouncingScrollPhysics())
      : const BouncingScrollPhysics();

  @override
  bool shouldNotify(LockingScrollBehavior old) {
    return lock != old.lock;
  }
}

class LockedScrollPhysics extends ScrollPhysics {
  const LockedScrollPhysics({ScrollPhysics parent}) : super(parent);

  @override
  LockedScrollPhysics applyTo(ScrollPhysics parent) =>
      new LockedScrollPhysics(parent: parent);

  @override
  Simulation createBallisticSimulation(
    ScrollPosition position,
    double velocity,
  ) =>
      null;

  @override
  double applyPhysicsToUserOffset(ScrollPosition position, double offset) =>
      0.0;
}
