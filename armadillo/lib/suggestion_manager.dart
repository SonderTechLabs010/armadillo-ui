// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'config_manager.dart';
import 'story_cluster.dart';
import 'suggestion.dart';

/// A simple suggestion manager that reads suggestions from json maps them to
/// stories.
abstract class SuggestionManager extends ConfigManager {
  List<Suggestion> get suggestions;

  set askText(String text);

  set asking(bool asking);

  /// Updates the [suggestions] based on the currently focused storyCluster].  If no
  /// story is in focus, [storyCluster] should be null.
  void storyClusterFocusChanged(StoryCluster storyCluster);

  /// Called when a suggestion is selected by the user.
  void onSuggestionSelected(Suggestion suggestion);
}

class InheritedSuggestionManager extends StatelessWidget {
  final SuggestionManager suggestionManager;
  final Widget child;

  InheritedSuggestionManager({this.suggestionManager, this.child});

  @override
  Widget build(BuildContext context) => new InheritedConfigManagerWidget(
        configManager: suggestionManager,
        builder: (BuildContext context) => new _InheritedSuggestionManager(
              suggestionManager: suggestionManager,
              child: child,
            ),
      );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [_InheritedSuggestionManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  /// If [rebuildOnChange] is true, the caller will be rebuilt upon changes
  /// to [SuggestionManager].
  static SuggestionManager of(BuildContext context,
      {bool rebuildOnChange: false}) {
    _InheritedSuggestionManager inheritedSuggestionManager = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(_InheritedSuggestionManager)
        : context.ancestorWidgetOfExactType(_InheritedSuggestionManager);
    return inheritedSuggestionManager?.configManager;
  }
}

class _InheritedSuggestionManager extends InheritedConfigManager {
  _InheritedSuggestionManager({
    Widget child,
    SuggestionManager suggestionManager,
  })
      : super(child: child, configManager: suggestionManager);
}
