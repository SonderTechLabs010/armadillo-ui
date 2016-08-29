// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/widgets.dart';

/// A [PageRoute] delegating the construction of its UI to a separate class
/// instead of a subclass.
class DelegatingPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder _builder;

  DelegatingPageRoute(this._builder,
      {Completer<T> completer, RouteSettings settings: const RouteSettings()})
      : super(completer: completer, settings: settings);

  @override
  Duration get transitionDuration => const Duration(milliseconds: 1);

  @override
  Color get barrierColor => null; // A page route is opaque anyways.

  @override
  Widget buildPage(BuildContext context, _, __) {
    return _builder(context);
  }

  @override
  bool get maintainState => false;
}
