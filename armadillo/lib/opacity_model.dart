// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'model.dart';

export 'model.dart' show ScopedModel, Model;

/// Tracks the [Opacity] of widget tree, notifying listeners when it changes.
/// Using an [OpacityModel] allows the [opacity] it tracks to be passed down
/// the widget tree using an [ScopedModel].
class OpacityModel extends Model {
  double _opacity;

  OpacityModel(double opacity) : _opacity = opacity ?? 1.0;

  double get opacity => _opacity;

  set opacity(double opacity) {
    if (opacity != _opacity) {
      _opacity = opacity;
      notifyListeners();
    }
  }
}
