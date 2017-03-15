// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'model.dart';

export 'model.dart' show ScopedModel, Model;

/// Tracks debug parameters, notifying listeners when they changes.
/// Using an [DebugModel] allows the debug parameters it tracks to be passed
/// down the widget tree using a [ScopedModel].
class DebugModel extends Model {
  bool _showTargetOverlay = false;
  bool _showTargetInfluenceOverlay = false;

  bool get showTargetInfluenceOverlay => _showTargetInfluenceOverlay;

  set showTargetInfluenceOverlay(bool showTargetInfluenceOverlay) {
    if (_showTargetInfluenceOverlay != showTargetInfluenceOverlay) {
      _showTargetInfluenceOverlay = showTargetInfluenceOverlay;
      notifyListeners();
    }
  }

  bool get showTargetOverlay => _showTargetOverlay;

  set showTargetOverlay(bool showTargetOverlay) {
    if (_showTargetOverlay != showTargetOverlay) {
      _showTargetOverlay = showTargetOverlay;
      notifyListeners();
    }
  }

  void twiddle() {
    if (!showTargetOverlay && !showTargetInfluenceOverlay) {
      showTargetOverlay = true;
      showTargetInfluenceOverlay = false;
    } else if (!showTargetInfluenceOverlay) {
      showTargetOverlay = false;
      showTargetInfluenceOverlay = true;
    } else {
      showTargetOverlay = false;
      showTargetInfluenceOverlay = false;
    }
  }
}
