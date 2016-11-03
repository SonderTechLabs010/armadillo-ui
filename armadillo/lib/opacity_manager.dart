// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'config_manager.dart';

/// Tracks the [Opacity] of widget tree, notifying listeners when it changes.
/// Using an [OpacityManager] allows the [opacity] it tracks to be passed down
/// the widget tree using an [InheritedOpacityManager].
class OpacityManager extends ConfigManager {
  double _opacity;

  OpacityManager(double opacity) : _opacity = opacity ?? 1.0;

  double get opacity => _opacity;

  set opacity(double opacity) {
    if (opacity != _opacity) {
      _opacity = opacity;
      notifyListeners();
    }
  }
}

class InheritedOpacityManager extends StatelessWidget {
  final OpacityManager opacityManager;
  final Widget child;

  InheritedOpacityManager({this.opacityManager, this.child});

  @override
  Widget build(BuildContext context) => new InheritedConfigManagerWidget(
        configManager: opacityManager,
        builder: (BuildContext context) => new _InheritedOpacityManager(
              opacityManager: opacityManager,
              child: child,
            ),
      );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [_InheritedOpacityManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  /// If [rebuildOnChange] is true, the caller will be rebuilt upon changes
  /// to [OpacityManager].
  static OpacityManager of(BuildContext context,
      {bool rebuildOnChange: false}) {
    _InheritedOpacityManager inheritedOpacityManager = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(_InheritedOpacityManager)
        : context.ancestorWidgetOfExactType(_InheritedOpacityManager);
    return inheritedOpacityManager?.configManager;
  }
}

class _InheritedOpacityManager extends InheritedConfigManager {
  _InheritedOpacityManager({
    Widget child,
    OpacityManager opacityManager,
  })
      : super(child: child, configManager: opacityManager);
}

typedef Widget InheritedOpacityWidgetBuilder(
  BuildContext context,
  Widget child,
  double opacity,
);

class InheritedOpacityWidget extends StatelessWidget {
  final InheritedOpacityWidgetBuilder builder;
  final Widget child;
  InheritedOpacityWidget({this.builder, this.child});

  @override
  Widget build(BuildContext context) => builder(
        context,
        child,
        InheritedOpacityManager.of(context, rebuildOnChange: true).opacity,
      );
}
