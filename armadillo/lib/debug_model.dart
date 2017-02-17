// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'model.dart';

export 'model.dart' show ScopedModel, Model;

/// Tracks debug parameters, notifying listeners when they changes.
/// Using an [DebugModel] allows the debug parameters it tracks to be passed
/// down the widget tree using a [ScopedModel].
class DebugModel extends Model {
  bool _showTargetLineOverlay = false;
  bool _showTargetLineInfluenceOverlay = false;

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static DebugModel of(BuildContext context, {bool rebuildOnChange: false}) =>
      new ModelFinder<DebugModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  bool get showTargetLineInfluenceOverlay => _showTargetLineInfluenceOverlay;

  set showTargetLineInfluenceOverlay(bool showTargetLineInfluenceOverlay) {
    if (_showTargetLineInfluenceOverlay != showTargetLineInfluenceOverlay) {
      _showTargetLineInfluenceOverlay = showTargetLineInfluenceOverlay;
      notifyListeners();
    }
  }

  bool get showTargetLineOverlay => _showTargetLineOverlay;

  set showTargetLineOverlay(bool showTargetLineOverlay) {
    if (_showTargetLineOverlay != showTargetLineOverlay) {
      _showTargetLineOverlay = showTargetLineOverlay;
      notifyListeners();
    }
  }

  void twiddle() {
    if (!showTargetLineOverlay && !showTargetLineInfluenceOverlay) {
      showTargetLineOverlay = true;
      showTargetLineInfluenceOverlay = false;
    } else if (!showTargetLineInfluenceOverlay) {
      showTargetLineOverlay = false;
      showTargetLineInfluenceOverlay = true;
    } else {
      showTargetLineOverlay = false;
      showTargetLineInfluenceOverlay = false;
    }
  }
}

typedef Widget ScopedDebugWidgetBuilder(
  BuildContext context,
  Widget child,
  DebugModel debugModel,
);

class ScopedDebugWidget extends StatelessWidget {
  final ScopedDebugWidgetBuilder builder;
  final Widget child;
  ScopedDebugWidget({this.builder, this.child});

  @override
  Widget build(BuildContext context) => builder(
        context,
        child,
        DebugModel.of(context, rebuildOnChange: true),
      );
}
