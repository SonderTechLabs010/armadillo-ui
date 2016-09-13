// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'config_manager.dart';
import 'focusable_story.dart';
import 'suggestion_manager.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// A simple story manager that reads stories from json and reorders them with
/// user interaction.
class StoryManager extends ConfigManager {
  final SuggestionManager suggestionManager;
  List<Story> _stories = const <Story>[];

  StoryManager({this.suggestionManager});

  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      final decodedJson = JSON.decode(json);

      // Load stories
      _stories = decodedJson["stories"]
          .map(
            (Map<String, Object> story) => new Story(
                  id: new ValueKey(story['id']),
                  builder: (_) => new Image.asset(
                        story['content'],
                        alignment: FractionalOffset.centerLeft,
                        fit: ImageFit.cover,
                      ),
                  title: story['title'],
                  icons: (story['icons'] as List<String>)
                      .map(
                        (String icon) => (BuildContext context) =>
                            new Image.asset(icon,
                                fit: ImageFit.cover, color: Colors.white),
                      )
                      .toList(),
                  avatar: (_) => new Image.asset(
                        story['avatar'],
                        fit: ImageFit.cover,
                      ),
                  lastInteraction: new DateTime.now().subtract(
                    new Duration(
                      seconds: int.parse(story['lastInteraction']),
                    ),
                  ),
                  cumulativeInteractionDuration: new Duration(
                    minutes: int.parse(story['culmulativeInteraction']),
                  ),
                  themeColor: new Color(int.parse(story['color'])),
                ),
          )
          .toList();

      notifyListeners();
    });
  }

  List<Story> get stories => _stories;

  /// Updates the [Story.lastInteraction] of [story] to be [DateTime.now].
  /// This method is to be called whenever a [Story]'s [Story.builder] [Widget]
  /// comes into focus.
  void interactionStarted(Story story) {
    _stories.removeWhere((Story s) => s.id == story.id);
    _stories.add(story.copyWith(lastInteraction: new DateTime.now()));
    notifyListeners();
    suggestionManager.storyFocusChanged(story);
  }

  void interactionStopped() {
    notifyListeners();
    suggestionManager.storyFocusChanged(null);
  }

  void addStory(Story story) {
    _stories.removeWhere((Story s) => s.id == story.id);
    _stories.add(story);
    notifyListeners();
  }
}

class InheritedStoryManager extends InheritedConfigManager<StoryManager> {
  InheritedStoryManager({
    Key key,
    Widget child,
    StoryManager storyManager,
  })
      : super(
          key: key,
          child: child,
          configManager: storyManager,
        );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedStoryManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static StoryManager of(BuildContext context) {
    InheritedStoryManager inheritedStoryManager =
        context.inheritFromWidgetOfExactType(InheritedStoryManager);
    return inheritedStoryManager?.configManager;
  }
}
