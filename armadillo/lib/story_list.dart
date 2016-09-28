// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'simulation_builder.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_widget.dart';
import 'story_keys.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_manager.dart';

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

const double _kStoryInlineTitleHeight = 20.0;

typedef void OnStoryClusterFocusCompleted(StoryCluster storyCluster);

class StoryList extends StatelessWidget {
  final ScrollListener onScroll;
  final VoidCallback onStoryClusterFocusStarted;
  final OnStoryClusterFocusCompleted onStoryClusterFocusCompleted;
  final double bottomPadding;
  final Size parentSize;
  final double quickSettingsHeightBump;
  final bool multiColumn;
  final Key scrollableKey;

  StoryList({
    Key key,
    this.scrollableKey,
    this.bottomPadding,
    this.onScroll,
    this.onStoryClusterFocusStarted,
    this.onStoryClusterFocusCompleted,
    this.parentSize,
    this.quickSettingsHeightBump,
    this.multiColumn: false,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<StoryCluster> storyClusters = new List<StoryCluster>.from(
      InheritedStoryManager.of(context).storyClusters,
    );

    // Remove clusters with any inactive stories.
    List<StoryCluster> inactiveStoryClusters = <StoryCluster>[];
    storyClusters.removeWhere(
      (StoryCluster storyCluster) {
        bool clusterInactive =
            !storyCluster.stories.every((Story story) => !story.inactive);
        if (clusterInactive) {
          inactiveStoryClusters.add(storyCluster);
        }
        return clusterInactive;
      },
    );

    // Sort recently interacted with stories to the start of the list.
    storyClusters.sort((StoryCluster a, StoryCluster b) =>
        b.lastInteraction.millisecondsSinceEpoch -
        a.lastInteraction.millisecondsSinceEpoch);

    // IMPORTANT:  In order for activation of inactive stories from suggestions
    // to work we must have them in the widget tree.
    List<Widget> stackChildren = new List.from(
      inactiveStoryClusters.map(
        (StoryCluster storyCluster) => new Offstage(
              offstage: true,
              child: new SimulationBuilder(
                key: StoryKeys.storyClusterFocusSimulationKey(storyCluster),
                builder: (BuildContext context, double progress) =>
                    _createStoryCluster(storyClusters, storyCluster, 0.0),
              ),
            ),
      ),
    );

    stackChildren.add(
      new StoryListBlock(
        scrollableKey: scrollableKey,
        bottomPadding: bottomPadding,
        onScroll: onScroll,
        parentSize: parentSize,
        children: storyClusters
            .map((StoryCluster storyCluster) =>
                _createFocusableStoryCluster(storyClusters, storyCluster))
            .toList(),
      ),
    );

    return new Stack(children: stackChildren);
  }

  Widget _createFocusableStoryCluster(
          List<StoryCluster> storyClusters, StoryCluster storyCluster) =>
      new SimulationBuilder(
        key: StoryKeys.storyClusterFocusSimulationKey(storyCluster),
        onSimulationChanged: (double progress, bool isDone) {
          if (progress == 1.0 && isDone) {
            onStoryClusterFocusCompleted?.call(storyCluster);
          }
        },
        builder: (BuildContext context, double progress) => new StoryListChild(
              storyCluster: storyCluster,
              focusProgress: progress,
              child: _createStoryCluster(storyClusters, storyCluster, progress),
            ),
      );

  Widget _createStoryCluster(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
    double progress,
  ) =>
      new StoryClusterWidget(
          focusProgress: progress,
          fullSize: parentSize,
          storyCluster: storyCluster,
          multiColumn: multiColumn,
          onGainFocus: () {
            bool storyClusterInFocus = false;
            storyClusters.forEach((StoryCluster s) {
              if (_inFocus(s)) {
                storyClusterInFocus = true;
              }
            });

            if (!storyClusterInFocus) {
              // Bring tapped story into focus.
              StoryKeys
                  .storyClusterFocusSimulationKey(storyCluster)
                  .currentState
                  ?.forward();
              storyCluster.stories.forEach((Story story) {
                StoryKeys.storyBarKey(story).currentState?.maximize();
              });

              onStoryClusterFocusStarted?.call();
            }
          });

  bool _inFocus(StoryCluster s) =>
      (StoryKeys.storyClusterFocusSimulationKey(s).currentState?.progress ??
          0.0) >
      0.0;
}

class StoryListBlock extends Block {
  final Size parentSize;
  final double bottomPadding;
  StoryListBlock({
    Key key,
    List<Widget> children,
    this.bottomPadding,
    ScrollListener onScroll,
    Key scrollableKey,
    this.parentSize,
  })
      : super(
          key: key,
          children: children,
          scrollDirection: Axis.vertical,
          scrollAnchor: ViewportAnchor.end,
          onScroll: onScroll,
          scrollableKey: scrollableKey,
        ) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  @override
  Widget build(BuildContext context) => new ScrollableViewport(
        scrollableKey: scrollableKey,
        initialScrollOffset: initialScrollOffset,
        scrollDirection: scrollDirection,
        scrollAnchor: scrollAnchor,
        onScrollStart: onScrollStart,
        onScroll: onScroll,
        onScrollEnd: onScrollEnd,
        child: new StoryListBlockBody(
          children: children,
          parentSize: parentSize,
          scrollOffset: (scrollableKey as GlobalKey<ScrollableState>)
                  .currentState
                  ?.scrollOffset ??
              0.0,
          bottomPadding: bottomPadding,
        ),
      );
}

class StoryListBlockBody extends BlockBody {
  final Size parentSize;
  final double scrollOffset;
  final double bottomPadding;
  StoryListBlockBody({
    Key key,
    List<Widget> children,
    this.parentSize,
    this.scrollOffset,
    this.bottomPadding,
  })
      : super(key: key, mainAxis: Axis.vertical, children: children);

  @override
  StoryListRenderBlock createRenderObject(BuildContext context) =>
      new StoryListRenderBlock(
        parentSize: parentSize,
        scrollOffset: scrollOffset,
        bottomPadding: bottomPadding,
      );

  @override
  void updateRenderObject(
      BuildContext context, StoryListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
    renderObject.parentSize = parentSize;
    renderObject.scrollOffset = scrollOffset;
    renderObject.bottomPadding = bottomPadding;
  }
}

class StoryListChild extends ParentDataWidget<StoryListBlockBody> {
  final StoryCluster storyCluster;
  final double focusProgress;
  StoryListChild({
    Widget child,
    this.storyCluster,
    this.focusProgress,
  })
      : super(child: child);
  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListRenderBlockParentData);
    final StoryListRenderBlockParentData parentData = renderObject.parentData;
    parentData.storyCluster = storyCluster;
    parentData.focusProgress = focusProgress;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description
        .add('storyCluster: $storyCluster, focusProgress: $focusProgress');
  }
}
