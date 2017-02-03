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
import 'story_cluster_drag_state_model.dart';
import 'story_cluster_widget.dart';
import 'story_list_layout.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_model.dart';
import 'story_rearrangement_scrim_model.dart';

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
                initValue: 0.0,
                targetValue: 1.0,
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
                context,
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
    BuildContext context,
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
    Map<StoryId, Widget> storyWidgets,
  ) =>
      new SimulationBuilder(
        key: storyCluster.liftScaleSimulationKey,
        initValue: 1.0,
        targetValue: StoryClusterDragStateModel
                .of(context, rebuildOnChange: true)
                .isDragging
            ? 0.9
            : 1.0,
        builder: (BuildContext context, double liftScaleProgress) =>
            new SimulationBuilder(
              key: storyCluster.inlinePreviewScaleSimulationKey,
              initValue: 0.0,
              targetValue: 0.0,
              builder: (BuildContext context,
                      double inlinePreviewScaleProgress) =>
                  new SimulationBuilder(
                    key: storyCluster.focusSimulationKey,
                    initValue: 0.0,
                    targetValue: 0.0,
                    onSimulationChanged: (double focusProgress, bool isDone) {
                      if (focusProgress == 1.0 && isDone) {
                        onStoryClusterFocusCompleted?.call(storyCluster);
                      }
                    },
                    builder: (BuildContext context, double focusProgress) =>
                        new StoryListChild(
                          storyLayout: storyCluster.storyLayout,
                          focusProgress: focusProgress,
                          inlinePreviewScaleProgress:
                              inlinePreviewScaleProgress,
                          liftScaleProgress: liftScaleProgress,
                          child: _createStoryCluster(
                            storyClusters,
                            storyCluster,
                            focusProgress,
                            storyWidgets,
                          ),
                        ),
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
              storyCluster.focusSimulationKey.currentState?.target = 1.0;

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
        scrimColor: StoryRearrangementScrimModel
            .of(context, rebuildOnChange: true)
            .scrimColor,
      );

  @override
  void updateRenderObject(BuildContext context, RenderBlock renderObject) {
    StoryListRenderBlock storyListRenderBlock = renderObject;
    storyListRenderBlock.mainAxis = mainAxis;
    storyListRenderBlock.parentSize =
        SizeModel.of(context, rebuildOnChange: true).size;
    storyListRenderBlock.scrollableKey = scrollableKey;
    storyListRenderBlock.bottomPadding = bottomPadding;
    storyListRenderBlock.listHeight = listHeight;
    storyListRenderBlock.scrimColor = StoryRearrangementScrimModel
        .of(context, rebuildOnChange: true)
        .scrimColor;
  }
}

class StoryListChild extends ParentDataWidget<StoryListBlockBody> {
  final StoryLayout storyLayout;
  final double focusProgress;
  final double liftScaleProgress;
  final double inlinePreviewScaleProgress;

  StoryListChild({
    Widget child,
    this.storyLayout,
    this.focusProgress,
    this.liftScaleProgress,
    this.inlinePreviewScaleProgress,
  })
      : super(child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListRenderBlockParentData);
    final StoryListRenderBlockParentData parentData = renderObject.parentData;
    parentData.storyLayout = storyLayout;
    parentData.focusProgress = focusProgress;
    parentData.liftScaleProgress = liftScaleProgress;
    parentData.inlinePreviewScaleProgress = inlinePreviewScaleProgress;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add(
        'storyLayout: $storyLayout, focusProgress: $focusProgress, liftScaleProgress: $liftScaleProgress, inlinePreviewScaleProgress: $inlinePreviewScaleProgress');
  }
}
