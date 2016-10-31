// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'config_manager.dart';

/// Tracks the [Size] of something, notifying listeners when it changes.
/// Using a [SizeManager] allows the [Size] it tracks to be passed down the
/// widget tree using an [InheritedSizeManager].
class SizeManager extends ConfigManager {
  Size _size;

  SizeManager(Size size) : _size = size ?? Size.zero;

  Size get size => _size;

  set size(Size size) {
    if (size != _size) {
      _size = size;
      notifyListeners();
    }
  }
}

class InheritedSizeManager extends StatelessWidget {
  final SizeManager sizeManager;
  final Widget child;

  InheritedSizeManager({this.sizeManager, this.child});

  @override
  Widget build(BuildContext context) => new InheritedConfigManagerWidget(
        configManager: sizeManager,
        builder: (BuildContext context) => new _InheritedSizeManager(
              sizeManager: sizeManager,
              child: child,
            ),
      );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [_InheritedSizeManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  /// If [rebuildOnChange] is true, the caller will be rebuilt upon changes
  /// to [SuggestionManager].
  static SizeManager of(BuildContext context, {bool rebuildOnChange: false}) {
    _InheritedSizeManager inheritedSuggestionManager = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(_InheritedSizeManager)
        : context.ancestorWidgetOfExactType(_InheritedSizeManager);
    return inheritedSuggestionManager?.configManager;
  }
}

class _InheritedSizeManager extends InheritedConfigManager {
  _InheritedSizeManager({
    Widget child,
    SizeManager sizeManager,
  })
      : super(child: child, configManager: sizeManager);
}
