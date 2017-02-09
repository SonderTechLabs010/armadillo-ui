// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'model.dart';
import 'panel.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_id.dart';
import 'story_generator.dart';
import 'story_list_layout.dart';
import 'suggestion_model.dart';

export 'model.dart' show ScopedModel, Model;

/// A simple story model that gets its stories from [storyGenerator] and
/// reorders them with user interaction.
class StoryModel extends Model {
  final SuggestionModel suggestionModel;
  final StoryGenerator storyGenerator;
  List<StoryCluster> _storyClusters = const <StoryCluster>[];
  List<StoryCluster> _activeSortedStoryClusters = const <StoryCluster>[];
  List<StoryCluster> _inactiveStoryClusters = const <StoryCluster>[];
  Size _lastLayoutSize = Size.zero;
  double _listHeight = 0.0;

  StoryModel({this.suggestionModel, this.storyGenerator}) {
    storyGenerator.addListener(() {
      _storyClusters = storyGenerator.storyClusters;
      updateLayouts(_lastLayoutSize);
      notifyListeners();
    });
  }

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static StoryModel of(BuildContext context, {bool rebuildOnChange: false}) =>
      new ModelFinder<StoryModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  List<StoryCluster> get storyClusters => _storyClusters;
  List<StoryCluster> get activeSortedStoryClusters =>
      _activeSortedStoryClusters;
  List<StoryCluster> get inactiveStoryClusters => _inactiveStoryClusters;
  double get listHeight => _listHeight;

  void updateLayouts(Size size) {
    if (size.width == 0.0 || size.height == 0.0) {
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

  /// Updates the [Story.lastInteraction] of [storyCluster] to be [DateTime.now].
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
    suggestionModel.storyClusterFocusChanged(storyCluster);
  }

  /// Indicates the currently focused story cluster has been defocused.
  void interactionStopped() {
    notifyListeners();
    suggestionModel.storyClusterFocusChanged(null);
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

  void _add({StoryCluster storyCluster}) {
    _storyClusters.add(storyCluster);
    updateLayouts(_lastLayoutSize);
    notifyListeners();
  }

  /// Adds [source]'s stories to [target]'s stories and removes [source] from
  /// the list of story clusters.
  void combine({StoryCluster source, StoryCluster target}) {
    // Update grid locations.
    for (int i = 0; i < source.stories.length; i++) {
      Story sourceStory = source.stories[i];
      Story largestStory = _getLargestStory(target.stories);
      largestStory.panel.split((Panel a, Panel b) {
        target.replace(panel: largestStory.panel, withPanel: a);
        target.add(story: sourceStory, withPanel: b);
        target.normalizeSizes();
      });
      if (!largestStory.panel.canBeSplitVertically(_lastLayoutSize.width) &&
          !largestStory.panel.canBeSplitHorizontally(_lastLayoutSize.height)) {
        target.displayMode = DisplayMode.tabs;
      }
    }

    // We need to update the draggable id as in some cases this id could
    // be used by one of the cluster's stories.
    remove(storyClusterId: source.id);
    remove(storyClusterId: target.id);
    _add(storyCluster: target.copyWith(clusterDraggableId: new GlobalKey()));
  }

  /// Removes [storyClusterId] from the list of story clusters.
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

    _add(storyCluster: new StoryCluster.fromStory(storyToSplit));
    _storyClusters.removeWhere((StoryCluster s) => s.id == from.id);
    _add(storyCluster: from.copyWith());
  }

  // Determines the max number of rows and columns based on [size] and either
  // does nothing, rearrange the panels to fit, or switches to tabs.
  void normalize({Size size}) {
    // TODO(apwilson): implement this!
  }

  /// Finds and returns the [StoryCluster] with the id equal to
  /// [storyClusterId].
  /// TODO(apwilson): have callers handle when the story cluster no longer exists.
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
