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

  int get listenerCount => _listeners.length;

  /// Should be called only by [ConfigManager] when [config] has changed.
  void notifyListeners() {
    version++;
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}

class InheritedConfigManagerWidget extends StatefulWidget {
  final ConfigManager configManager;
  final WidgetBuilder builder;

  InheritedConfigManagerWidget({this.configManager, this.builder});

  @override
  InheritedConfigManagerWidgetState createState() =>
      new InheritedConfigManagerWidgetState();
}

class InheritedConfigManagerWidgetState
    extends State<InheritedConfigManagerWidget> {
  @override
  void initState() {
    super.initState();
    config.configManager.addListener(_onChange);
  }

  @override
  void didUpdateConfig(InheritedConfigManagerWidget oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.configManager != oldConfig.configManager) {
      oldConfig.configManager.removeListener(_onChange);
      config.configManager.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    config.configManager.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => config.builder(context);

  void _onChange() {
    setState(() {});
  }
}

/// Base class for [InheritedWidget]s that provide a [ConfigManager].
class InheritedConfigManager extends InheritedWidget {
  final ConfigManager configManager;
  final int version;
  InheritedConfigManager({Key key, Widget child, ConfigManager configManager})
      : this.configManager = configManager,
        this.version = configManager.version,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedConfigManager oldWidget) =>
      (oldWidget.version != version);
}
