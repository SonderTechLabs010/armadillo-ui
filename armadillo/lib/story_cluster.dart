// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'story.dart';

/// A data model representing a list of [Story]s.
class StoryCluster {
  final Object id;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;
  final List<Story> _stories;
  final String title;
  final Object carouselId;
  final Object clusterDraggableId;
  final Object clusterDragTargetsId;
  final Object dragFeedbackId;
  final Set<VoidCallback> _storyListListeners;

  StoryCluster({
    Object id,
    Object carouselId,
    Object clusterDraggableId,
    Object clusterDragTargetsId,
    Object dragFeedbackId,
    List<Story> stories,
    Set<VoidCallback> storyListListeners,
  })
      : this._stories = stories,
        this.title = _getClusterTitle(stories),
        this.lastInteraction = _getClusterLastInteraction(stories),
        this.cumulativeInteractionDuration =
            _getClusterCumulativeInteractionDuration(stories),
        this.id = id ?? new Object(),
        this.carouselId = carouselId ?? new Object(),
        this.clusterDraggableId = clusterDraggableId ?? new Object(),
        this.clusterDragTargetsId = clusterDragTargetsId ?? new Object(),
        this.dragFeedbackId = dragFeedbackId ?? new Object(),
        this._storyListListeners =
            storyListListeners ?? new Set<VoidCallback>();

  factory StoryCluster.fromStory(Story story) => new StoryCluster(
        id: story.clusterId,
        clusterDraggableId: story.clusterDraggableId,
        stories: [
          story.copyWith(panel: new Panel()),
        ],
      );

  List<Story> get stories => new List.unmodifiable(_stories);

  void addStoryListListener(VoidCallback listener) {
    _storyListListeners.add(listener);
  }

  void removeStoryListListener(VoidCallback listener) {
    _storyListListeners.remove(listener);
  }

  void _notifyStoryListListeners() {
    _storyListListeners.forEach((VoidCallback listener) => listener());
  }

  StoryCluster copyWith({
    DateTime lastInteraction,
    Duration cumulativeInteractionDuration,
    bool inactive,
    Object clusterDraggableId,
  }) =>
      new StoryCluster(
        id: this.id,
        carouselId: this.carouselId,
        clusterDraggableId: clusterDraggableId ?? this.clusterDraggableId,
        clusterDragTargetsId: this.clusterDragTargetsId,
        dragFeedbackId: this.dragFeedbackId,
        stories: new List<Story>.generate(
          _stories.length,
          (int index) => _stories[index].copyWith(
                lastInteraction: lastInteraction,
                cumulativeInteractionDuration: cumulativeInteractionDuration,
                inactive: inactive,
              ),
        ),
        storyListListeners: this._storyListListeners,
      );

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) => (other is StoryCluster && other.id == id);

  @override
  String toString() {
    String string = 'StoryCluster( id: $id, title: $title,\n';
    _stories.forEach((Story story) {
      string += '\n   story: $story';
    });
    string += ' )';
    return string;
  }

  /// Removes any preview stories from [stories]
  void removePreviews() {
    _stories.toList().forEach((Story story) {
      if (story.isPlaceHolder) {
        absorb(_stories.where((Story s) => story.id == s.id).single);
      }
    });
  }

  /// Returns the [Panel]s of the [stories].
  Iterable<Panel> get panels => _stories.map((Story story) => story.panel);

  /// Resizes the [Panel]s of the [stories] to have columns with equal widths
  /// and rows of equal heights.
  void normalizeSizes() {
    Set<double> currentLeftsSet = new Set<double>();
    Set<double> currentTopsSet = new Set<double>();
    panels.forEach((Panel panel) {
      currentLeftsSet.add(panel.left);
      currentTopsSet.add(panel.top);
    });

    List<double> currentSortedLefts = new List<double>.from(currentLeftsSet);
    currentSortedLefts.sort();

    List<double> currentSortedTops = new List<double>.from(currentTopsSet);
    currentSortedTops.sort();

    Map<double, double> leftMap = <double, double>{1.0: 1.0};
    double left = 0.0;
    for (int i = 0; i < currentSortedLefts.length; i++) {
      leftMap[currentSortedLefts[i]] = left;
      left += getSpanSpan(1.0, i, currentSortedLefts.length);
    }

    Map<double, double> topMap = <double, double>{1.0: 1.0};
    double top = 0.0;
    for (int i = 0; i < currentSortedTops.length; i++) {
      topMap[currentSortedTops[i]] = top;
      top += getSpanSpan(1.0, i, currentSortedTops.length);
    }

    panels.toList().forEach(
          (Panel panel) => replace(
                panel: panel,
                withPanel: new Panel.fromLTRB(
                  leftMap[panel.left],
                  topMap[panel.top],
                  leftMap[panel.right],
                  topMap[panel.bottom],
                ),
              ),
        );
  }

  /// Adds the [story] to [stories] with a [Panel] of [withPanel].
  void add({Story story, Panel withPanel}) {
    _stories.add(story.copyWith(panel: withPanel));
    _notifyStoryListListeners();
  }

  /// Replaces the [Story.panel] of the story with [panel] with [withPanel]/
  void replace({Panel panel, Panel withPanel}) {
    Story story = _stories.where((Story story) => story.panel == panel).single;
    _stories.remove(story);
    _stories.add(story.copyWith(panel: withPanel));
  }

  void absorb(Story story) {
    // Update grid locations.
    List<Story> stories = new List<Story>.from(_stories);
    stories.remove(story);
    stories.sort(
      (Story a, Story b) => a.panel.sizeFactor > b.panel.sizeFactor
          ? 1
          : a.panel.sizeFactor < b.panel.sizeFactor ? -1 : 0,
    );
    Panel remainingAreaToAbsorb = story.panel;
    double remainingSize;
    do {
      remainingSize = remainingAreaToAbsorb.sizeFactor;
      stories
          .where((Story story) =>
              story.panel.isAdjacentWithOriginAligned(remainingAreaToAbsorb))
          .forEach((Story story) {
        story.panel.absorb(remainingAreaToAbsorb,
            (Panel absorbed, Panel remainder) {
          int storyIndex = _stories.indexOf(story);
          _stories.remove(story);
          _stories.insert(
            storyIndex,
            story.copyWith(panel: absorbed),
          );
          remainingAreaToAbsorb = remainder;
        });
      });
    } while (remainingAreaToAbsorb.sizeFactor < remainingSize);
    assert(remainingAreaToAbsorb.sizeFactor == 0.0);

    _stories.remove(story);
    normalizeSizes();
    _notifyStoryListListeners();
  }

  static String _getClusterTitle(List<Story> stories) {
    String title = '';
    stories.where((Story story) => !story.isPlaceHolder).forEach((Story story) {
      if (title.isNotEmpty) {
        title += ', ';
      }
      title += story.title;
    });
    return title;
  }

  static DateTime _getClusterLastInteraction(List<Story> stories) {
    DateTime latestTime = new DateTime(1970);
    stories.where((Story story) => !story.isPlaceHolder).forEach((Story story) {
      if (latestTime.isBefore(story.lastInteraction)) {
        latestTime = story.lastInteraction;
      }
    });
    return latestTime;
  }

  static Duration _getClusterCumulativeInteractionDuration(
      List<Story> stories) {
    Duration largestDuration = new Duration();
    stories.where((Story story) => !story.isPlaceHolder).forEach((Story story) {
      if (largestDuration < story.cumulativeInteractionDuration) {
        largestDuration = story.cumulativeInteractionDuration;
      }
    });
    return largestDuration;
  }
}
