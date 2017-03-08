// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Base class for classes that provide data via [InheritedWidget]s.
abstract class Model {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  int version = 0;

  /// [listener] will be notified when the model changes.
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// [listener] will no longer be notified when the model changes.
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  int get listenerCount => _listeners.length;

  /// Should be called only by [Model] when the model has changed.
  void notifyListeners() {
    // We schedule a microtask as it's not uncommon for changes that trigger
    // listener notifications to occur in a build step and for listeners to
    // call setState.  Its a big no-no to setState during build so we schedule
    // for them to happen later.
    // TODO(apwilson): This is a bad-flutter-code-smell. Eliminate the need for
    // this scheduleMicrotask.
    scheduleMicrotask(() {
      version++;
      _listeners.toList().forEach((VoidCallback listener) => listener());
    });
  }
}

/// Finds a [Model].  This class is necessary as templated classes are relified
/// but static templated functions are not.
class ModelFinder<T extends Model> {
  /// Returns the [Model] of type [T] of the closest ancestor [ScopedModel].
  ///
  /// [Widget]s who call [of] with a [rebuildOnChange] of true will be rebuilt
  /// whenever there's a change to the returned model.
  T of(BuildContext context, {bool rebuildOnChange: false}) {
    final Type type = new _InheritedModel<T>.forRuntimeType().runtimeType;
    Widget widget = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(type)
        : context.ancestorWidgetOfExactType(type);
    return (widget is _InheritedModel<T>) ? widget.model : null;
  }
}

/// Allows the given [model] to be accessed by [child] or any of its decendants
/// using [ModelFinder].
class ScopedModel<T extends Model> extends StatelessWidget {
  final T model;
  final Widget child;

  ScopedModel({this.model, this.child});

  @override
  Widget build(BuildContext context) => new _ModelListener(
        model: model,
        builder: (BuildContext context) => new _InheritedModel<T>(
              model: model,
              child: child,
            ),
      );
}

/// Listens to [model] and calls [builder] whenever [model] changes.
class _ModelListener extends StatefulWidget {
  final Model model;
  final WidgetBuilder builder;

  _ModelListener({this.model, this.builder});

  @override
  _ModelListenerState createState() => new _ModelListenerState();
}

class _ModelListenerState extends State<_ModelListener> {
  @override
  void initState() {
    super.initState();
    config.model.addListener(_onChange);
  }

  @override
  void didUpdateConfig(_ModelListener oldConfig) {
    super.didUpdateConfig(oldConfig);
    if (config.model != oldConfig.model) {
      oldConfig.model.removeListener(_onChange);
      config.model.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    config.model.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => config.builder(context);

  void _onChange() => setState(() {});
}

/// Provides [model] to its [child] [Widget] tree via [InheritedWidget].  When
/// [version] changes, all descendants who request (via
/// [BuildContext.inheritFromWidgetOfExactType]) to be rebuilt when the model
/// changes will do so.
class _InheritedModel<T extends Model> extends InheritedWidget {
  final T model;
  final int version;
  _InheritedModel({Key key, Widget child, T model})
      : this.model = model,
        this.version = model.version,
        super(key: key, child: child);

  /// Used to return the runtime type.
  _InheritedModel.forRuntimeType()
      : this.model = null,
        this.version = 0;

  @override
  bool updateShouldNotify(_InheritedModel<T> oldWidget) =>
      (oldWidget.version != version);
}

typedef Widget ScopedModelDecendantBuilder<T extends Model>(
  BuildContext context,
  Widget child,
  T model,
);

class ScopedModelDecendant<T extends Model> extends StatelessWidget {
  final ScopedModelDecendantBuilder<T> builder;
  final Widget child;

  ScopedModelDecendant({this.builder, this.child});

  @override
  Widget build(BuildContext context) => builder(
        context,
        child,
        new ModelFinder<T>().of(context, rebuildOnChange: true),
      );
}
