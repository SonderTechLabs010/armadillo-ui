// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'model.dart';

export 'model.dart' show ScopedModel, Model;

/// Base class for [Model]s that specify a background scrim.
abstract class ScrimModel extends Model {
  Color get scrimColor;
  double get progress;

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static ScrimModel of(BuildContext context) =>
      const ModelFinder<ScrimModel>().of(context);
}
