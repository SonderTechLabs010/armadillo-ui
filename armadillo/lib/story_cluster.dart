// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';
import 'place_holder_story.dart';
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
  final GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey;

  /// The focus simulation is the scaling that occurs when the
  /// user has focused on the cluster to bring it to full screen size.
  final GlobalKey<SimulationBuilderState> focusSimulationKey;

  /// The inline preview scale simulation is the scaling that occurs when the
  /// user drags a cluster over this cluster while in the timeline after the
  /// inline preview timeout occurs.
  final GlobalKey<SimulationBuilderState> inlinePreviewScaleSimulationKey;

  /// The inline preview hint scale simulation is the scaling that occurs when
  /// the user drags a cluster over this cluster while in the timeline before
  /// the inline preview timeout occurs.
  final GlobalKey<SimulationBuilderState> inlinePreviewHintScaleSimulationKey;

  DisplayMode _displayMode;
  DisplayMode _previewDisplayMode;
  final Set<VoidCallback> _storyListListeners;
  final Set<VoidCallback> _panelListeners;
  StoryId _focusedStoryId;
  StoryLayout storyLayout;

  StoryCluster({
    StoryClusterId id,
    GlobalKey carouselKey,
    GlobalKey clusterDraggableKey,
    GlobalKey clusterDragTargetsKey,
    GlobalKey panelsKey,
    GlobalKey<StoryClusterDragFeedbackState> dragFeedbackKey,
    GlobalKey<SimulationBuilderState> focusSimulationKey,
    GlobalKey<SimulationBuilderState> inlinePreviewScaleSimulationKey,
    GlobalKey<SimulationBuilderState> inlinePreviewHintScaleSimulationKey,
    List<Story> stories,
    Set<VoidCallback> storyListListeners,
    Set<VoidCallback> panelListeners,
    DisplayMode displayMode,
    DisplayMode previewDisplayMode,
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
        this.dragFeedbackKey =
            dragFeedbackKey ?? new GlobalKey<StoryClusterDragFeedbackState>(),
        this.focusSimulationKey =
            focusSimulationKey ?? new GlobalKey<SimulationBuilderState>(),
        this.inlinePreviewScaleSimulationKey =
            inlinePreviewScaleSimulationKey ??
                new GlobalKey<SimulationBuilderState>(),
        this.inlinePreviewHintScaleSimulationKey =
            inlinePreviewHintScaleSimulationKey ??
                new GlobalKey<SimulationBuilderState>(),
        this._displayMode = displayMode ?? DisplayMode.panels,
        this._previewDisplayMode = previewDisplayMode ?? DisplayMode.panels,
        this._storyListListeners =
            storyListListeners ?? new Set<VoidCallback>(),
        this._panelListeners = panelListeners ?? new Set<VoidCallback>(),
        this._focusedStoryId = focusedStoryId ?? stories[0].id;

  factory StoryCluster.fromStory(Story story) => new StoryCluster(
        id: story.clusterId,
        clusterDraggableKey: story.clusterDraggableKey,
        stories: <Story>[
          story.copyWith(
            panel: new Panel(),
            positionedKey: new GlobalKey(),
          ),
        ],
      );

  /// The list of stories in this cluster including both 'real' stories and
  /// place holder stories.
  List<Story> get stories => new List<Story>.unmodifiable(_stories);

  /// The list of 'real' stories in this cluster.
  List<Story> get realStories => new List<Story>.unmodifiable(
        _stories.where((Story story) => !story.isPlaceHolder),
      );

  /// The list of place holder stories in this cluster.
  List<PlaceHolderStory> get previewStories =>
      new List<PlaceHolderStory>.unmodifiable(
        _stories.where((Story story) => story.isPlaceHolder),
      );

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
  }) =>
      new StoryCluster(
        id: this.id,
        carouselKey: this.carouselKey,
        clusterDraggableKey: clusterDraggableId ?? this.clusterDraggableKey,
        clusterDragTargetsKey: this.clusterDragTargetsKey,
        panelsKey: this.panelsKey,
        dragFeedbackKey: this.dragFeedbackKey,
        focusSimulationKey: this.focusSimulationKey,
        inlinePreviewScaleSimulationKey: this.inlinePreviewScaleSimulationKey,
        inlinePreviewHintScaleSimulationKey:
            this.inlinePreviewHintScaleSimulationKey,
        stories: new List<Story>.generate(
          _stories.length,
          (int index) => _stories[index].copyWith(
                lastInteraction: lastInteraction,
                cumulativeInteractionDuration: cumulativeInteractionDuration,
                inactive: inactive,
              ),
        ),
        displayMode: this._displayMode,
        previewDisplayMode: this._previewDisplayMode,
        storyListListeners: this._storyListListeners,
        panelListeners: this._panelListeners,
        focusedStoryId: this._focusedStoryId,
        storyLayout: this.storyLayout,
      );

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) => (other is StoryCluster && other.id == id);

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
  Map<StoryId, PlaceHolderStory> removePreviews() {
    Map<StoryId, PlaceHolderStory> storiesRemoved =
        <StoryId, PlaceHolderStory>{};
    _stories.toList().forEach((Story story) {
      if (story is PlaceHolderStory) {
        absorb(_stories.where((Story s) => story.id == s.id).single);
        storiesRemoved[story.associatedStoryId] = story;
      }
    });
    return storiesRemoved;
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
      (Panel panel) {
        assert(() {
          bool hadErrors = false;
          if (leftMap[panel.left] == null) {
            print(
                'leftMap doesn\'t contain left ${panel.left}: ${leftMap.keys}');
            hadErrors = true;
          }
          if (topMap[panel.top] == null) {
            print('topMap doesn\'t contain top ${panel.top}: ${topMap.keys}');
            hadErrors = true;
          }
          if (leftMap[panel.right] == null) {
            print(
                'leftMap doesn\'t contain right ${panel.right}: ${leftMap.keys}');
            hadErrors = true;
          }
          if (topMap[panel.bottom] == null) {
            print(
                'topMap doesn\'t contain bottom ${panel.bottom}: ${topMap.keys}');
            hadErrors = true;
          }
          if (hadErrors) {
            panels.forEach((Panel panel) {
              print(' |--> $panel');
            });
          }
          return !hadErrors;
        });
        replace(
          panel: panel,
          withPanel: new Panel.fromLTRB(
            leftMap[panel.left],
            topMap[panel.top],
            leftMap[panel.right],
            topMap[panel.bottom],
          ),
        );
      },
    );
    _notifyPanelListeners();
  }

  /// Adds the [story] to [stories] with a [Panel] of [withPanel].
  void add({Story story, Panel withPanel, int atIndex}) {
    if (atIndex == null) {
      _stories.add(story.copyWith(panel: withPanel));
    } else {
      _stories.insert(atIndex, story.copyWith(panel: withPanel));
    }
    _notifyStoryListListeners();
  }

  /// Replaces the [Story.panel] of the story with [panel] with [withPanel]/
  void replace({Panel panel, Panel withPanel}) {
    Story story = _stories.where((Story story) => story.panel == panel).single;
    _replaceStory(story: story, withPanel: withPanel);
  }

  /// Replaces the [Story.panel] of the story with [storyId] with [withPanel]/
  void replaceStoryPanel({StoryId storyId, Panel withPanel}) {
    Story story = _stories.where((Story story) => story.id == storyId).single;
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

  set focusedStoryId(StoryId storyId) {
    if (storyId != _focusedStoryId) {
      _focusedStoryId = storyId;
      _notifyPanelListeners();
    }
  }

  StoryId get focusedStoryId => _focusedStoryId;

  void unFocus() {
    focusSimulationKey.currentState?.target = 0.0;
    stories.forEach((Story story) {
      story.storyBarKey.currentState?.minimize();
    });
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
