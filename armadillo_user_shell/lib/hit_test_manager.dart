// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/config_manager.dart';
import 'package:flutter/widgets.dart';

export 'package:armadillo/config_manager.dart' show ScopedModel, Model;

/// Determines which stories can be hit testable.
class HitTestModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static HitTestModel of(BuildContext context, {bool rebuildOnChange: false}) =>
      new ModelFinder<HitTestModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  List<String> _focusedStoryIds = [];
  bool _storiesObscuredBySuggestionOverlay = false;
  bool _storiesObscuredByQuickSettingsOverlay = false;

  void onFocusedStoriesChanged(List<String> focusedStoryIds) {
    _focusedStoryIds = focusedStoryIds;
    notifyListeners();
  }

  void onQuickSettingsOverlayChanged(bool active) {
    if (_storiesObscuredByQuickSettingsOverlay != active) {
      _storiesObscuredByQuickSettingsOverlay = active;
      notifyListeners();
    }
  }

  void onSuggestionsOverlayChanged(bool active) {
    if (_storiesObscuredBySuggestionOverlay != active) {
      _storiesObscuredBySuggestionOverlay = active;
      notifyListeners();
    }
  }

  bool isStoryHitTestable(String storyId) =>
      !_storiesObscuredBySuggestionOverlay &&
      !_storiesObscuredByQuickSettingsOverlay &&
      _focusedStoryIds.contains(storyId);
}
