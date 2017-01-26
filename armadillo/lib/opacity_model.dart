// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'model.dart';

export 'model.dart' show ScopedModel, Model;

/// Tracks the [Opacity] of widget tree, notifying listeners when it changes.
/// Using an [OpacityModel] allows the [opacity] it tracks to be passed down
/// the widget tree using an [ScopedOpacityModel].
class OpacityModel extends Model {
  double _opacity;

  OpacityModel(double opacity) : _opacity = opacity ?? 1.0;

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static OpacityModel of(BuildContext context, {bool rebuildOnChange: false}) =>
      new ModelFinder<OpacityModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  double get opacity => _opacity;

  set opacity(double opacity) {
    if (opacity != _opacity) {
      _opacity = opacity;
      notifyListeners();
    }
  }
}

typedef Widget ScopedOpacityWidgetBuilder(
  BuildContext context,
  Widget child,
  double opacity,
);

class ScopedOpacityWidget extends StatelessWidget {
  final ScopedOpacityWidgetBuilder builder;
  final Widget child;
  ScopedOpacityWidget({this.builder, this.child});

  @override
  Widget build(BuildContext context) => builder(
        context,
        child,
        OpacityModel.of(context, rebuildOnChange: true).opacity,
      );
}
