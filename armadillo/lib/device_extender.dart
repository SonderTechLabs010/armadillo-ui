// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Used to allow [deviceExtensions] to push [child] up from the bottom (by
/// shrinking [child]'s height) when they grow in size.
///
/// An example of a device extension would be an IME or some other button bar
/// that should appear to be an extension of device hardware rather than a
/// software UI.
class DeviceExtender extends StatelessWidget {
  final Widget child;
  final List<Widget> deviceExtensions;

  DeviceExtender({this.child, this.deviceExtensions: const <Widget>[]});

  @override
  Widget build(BuildContext context) {
    final columnChildren = new List<Widget>();
    columnChildren.add(new Flexible(child: child));
    columnChildren.addAll(deviceExtensions);
    return new Column(children: columnChildren);
  }
}
