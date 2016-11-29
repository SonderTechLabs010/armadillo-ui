// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/config_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Determines which stories can be hit testable.
class HitTestManager extends ConfigManager {
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

class InheritedHitTestManager extends StatelessWidget {
  final HitTestManager hitTestManager;
  final Widget child;

  InheritedHitTestManager({this.hitTestManager, this.child});

  @override
  Widget build(BuildContext context) => new InheritedConfigManagerWidget(
        configManager: hitTestManager,
        builder: (BuildContext context) => new _InheritedHitTestManager(
              hitTestManager: hitTestManager,
              child: child,
            ),
      );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [_InheritedHitTestManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  /// If [rebuildOnChange] is true, the caller will be rebuilt upon changes
  /// to [HitTestManager].
  static StoryManager of(BuildContext context, {bool rebuildOnChange: false}) {
    _InheritedHitTestManager inheritedHitTestManager = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(_InheritedHitTestManager)
        : context.ancestorWidgetOfExactType(_InheritedHitTestManager);
    return inheritedHitTestManager?.configManager;
  }
}

class _InheritedHitTestManager extends InheritedConfigManager {
  _InheritedHitTestManager({Widget child, HitTestManager hitTestManager})
      : super(child: child, configManager: hitTestManager);
}
