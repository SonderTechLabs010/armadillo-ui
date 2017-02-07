// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'armadillo_drag_target.dart' show ArmadilloLongPressDraggable;

/// Used with [ArmadilloLongPressDraggable]s to display their drag feedback
/// widgets.
class ArmadilloOverlay extends StatefulWidget {
  ArmadilloOverlay({Key key}) : super(key: key);

  @override
  ArmadilloOverlayState createState() => new ArmadilloOverlayState();
}

class ArmadilloOverlayState extends State<ArmadilloOverlay> {
  final Set<WidgetBuilder> _builders = new Set<WidgetBuilder>();

  bool get hasBuilders => _builders.isNotEmpty;

  void addBuilder(WidgetBuilder builder) => setState(() {
        _builders.add(builder);
      });

  void removeBuilder(WidgetBuilder builder) => setState(() {
        _builders.remove(builder);
      });

  void update() => setState(() {});

  @override
  Widget build(BuildContext context) => new Stack(
        children: _builders
            .map(
              (WidgetBuilder builder) => builder(context),
            )
            .toList(),
      );
}
