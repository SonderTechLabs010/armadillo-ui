// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Base class for classes that provide configuration data via
/// [InheritedWidget]s.
abstract class ConfigManager {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  int version = 0;

  /// Should be called only by those who instantiate
  /// [InheritedConfigManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when [config] changes, use
  /// [InheritedConfigManager.of].
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Should be called only by those who instantiate
  /// [InheritedConfigManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when [config] changes, use
  /// [InheritedConfigManager.of].
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Should be called only by [ConfigManager] when [config] has changed.
  void notifyListeners() {
    version++;
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}

/// Base class for [InheritedWidget]s that provide a [ConfigManager].
class InheritedConfigManager<T extends ConfigManager> extends InheritedWidget {
  final T configManager;
  final int version;
  InheritedConfigManager({Key key, Widget child, T configManager})
      : this.configManager = configManager,
        this.version = configManager.version,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedConfigManager oldWidget) =>
      (oldWidget.version != version);
}
