// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/rk4_spring_simulation.dart';

import 'armadillo_overlay.dart';
import 'nothing.dart';
import 'simulation_builder.dart';
import 'size_model.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_cluster_widget.dart';
import 'story_drag_transition_model.dart';
import 'story_list_layout.dart';
import 'story_list_render_block.dart';
import 'story_list_render_block_parent_data.dart';
import 'story_model.dart';
import 'story_rearrangement_scrim_model.dart';

/// In multicolumn mode, the distance the right column will be offset up.
const double _kRightBump = 64.0;

const double _kStoryInlineTitleHeight = 20.0;

const RK4SpringDescription _kInlinePreviewSimulationDesc =
    const RK4SpringDescription(tension: 900.0, friction: 50.0);

typedef void OnStoryClusterFocusCompleted(StoryCluster storyCluster);

class StoryList extends StatelessWidget {
  final ValueChanged<double> onScroll;
  final VoidCallback onStoryClusterFocusStarted;
  final OnStoryClusterFocusCompleted onStoryClusterFocusCompleted;
  final double bottomPadding;
  final double quickSettingsHeightBump;
  final bool multiColumn;
  final ScrollController scrollController;
  final GlobalKey<ArmadilloOverlayState> overlayKey;
  final SizeModel sizeModel;
  final VoidCallback onStoryClusterVerticalEdgeHover;

  StoryList({
    Key key,
    this.scrollController,
    this.overlayKey,
    this.bottomPadding,
    this.onScroll,
    this.onStoryClusterFocusStarted,
    this.onStoryClusterFocusCompleted,
    this.quickSettingsHeightBump,
    this.sizeModel,
    this.onStoryClusterVerticalEdgeHover,
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
        scrollController: scrollController,
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
        key: storyCluster.inlinePreviewHintScaleSimulationKey,
        springDescription: _kInlinePreviewSimulationDesc,
        initValue: 0.0,
        targetValue: 0.0,
        builder: (
          BuildContext context,
          double inlinePreviewHintScaleProgress,
        ) =>
            new SimulationBuilder(
              key: storyCluster.inlinePreviewScaleSimulationKey,
              springDescription: _kInlinePreviewSimulationDesc,
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
                          inlinePreviewHintScaleProgress:
                              inlinePreviewHintScaleProgress,
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
          onAccept: () {
            if (!_inFocus(storyCluster)) {
              _onGainFocus(storyClusters, storyCluster);
            }
          },
          onTap: () => _onGainFocus(storyClusters, storyCluster),
          onVerticalEdgeHover: onStoryClusterVerticalEdgeHover,
          storyWidgets: storyWidgets,
        ),
      );

  bool _inFocus(StoryCluster s) =>
      (s.focusSimulationKey.currentState?.progress ?? 0.0) > 0.0;

  void _onGainFocus(
    List<StoryCluster> storyClusters,
    StoryCluster storyCluster,
  ) {
    // Defocus any focused stories.
    storyClusters.forEach((StoryCluster s) {
      if (_inFocus(s)) {
        s.unFocus();
      }
    });

    // Bring tapped story into focus.
    storyCluster.focusSimulationKey.currentState?.target = 1.0;

    storyCluster.stories.forEach((Story story) {
      story.storyBarKey.currentState?.maximize();
    });

    onStoryClusterFocusStarted?.call();
  }
}

class StoryListBlock extends StatelessWidget {
  final double bottomPadding;
  final double listHeight;
  final ValueChanged<double> onScroll;
  final ScrollController scrollController;
  final List<Widget> children;

  StoryListBlock({
    Key key,
    this.children,
    this.bottomPadding,
    this.onScroll,
    this.scrollController,
    this.listHeight,
  })
      : super(
          key: key,
        ) {
    assert(children != null);
    assert(!children.any((Widget child) => child == null));
  }

  @override
  Widget build(BuildContext context) =>
      new NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification notification) {
          if (notification is ScrollUpdateNotification &&
              notification.depth == 0) {
            onScroll?.call(notification.metrics.extentBefore);
          }
          return false;
        },
        child: new SingleChildScrollView(
          reverse: true,
          controller: scrollController,
          child: new StoryListBlockBody(
            children: children,
            listHeight: listHeight,
            scrollController: scrollController,
            bottomPadding: bottomPadding,
          ),
        ),
      );
}

class StoryListBlockBody extends MultiChildRenderObjectWidget {
  final ScrollController scrollController;
  final double bottomPadding;
  final double listHeight;
  StoryListBlockBody({
    Key key,
    List<Widget> children,
    this.scrollController,
    this.bottomPadding,
    this.listHeight,
  })
      : super(key: key, children: children);

  @override
  StoryListRenderBlock createRenderObject(BuildContext context) =>
      new StoryListRenderBlock(
        parentSize: SizeModel.of(context, rebuildOnChange: true).size,
        scrollController: scrollController,
        bottomPadding: bottomPadding,
        listHeight: listHeight,
        scrimColor: StoryRearrangementScrimModel
            .of(context, rebuildOnChange: true)
            .scrimColor,
        liftScale: lerpDouble(
          1.0,
          0.9,
          StoryDragTransitionModel.of(context, rebuildOnChange: true).progress,
        ),
      );

  @override
  void updateRenderObject(BuildContext context, RenderBlock renderObject) {
    StoryListRenderBlock storyListRenderBlock = renderObject;
    storyListRenderBlock.mainAxis = Axis.vertical;
    storyListRenderBlock.parentSize =
        SizeModel.of(context, rebuildOnChange: true).size;
    storyListRenderBlock.scrollController = scrollController;
    storyListRenderBlock.bottomPadding = bottomPadding;
    storyListRenderBlock.listHeight = listHeight;
    storyListRenderBlock.scrimColor = StoryRearrangementScrimModel
        .of(context, rebuildOnChange: true)
        .scrimColor;
    storyListRenderBlock.liftScale = lerpDouble(
      1.0,
      0.9,
      StoryDragTransitionModel.of(context, rebuildOnChange: true).progress,
    );
  }
}

class StoryListChild extends ParentDataWidget<StoryListBlockBody> {
  final StoryLayout storyLayout;
  final double focusProgress;
  final double inlinePreviewScaleProgress;
  final double inlinePreviewHintScaleProgress;

  StoryListChild({
    Widget child,
    this.storyLayout,
    this.focusProgress,
    this.inlinePreviewScaleProgress,
    this.inlinePreviewHintScaleProgress,
  })
      : super(child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is StoryListRenderBlockParentData);
    final StoryListRenderBlockParentData parentData = renderObject.parentData;
    parentData.storyLayout = storyLayout;
    parentData.focusProgress = focusProgress;
    parentData.inlinePreviewScaleProgress = inlinePreviewScaleProgress;
    parentData.inlinePreviewHintScaleProgress = inlinePreviewHintScaleProgress;
  }

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add(
      'storyLayout: $storyLayout, '
          'focusProgress: $focusProgress, '
          'inlinePreviewScaleProgress: $inlinePreviewScaleProgress, '
          'inlinePreviewHintScaleProgress: $inlinePreviewHintScaleProgress',
    );
  }
}
