// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'config_manager.dart';

export 'config_manager.dart' show ScopedModel, Model;

/// Tracks the [Size] of something, notifying listeners when it changes.
/// Using a [SizeModel] allows the [Size] it tracks to be passed down the
/// widget tree using an [ScopedSizeModel].
class SizeModel extends Model {
  Size _size;

  SizeModel(Size size) : _size = size ?? Size.zero;

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static SizeModel of(BuildContext context, {bool rebuildOnChange: false}) =>
      new ModelFinder<SizeModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  Size get size => _size;

  set size(Size size) {
    if (size != _size) {
      _size = size;
      notifyListeners();
    }
  }
}
