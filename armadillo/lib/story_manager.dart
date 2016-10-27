// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'config_manager.dart';
import 'panel.dart';
import 'story.dart';
import 'story_builder.dart';
import 'story_cluster.dart';
import 'story_list_layout.dart';
import 'suggestion_manager.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// A simple story manager that reads stories from json and reorders them with
/// user interaction.
class StoryManager extends ConfigManager {
  final SuggestionManager suggestionManager;
  List<StoryCluster> _storyClusters = const <StoryCluster>[];
  List<StoryCluster> _activeSortedStoryClusters = const <StoryCluster>[];
  List<StoryCluster> _inactiveStoryClusters = const <StoryCluster>[];
  Size _lastLayoutSize = Size.zero;
  double _listHeight = 0.0;

  StoryManager({this.suggestionManager});

  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      final decodedJson = convert.JSON.decode(json);

      // Load stories
      _storyClusters = decodedJson["stories"]
          .map((Map<String, Object> story) => new StoryCluster(stories: [
                storyBuilder(story),
              ]))
          .toList();
      updateLayouts(_lastLayoutSize);
      notifyListeners();
    });
  }

  List<StoryCluster> get storyClusters => _storyClusters;
  List<StoryCluster> get activeSortedStoryClusters =>
      _activeSortedStoryClusters;
  List<StoryCluster> get inactiveStoryClusters => _inactiveStoryClusters;
  double get listHeight => _listHeight;

  void updateLayouts(Size size) {
    if (size == Size.zero) {
      return;
    }
    _lastLayoutSize = size;

    _inactiveStoryClusters = new List<StoryCluster>.from(
      _storyClusters,
    );

    _inactiveStoryClusters.retainWhere((StoryCluster storyCluster) =>
        !storyCluster.stories.every((Story story) => !story.inactive));

    _activeSortedStoryClusters = new List<StoryCluster>.from(
      _storyClusters,
    );

    _activeSortedStoryClusters.removeWhere((StoryCluster storyCluster) =>
        !storyCluster.stories.every((Story story) => !story.inactive));

    // Sort recently interacted with stories to the start of the list.
    _activeSortedStoryClusters.sort((StoryCluster a, StoryCluster b) =>
        b.lastInteraction.millisecondsSinceEpoch -
        a.lastInteraction.millisecondsSinceEpoch);

    List<StoryLayout> storyLayout = new StoryListLayout(size: size).layout(
      storyClustersToLayout: _activeSortedStoryClusters,
      currentTime: new DateTime.now(),
    );

    double listHeight = 0.0;
    for (int i = 0; i < storyLayout.length; i++) {
      _activeSortedStoryClusters[i].storyLayout = storyLayout[i];
      listHeight = math.max(listHeight, -storyLayout[i].offset.dy);
    }
    _listHeight = listHeight;
  }

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
    updateLayouts(_lastLayoutSize);
    notifyListeners();
    suggestionManager.storyClusterFocusChanged(storyCluster);
  }

  /// Indicates the currently focused story cluster has been defocused.
  void interactionStopped() {
    notifyListeners();
    suggestionManager.storyClusterFocusChanged(null);
  }

  /// Randomizes story interaction times within the story cluster.
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
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Adds [storyCluster] to the list of story clusters.
  void add({StoryCluster storyCluster}) {
    _storyClusters.removeWhere((StoryCluster s) => s.id == storyCluster.id);
    _storyClusters.add(storyCluster);
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Adds [source]'s stories to [target]'s stories and removes [source] from
  /// the list of story clusters.
  void combine({StoryCluster source, StoryCluster target, Size size}) {
    // Update grid locations.
    for (int i = 0; i < source.stories.length; i++) {
      Story sourceStory = source.stories[i];
      Story largestStory = _getLargestStory(target.stories);
      if (largestStory.panel.canBeSplitVertically(size.width) ||
          largestStory.panel.canBeSplitHorizontally(size.height)) {
        largestStory.panel.split((Panel a, Panel b) {
          target.replace(panel: largestStory.panel, withPanel: a);
          target.add(story: sourceStory, withPanel: b);
          target.normalizeSizes();
        });
      } else {
        print('Cannot add story as a panel!  We must switch to tabs!');
      }
    }

    // We need to update the draggable id as in some cases this id could
    // be used by one of the cluster's stories.
    remove(storyClusterId: source.id);
    remove(storyClusterId: target.id);
    add(storyCluster: target.copyWith(clusterDraggableId: new GlobalKey()));
  }

  /// Removes [storyCluster] from the list of story clusters.
  void remove({StoryClusterId storyClusterId}) {
    _storyClusters.removeWhere((StoryCluster s) => (s.id == storyClusterId));
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Removes [storyToSplit] from [from]'s stories and updates [from]'s stories
  /// panels.  [storyToSplit] becomes forms its own [StoryCluster] which is
  /// added to the story cluster list.
  void split({Story storyToSplit, StoryCluster from}) {
    assert(from.stories.contains(storyToSplit));

    from.absorb(storyToSplit);

    add(storyCluster: new StoryCluster.fromStory(storyToSplit));
    add(storyCluster: from.copyWith());
  }

  // Determines the max number of rows and columns based on [size] and either
  // does nothing, rearrange the panels to fit, or switches to tabs.
  void normalize({Size size}) {
    // TODO(apwilson): implement this!
  }

  /// Finds and returns the [StoryCluster] with the id equal to
  /// [storyClusterId].
  StoryCluster getStoryCluster(StoryClusterId storyClusterId) => _storyClusters
      .where((StoryCluster storyCluster) => storyCluster.id == storyClusterId)
      .single;

  Story _getLargestStory(List<Story> stories) {
    double largestSize = -0.0;
    Story largestStory;
    stories.forEach((Story story) {
      double storySize = story.panel.sizeFactor;
      if (storySize > largestSize) {
        largestSize = storySize;
        largestStory = story;
      }
    });
    return largestStory;
  }
}

class InheritedStoryManager extends StatelessWidget {
  final StoryManager storyManager;
  final Widget child;

  InheritedStoryManager({this.storyManager, this.child});

  @override
  Widget build(BuildContext context) => new InheritedConfigManagerWidget(
        configManager: storyManager,
        builder: (BuildContext context) => new _InheritedStoryManager(
              storyManager: storyManager,
              child: child,
            ),
      );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [_InheritedStoryManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  /// If [rebuildOnChange] is true, the caller will be rebuilt upon changes
  /// to [StoryManager].
  static StoryManager of(BuildContext context, {bool rebuildOnChange: false}) {
    _InheritedStoryManager inheritedStoryManager = rebuildOnChange
        ? context.inheritFromWidgetOfExactType(_InheritedStoryManager)
        : context.ancestorWidgetOfExactType(_InheritedStoryManager);
    return inheritedStoryManager?.configManager;
  }
}

class _InheritedStoryManager extends InheritedConfigManager {
  _InheritedStoryManager({Widget child, StoryManager storyManager})
      : super(child: child, configManager: storyManager);
}
