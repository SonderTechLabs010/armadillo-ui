// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'focusable_story.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

class Suggestion {
  final Object id;
  final String title;
  final Color themeColor;
  Suggestion({this.id, this.title, this.themeColor});
}

/// A simple suggestion manager that reads suggestions from json maps them to
/// stories.
class SuggestionManager {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  int version = 0;
  Map<Object, List<Suggestion>> _storySuggestionsMap =
      const <Object, List<Suggestion>>{};
  List<Suggestion> _currentSuggestions = const <Suggestion>[];

  SuggestionManager();

  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      final decodedJson = JSON.decode(json);

      // Load suggestions.
      Map<Object, Suggestion> suggestionMap =
          new Map<Object, Suggestion>.fromIterable(
        decodedJson["suggestions"].map(
          (Map<String, Object> suggestion) => new Suggestion(
                id: new ValueKey(suggestion['id']),
                title: suggestion['title'],
                themeColor: new Color(int.parse(suggestion['color'])),
              ),
        ),
        key: (Suggestion suggestion) => suggestion.id,
        value: (Suggestion suggestion) => suggestion,
      );

      // Load story suggestions map.
      _storySuggestionsMap = new Map<Object, List<Suggestion>>();
      decodedJson["story_suggestions_map"]
          .forEach((String storyId, List<String> suggestions) {
        _storySuggestionsMap[new ValueKey(storyId)] = suggestions
            .map((String suggestionId) =>
                suggestionMap[new ValueKey(suggestionId)])
            .toList();
      });

      // Start with no story focus suggestions.
      _currentSuggestions = _storySuggestionsMap[new ValueKey('none')];

      _notifyListeners();
    });
  }

  List<Suggestion> get suggestions => _currentSuggestions;

  set askText(String text) {
    // TODO(apwilson): change suggestions based on askText.
  }

  /// Should be called only by those who instantiate
  /// [InheritedSuggestionManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when suggestions change, use
  /// [InheritedSuggestionManager.of].
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Should be called only by those who instantiate
  /// [InheritedSuggestionManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when suggestions change, use
  /// [InheritedSuggestionManager.of].
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Updates the [suggestions] based on the currently focused [story].  If no
  /// story is in focus, [story] should be null.
  void storyFocusChanged(Story story) {
    _currentSuggestions =
        _storySuggestionsMap[story?.id ?? new ValueKey('none')];
    _notifyListeners();
  }

  void _notifyListeners() {
    version++;
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}

class InheritedSuggestionManager extends InheritedWidget {
  final SuggestionManager suggestionManager;
  final int suggestionManagerVersion;
  InheritedSuggestionManager(
      {Key key, Widget child, SuggestionManager suggestionManager})
      : this.suggestionManager = suggestionManager,
        this.suggestionManagerVersion = suggestionManager.version,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedSuggestionManager oldWidget) =>
      (oldWidget.suggestionManagerVersion != suggestionManagerVersion);

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedSuggestionManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static SuggestionManager of(BuildContext context) {
    InheritedSuggestionManager inheritedSuggestionManager =
        context.inheritFromWidgetOfExactType(InheritedSuggestionManager);
    return inheritedSuggestionManager?.suggestionManager;
  }
}
