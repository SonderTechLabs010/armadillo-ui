// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'story.dart';

class StoryCluster {
  final Object id;
  final DateTime lastInteraction;
  final Duration cumulativeInteractionDuration;
  final List<Story> stories;
  final String title;
  final Object carouselId;

  StoryCluster({Object id, Object carouselId, List<Story> stories})
      : this.stories = stories,
        this.title = _getClusterTitle(stories),
        this.lastInteraction = _getClusterLastInteraction(stories),
        this.cumulativeInteractionDuration =
            _getClusterCumulativeInteractionDuration(stories),
        this.id = id ?? new Object(),
        this.carouselId = carouselId ?? new Object();

  StoryCluster copyWith({
    DateTime lastInteraction,
    Duration cumulativeInteractionDuration,
    bool inactive,
  }) =>
      new StoryCluster(
        id: this.id,
        carouselId: this.carouselId,
        stories: new List<Story>.generate(
          stories.length,
          (int index) => stories[index].copyWith(
                lastInteraction: lastInteraction,
                cumulativeInteractionDuration: cumulativeInteractionDuration,
                inactive: inactive,
              ),
        ),
      );

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(other) => (other is StoryCluster && other.id == id);

  static String _getClusterTitle(List<Story> stories) {
    String title = '';
    stories.forEach((Story story) {
      if (title.isNotEmpty) {
        title += ', ';
      }
      title += story.title;
    });
    return title;
  }

  static DateTime _getClusterLastInteraction(List<Story> stories) {
    DateTime latestTime = new DateTime(1970);
    stories.forEach((Story story) {
      if (latestTime.isBefore(story.lastInteraction)) {
        latestTime = story.lastInteraction;
      }
    });
    return latestTime;
  }

  static Duration _getClusterCumulativeInteractionDuration(
      List<Story> stories) {
    Duration largestDuration = new Duration();
    stories.forEach((Story story) {
      if (largestDuration < story.cumulativeInteractionDuration) {
        largestDuration = story.cumulativeInteractionDuration;
      }
    });
    return largestDuration;
  }
}
