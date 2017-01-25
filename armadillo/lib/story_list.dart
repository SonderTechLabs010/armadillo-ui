// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'armadillo_overlay.dart';
import 'nothing.dart';
import 'simulation_builder.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_widget.dart';
import 'story_list_layout.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_model.dart';

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

const double _kStoryInlineTitleHeight = 20.0;

typedef void OnStoryClusterFocusCompleted(StoryCluster storyCluster);

class StoryList extends StatelessWidget {
  final ScrollListener onScroll;
  final VoidCallback onStoryClusterFocusStarted;
  final OnStoryClusterFocusCompleted onStoryClusterFocusCompleted;
  final double bottomPadding;
  final double quickSettingsHeightBump;
  final bool multiColumn;
  final Key scrollableKey;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final SizeModel sizeModel;

  StoryList({
    Key key,
    this.scrollableKey,
    this.overlayKey,
    this.bottomPadding,
    this.onScroll,
    this.onStoryClusterFocusStarted,
    this.onStoryClusterFocusCompleted,
    this.quickSettingsHeightBump,
    this.sizeModel,
    this.multiColumn: false,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    StoryModel storyModel = StoryModel.of(context, rebuildOnChange: true);

    // IMPORTANT:  In order for activation of inactive stories from suggestions
    // to work we must have them in the widget tree.
    List<Widget> stackChildren = new List<Widget>.from(
      storyModel.inactiveStoryClusters.map(
        (StoryCluster storyCluster) => new Positioned(
              width: 0.0,
              height: 0.0,
              child: new SimulationBuilder(
                key: storyCluster.focusSimulationKey,
                builder: (BuildContext context, double progress) =>
                    _createStoryCluster(
                      storyModel.activeSortedStoryClusters,
                      storyCluster,
                      0.0,
                      storyCluster.buildStoryWidgets(context),
                    ),
              ),
            ),
      ),
    );

    stackChildren.add(
      new Positioned(
        top: 0.0,
        left: 0.0,
        bottom: 0.0,
        right: 0.0,
        child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            sizeModel.size = new Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            return Nothing.widget;
          },
        ),
      ),
    );

    stackChildren.add(
      new StoryListBlock(
        scrollableKey: scrollableKey,
        bottomPadding: bottomPadding,
        onScroll: onScroll,
        listHeight: storyModel.listHeight,
        children: new List<Widget>.generate(
          storyModel.activeSortedStoryClusters.length,
          (int index) => _createFocusableStoryCluster(
                storyModel.activeSortedStoryClusters,
                storyModel.activeSortedStoryClusters[index],
                storyModel.activeSortedStoryClusters[index].buildStoryWidgets(
                  context,
                ),
              ),
        ),
      ),
    );

    stackChildren.add(new ArmadilloOverlay(key: overlayKey));

    return new ScopedModel<SizeModel>(
      model: sizeModel,
      child: new Stack(children: stackChildren),
    );
  }

  Widget _createFocusableStoryCluster(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
    Map<StoryId, Widget> storyWidgets,
  ) =>
      new SimulationBuilder(
        key: storyCluster.focusSimulationKey,
        onSimulationChanged: (double progress, bool isDone) {
          if (progress == 1.0 && isDone) {
            onStoryClusterFocusCompleted?.call(storyCluster);
          }
        },
        builder: (BuildContext context, double progress) => new StoryListChild(
              storyLayout: storyCluster.storyLayout,
              focusProgress: progress,
              child: _createStoryCluster(
                storyClusters,
                storyCluster,
                progress,
                storyWidgets,
              ),
            ),
      );

  Widget _createStoryCluster(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
    double progress,
    Map<StoryId, Widget> storyWidgets,
  ) =>
      new RepaintBoundary(
        child: new StoryClusterWidget(
          overlayKey: overlayKey,
          focusProgress: progress,
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
              storyCluster.focusSimulationKey.currentState?.forward();
              storyCluster.stories.forEach((Story story) {
                story.storyBarKey.currentState?.maximize();
              });

              onStoryClusterFocusStarted?.call();
            }
          },
          storyWidgets: storyWidgets,
        ),
      );

  bool _inFocus(StoryCluster s) =>
      (s.focusSimulationKey.currentState?.progress ?? 0.0) > 0.0;
}

class StoryListBlock extends Block {
  final double bottomPadding;
  final double listHeight;
  StoryListBlock({
    Key key,
    List<Widget> children,
    this.bottomPadding,
    ScrollListener onScroll,
    Key scrollableKey,
    this.listHeight,
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
          listHeight: listHeight,
          scrollableKey: scrollableKey,
          bottomPadding: bottomPadding,
        ),
      );
}

class StoryListBlockBody extends BlockBody {
  final Key scrollableKey;
  final double bottomPadding;
  final double listHeight;
  StoryListBlockBody({
    Key key,
    List<Widget> children,
    this.scrollableKey,
    this.bottomPadding,
    this.listHeight,
  })
      : super(key: key, mainAxis: Axis.vertical, children: children);

  @override
  StoryListRenderBlock createRenderObject(BuildContext context) =>
      new StoryListRenderBlock(
        parentSize: SizeModel.of(context, rebuildOnChange: true).size,
        scrollableKey: scrollableKey,
        bottomPadding: bottomPadding,
        listHeight: listHeight,
      );

  @override
  void updateRenderObject(
      BuildContext context, StoryListRenderBlock renderObject) {
    renderObject.mainAxis = mainAxis;
    renderObject.parentSize = SizeModel.of(context, rebuildOnChange: true).size;
    renderObject.scrollableKey = scrollableKey;
    renderObject.bottomPadding = bottomPadding;
    renderObject.listHeight = listHeight;
  }
}

class StoryListChild extends ParentDataWidget<StoryListBlockBody> {
  final StoryLayout storyLayout;
  final double focusProgress;
  StoryListChild({
    Widget child,
    this.storyLayout,
    this.focusProgress,
  })
      : super(child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListRenderBlockParentData);
    final StoryListRenderBlockParentData parentData = renderObject.parentData;
    parentData.storyLayout = storyLayout;
    parentData.focusProgress = focusProgress;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('storyLayout: $storyLayout, focusProgress: $focusProgress');
  }
}
