// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'simulation_builder.dart';
import 'story.dart';
import 'story_cluster_drag_feedback.dart';
import 'story_cluster_id.dart';
import 'story_list_layout.dart';

enum DisplayMode { tabs, panels }

/// A data model representing a list of [Story]s.
class StoryCluster {
  final StoryClusterId id;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;
  final List<Story> _stories;
  final String title;
  final GlobalKey carouselKey;
  final GlobalKey clusterDraggableKey;
  final GlobalKey clusterDragTargetsKey;
  final GlobalKey panelsKey;
  final GlobalKey scaleTransformKey;
  final GlobalKey titleTransformKey;
  final GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey;
  final GlobalKey<SimulationBuilderState> focusSimulationKey;
  DisplayMode _displayMode;
  final Set<VoidCallback> _storyListListeners;
  final Set<VoidCallback> _panelListeners;
  StoryId focusedStoryId;
  StoryLayout storyLayout;

  StoryCluster({
    StoryClusterId id,
    GlobalKey carouselKey,
    GlobalKey clusterDraggableKey,
    GlobalKey clusterDragTargetsKey,
    GlobalKey panelsKey,
    GlobalKey scaleTransformKey,
    GlobalKey titleTransformKey,
    GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey,
    GlobalKey<SimulationBuilderState> focusSimulationKey,
    List<Story> stories,
    Set<VoidCallback> storyListListeners,
    Set<VoidCallback> panelListeners,
    DisplayMode displayMode,
    StoryId focusedStoryId,
    this.storyLayout,
  })
      : this._stories = stories,
        this.title = _getClusterTitle(stories),
        this.lastInteraction = _getClusterLastInteraction(stories),
        this.cumulativeInteractionDuration =
            _getClusterCumulativeInteractionDuration(stories),
        this.id = id ?? new StoryClusterId(),
        this.carouselKey = carouselKey ?? new GlobalKey(),
        this.clusterDraggableKey = clusterDraggableKey ?? new GlobalKey(),
        this.clusterDragTargetsKey = clusterDragTargetsKey ?? new GlobalKey(),
        this.panelsKey = panelsKey ?? new GlobalKey(),
        this.scaleTransformKey = scaleTransformKey ?? new GlobalKey(),
        this.titleTransformKey = titleTransformKey ?? new GlobalKey(),
        this.dragFeedbackKey =
            dragFeedbackKey ?? new GlobalKey<StoryClusterDragFeedbackState>(),
        this.focusSimulationKey =
            focusSimulationKey ?? new GlobalKey<SimulationBuilderState>(),
        this._displayMode = displayMode ?? DisplayMode.panels,
        this._storyListListeners =
            storyListListeners ?? new Set<VoidCallback>(),
        this._panelListeners = panelListeners ?? new Set<VoidCallback>(),
        this.focusedStoryId = focusedStoryId ?? stories[0].id;

  factory StoryCluster.fromStory(Story story) => new StoryCluster(
        id: story.clusterId,
        clusterDraggableKey: story.clusterDraggableKey,
        stories: [
          story.copyWith(
            panel: new Panel(),
            positionedKey: new GlobalKey(),
          ),
        ],
      );

  List<Story> get stories => new List.unmodifiable(_stories);

  Map<StoryId, Widget> buildStoryWidgets(BuildContext context) {
    Map<StoryId, Widget> storyWidgets = <StoryId, Widget>{};
    stories.forEach((Story story) {
      storyWidgets[story.id] = story.builder(context);
    });
    return storyWidgets;
  }

  void addStoryListListener(VoidCallback listener) {
    _storyListListeners.add(listener);
  }

  void removeStoryListListener(VoidCallback listener) {
    _storyListListeners.remove(listener);
  }

  void _notifyStoryListListeners() {
    _storyListListeners.forEach((VoidCallback listener) => listener());
  }

  void addPanelListener(VoidCallback listener) {
    _panelListeners.add(listener);
  }

  void removePanelListener(VoidCallback listener) {
    _panelListeners.remove(listener);
  }

  void _notifyPanelListeners() {
    _panelListeners.forEach((VoidCallback listener) => listener());
  }

  StoryCluster copyWith({
    DateTime lastInteraction,
    Duration cumulativeInteractionDuration,
    bool inactive,
    GlobalKey clusterDraggableId,
    StoryId focusedStoryId,
    DisplayMode displayMode,
  }) =>
      new StoryCluster(
        id: this.id,
        carouselKey: this.carouselKey,
        clusterDraggableKey: clusterDraggableId ?? this.clusterDraggableKey,
        clusterDragTargetsKey: this.clusterDragTargetsKey,
        panelsKey: this.panelsKey,
        scaleTransformKey: this.scaleTransformKey,
        titleTransformKey: this.titleTransformKey,
        dragFeedbackKey: this.dragFeedbackKey,
        focusSimulationKey: this.focusSimulationKey,
        stories: new List<Story>.generate(
          _stories.length,
          (int index) => _stories[index].copyWith(
                lastInteraction: lastInteraction,
                cumulativeInteractionDuration: cumulativeInteractionDuration,
                inactive: inactive,
              ),
        ),
        displayMode: displayMode ?? this._displayMode,
        storyListListeners: this._storyListListeners,
        panelListeners: this._panelListeners,
        focusedStoryId: focusedStoryId ?? this.focusedStoryId,
        storyLayout: this.storyLayout,
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

  DisplayMode get displayMode => _displayMode;

  /// Switches the [DisplayMode] to [displayMode].
  set displayMode(DisplayMode displayMode) {
    if (_displayMode != displayMode) {
      _displayMode = displayMode;
      _notifyPanelListeners();
    }
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
    _notifyPanelListeners();
  }

  /// Adds the [story] to [stories] with a [Panel] of [withPanel].
  void add({Story story, Panel withPanel}) {
    _stories.add(story.copyWith(panel: withPanel));
    _notifyStoryListListeners();
  }

  /// Replaces the [Story.panel] of the story with [panel] with [withPanel]/
  void replace({Panel panel, Panel withPanel}) {
    Story story = _stories.where((Story story) => story.panel == panel).single;
    _replaceStory(story: story, withPanel: withPanel);
  }

  void _replaceStory({Story story, Panel withPanel}) {
    int storyIndex = _stories.indexOf(story);
    _stories.remove(story);
    _stories.insert(
      storyIndex,
      story.copyWith(panel: withPanel),
    );
  }

  void absorb(Story story) {
    List<Story> stories = new List<Story>.from(_stories);
    stories.remove(story);
    stories.sort(
      (Story a, Story b) => a.panel.sizeFactor > b.panel.sizeFactor
          ? 1
          : a.panel.sizeFactor < b.panel.sizeFactor ? -1 : 0,
    );

    Panel remainingAreaToAbsorb = story.panel;
    double remainingSize;
    Story absorbingStory;
    do {
      remainingSize = remainingAreaToAbsorb.sizeFactor;
      absorbingStory = _stories
          .where((Story story) => story.panel.canAbsorb(remainingAreaToAbsorb))
          .first;
      absorbingStory.panel.absorb(remainingAreaToAbsorb,
          (Panel absorbed, Panel remainder) {
        _replaceStory(story: absorbingStory, withPanel: absorbed);
        remainingAreaToAbsorb = remainder;
      });
    } while (remainingAreaToAbsorb.sizeFactor < remainingSize &&
        remainingAreaToAbsorb.sizeFactor > 0.0);
    assert(remainingAreaToAbsorb.sizeFactor == 0.0);

    int absorbedStoryIndex = _stories.indexOf(story);
    _stories.remove(story);
    normalizeSizes();

    // If we've just removed the focused story, switch focus to a tab adjacent
    // story.
    if (focusedStoryId == story.id) {
      focusedStoryId = _stories[absorbedStoryIndex >= _stories.length
              ? _stories.length - 1
              : absorbedStoryIndex]
          .id;
    }

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
