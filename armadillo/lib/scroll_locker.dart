// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  Widget build(BuildContext context) => new ScrollConfiguration(
        delegate: new LockingScrollConfigurationDelegate(lock: _lockScrolling),
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

class LockingScrollConfigurationDelegate extends ScrollConfigurationDelegate {
  final bool lock;
  const LockingScrollConfigurationDelegate({this.lock: false});

  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  ExtentScrollBehavior createScrollBehavior() {
    return lock
        ? new LockedUnboundedBehavior(platform: platform)
        : new OverscrollWhenScrollableBehavior(platform: platform);
  }

  @override
  bool updateShouldNotify(LockingScrollConfigurationDelegate old) {
    return lock != old.lock;
  }
}

class LockedUnboundedBehavior extends UnboundedBehavior {
  LockedUnboundedBehavior({
    double contentExtent: double.INFINITY,
    double containerExtent: 0.0,
    TargetPlatform platform,
  })
      : super(
          contentExtent: contentExtent,
          containerExtent: containerExtent,
          platform: platform,
        );

  @override
  bool get isScrollable => false;
}
