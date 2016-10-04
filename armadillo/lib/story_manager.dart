// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'config_manager.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'suggestion_manager.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// A simple story manager that reads stories from json and reorders them with
/// user interaction.
class StoryManager extends ConfigManager {
  final SuggestionManager suggestionManager;
  List<StoryCluster> _storyClusters = const <StoryCluster>[];

  StoryManager({this.suggestionManager});

  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      final decodedJson = convert.JSON.decode(json);

      // Load stories
      _storyClusters = decodedJson["stories"]
          .map(
            (Map<String, Object> story) => new StoryCluster(stories: [
                  new Story(
                    id: new ValueKey(story['id']),
                    builder: (_) => new Image.asset(
                          story['content'],
                          alignment: FractionalOffset.topCenter,
                          fit: ImageFit.cover,
                        ),
                    wideBuilder: (_) => new Image.asset(
                          story['contentWide'] ?? story['content'],
                          alignment: FractionalOffset.topCenter,
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
                    inactive: 'true' == (story['inactive'] ?? 'false'),
                  ),
                ]),
          )
          .toList();

      notifyListeners();
    });
  }

  List<StoryCluster> get storyClusters => _storyClusters;

  /// Updates the [Story.lastInteraction] of [story] to be [DateTime.now].
  /// This method is to be called whenever a [Story]'s [Story.builder] [Widget]
  /// comes into focus.
  void interactionStarted(StoryCluster storyCluster) {
    _storyClusters.removeWhere((StoryCluster s) => s.id == storyCluster.id);
    _storyClusters.add(
      storyCluster.copyWith(
        lastInteraction: new DateTime.now(),
        inactive: false,
      ),
    );
    notifyListeners();
    suggestionManager.storyClusterFocusChanged(storyCluster);
  }

  void interactionStopped() {
    notifyListeners();
    suggestionManager.storyClusterFocusChanged(null);
  }

  void addStoryCluster(StoryCluster storyCluster) {
    _storyClusters.removeWhere((StoryCluster s) => s.id == storyCluster.id);
    _storyClusters.add(storyCluster);
    notifyListeners();
  }

  void randomizeStoryTimes() {
    math.Random random = new math.Random();
    DateTime storyInteractionTime = new DateTime.now();
    _storyClusters =
        new List<StoryCluster>.generate(_storyClusters.length, (int index) {
      storyInteractionTime = storyInteractionTime.subtract(
          new Duration(minutes: math.max(0, random.nextInt(100) - 70)));
      Duration interaction = new Duration(minutes: random.nextInt(60));
      StoryCluster storyCluster = _storyClusters[index].copyWith(
        lastInteraction: storyInteractionTime,
        cumulativeInteractionDuration: interaction,
      );
      storyInteractionTime = storyInteractionTime.subtract(interaction);
      return storyCluster;
    });
    notifyListeners();
  }

  void combine({StoryCluster source, StoryCluster target}) {
    _storyClusters.removeWhere(
        (StoryCluster s) => (s.id == source.id) || (s.id == target.id));
    target.stories.addAll(source.stories);
    _storyClusters.add(target.copyWith());
    notifyListeners();
  }

  void split({Story story, StoryCluster from}) {
    if (!from.stories.contains(story)) {
      return;
    }
    from.stories.remove(story);
    addStoryCluster(new StoryCluster.fromStory(story));
    addStoryCluster(from.copyWith());
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
  /// If [rebuildOnChange] is true, the caller will be rebuilt upon changes
  /// to [StoryManager].
  static StoryManager of(BuildContext context, {bool rebuildOnChange: false}) {
    InheritedStoryManager inheritedStoryManager = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(InheritedStoryManager)
        : context.ancestorWidgetOfExactType(InheritedStoryManager);
    return inheritedStoryManager?.configManager;
  }
}
