// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'focusable_story.dart';
import 'suggestion_manager.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// A simple story manager that reads stories from json and reorders them with
/// user interaction.
class StoryManager {
  final SuggestionManager suggestionManager;
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  int version = 0;
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

      _notifyListeners();
    });
  }

  List<Story> get stories => _stories;

  /// Should be called only by those who instantiate
  /// [InheritedStoryManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when stories change, use
  /// [InheritedStoryManager.of].
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Should be called only by those who instantiate
  /// [InheritedStoryManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when stories change, use
  /// [InheritedStoryManager.of].
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Updates the [Story.lastInteraction] of [story] to be [DateTime.now].
  /// This method is to be called whenever a [Story]'s [Story.builder] [Widget]
  /// comes into focus.
  void interactionStarted(Story story) {
    _stories.removeWhere((Story s) => s.id == story.id);
    _stories.add(story.copyWith(lastInteraction: new DateTime.now()));
    _notifyListeners();
    suggestionManager.storyFocusChanged(story);
  }

  void interactionStopped() {
    _notifyListeners();
    suggestionManager.storyFocusChanged(null);
  }

  void _notifyListeners() {
    version++;
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}

class InheritedStoryManager extends InheritedWidget {
  final StoryManager storyManager;
  final int storyManagerVersion;
  InheritedStoryManager({Key key, Widget child, StoryManager storyManager})
      : this.storyManager = storyManager,
        this.storyManagerVersion = storyManager.version,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedStoryManager oldWidget) =>
      (oldWidget.storyManagerVersion != storyManagerVersion);

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedStoryManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static StoryManager of(BuildContext context) {
    InheritedStoryManager inheritedStoryManager =
        context.inheritFromWidgetOfExactType(InheritedStoryManager);
    return inheritedStoryManager?.storyManager;
  }
}
