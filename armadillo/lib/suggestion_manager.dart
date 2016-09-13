// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard/word_suggestion_service.dart';

import 'config_manager.dart';
import 'focusable_story.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// Specifies the type of action to perform when the suggestion is selected.
/// [launchStory] will trigger the [Story] specified by
/// [Suggestion.selectionStoryId] to come into focus.
/// [modifyStory] will modify the [Story] specified by
/// [Suggestion.selectionStoryId] in some way.
/// [doNothing] does nothing and is only provided for testing purposes.
enum SelectionType { launchStory, modifyStory, doNothing }

/// Determines what the suggestion looks like with respect to
/// [Suggestion.image].
enum ImageType { person, other }

class Suggestion {
  final Object id;
  final String title;
  final Color themeColor;
  final SelectionType selectionType;
  final Object selectionStoryId;
  final List<WidgetBuilder> icons;
  final WidgetBuilder image;
  final ImageType imageType;
  Suggestion({
    this.id,
    this.title,
    this.themeColor,
    this.selectionType,
    this.selectionStoryId,
    this.icons: const <WidgetBuilder>[],
    this.image,
    this.imageType,
  });
}

/// A simple suggestion manager that reads suggestions from json maps them to
/// stories.
class SuggestionManager extends ConfigManager {
  Map<Object, List<Suggestion>> _storySuggestionsMap =
      const <Object, List<Suggestion>>{};
  List<Suggestion> _currentSuggestions = const <Suggestion>[];
  Story _activeStory;
  String _askText;

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
                themeColor: suggestion['color'] != null
                    ? new Color(int.parse(suggestion['color']))
                    : Colors.blueGrey[600],
                selectionType: _getSelectionType(suggestion['selection_type']),
                selectionStoryId: new ValueKey(suggestion['story_id']),
                icons: suggestion['icons'] != null
                    ? (suggestion['icons'] as List<String>)
                        .map(
                          (String icon) => (BuildContext context) =>
                              new Image.asset(icon,
                                  fit: ImageFit.cover, color: Colors.white),
                        )
                        .toList()
                    : const <WidgetBuilder>[],
                image: suggestion['image'] != null
                    ? (_) => new Image.asset(
                          suggestion['image'],
                          fit: ImageFit.cover,
                        )
                    : null,
                imageType: _getImageType(suggestion['image_type']),
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

      notifyListeners();
    });
  }

  SelectionType _getSelectionType(String selectionType) {
    switch (selectionType) {
      case 'launch':
        return SelectionType.launchStory;
      case 'modify':
        return SelectionType.modifyStory;
      case 'nothing':
      default:
        return SelectionType.doNothing;
    }
  }

  ImageType _getImageType(String imageType) {
    switch (imageType) {
      case 'person':
        return ImageType.person;
      case 'other':
      default:
        return ImageType.other;
    }
  }

  List<Suggestion> get suggestions => _currentSuggestions;

  set askText(String text) {
    _askText = text?.toLowerCase();
    _updateSuggestions();
  }

  /// Updates the [suggestions] based on the currently focused [story].  If no
  /// story is in focus, [story] should be null.
  void storyFocusChanged(Story story) {
    _activeStory = story;
    _updateSuggestions();
  }

  void _updateSuggestions() {
    if (_askText?.isEmpty ?? true) {
      _currentSuggestions = _storySuggestionsMap[_activeStory?.id] ??
          _storySuggestionsMap[new ValueKey('none')];
    } else {
      List<Suggestion> suggestions =
          new List<Suggestion>.from(_storySuggestionsMap[new ValueKey('none')]);
      suggestions.sort((Suggestion a, Suggestion b) {
        int minADistance = math.min(
          a.title
              .toLowerCase()
              .split(' ')
              .map((String word) =>
                  WordSuggestionService.levenshteinDistance(word, _askText))
              .reduce(math.min),
          WordSuggestionService.levenshteinDistance(
              a.title.toLowerCase(), _askText),
        );

        int minBDistance = math.min(
          b.title
              .toLowerCase()
              .split(' ')
              .map((String word) =>
                  WordSuggestionService.levenshteinDistance(word, _askText))
              .reduce(math.min),
          WordSuggestionService.levenshteinDistance(
              b.title.toLowerCase(), _askText),
        );

        return minADistance - minBDistance;
      });
      _currentSuggestions = suggestions;
    }
    notifyListeners();
  }
}

class InheritedSuggestionManager
    extends InheritedConfigManager<SuggestionManager> {
  InheritedSuggestionManager({
    Key key,
    Widget child,
    SuggestionManager suggestionManager,
  })
      : super(
          key: key,
          child: child,
          configManager: suggestionManager,
        );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedSuggestionManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static SuggestionManager of(BuildContext context) {
    InheritedSuggestionManager inheritedSuggestionManager =
        context.inheritFromWidgetOfExactType(InheritedSuggestionManager);
    return inheritedSuggestionManager?.configManager;
  }
}
