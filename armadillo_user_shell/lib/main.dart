// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:application.lib.app.dart/app.dart';
import 'package:armadillo/armadillo.dart';
import 'package:armadillo/armadillo_drag_target.dart';
import 'package:armadillo/conductor.dart';
import 'package:armadillo/debug_enabler.dart';
import 'package:armadillo/debug_model.dart';
import 'package:armadillo/now_model.dart';
import 'package:armadillo/panel_resizing_model.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_drag_data.dart';
import 'package:armadillo/story_cluster_drag_state_model.dart';
import 'package:armadillo/story.dart';
import 'package:armadillo/story_drag_transition_model.dart';
import 'package:armadillo/story_model.dart';
import 'package:armadillo/story_rearrangement_scrim_model.dart';
import 'package:armadillo/story_time_randomizer.dart';
import 'package:armadillo/suggestion_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'focus_request_watcher_impl.dart';
import 'hit_test_model.dart';
import 'initial_focus_setter.dart';
import 'initial_story_generator.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_model.dart';
import 'user_logoutter.dart';
import 'user_shell_impl.dart';
import 'user_shell_widget.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

/// Set to true to enable dumping of all errors, not just the first one.
const bool _kDumpAllErrors = false;

Future<Null> main() async {
  if (_kDumpAllErrors) {
    FlutterError.onError =
        (FlutterErrorDetails details) => FlutterError.dumpErrorToConsole(
              details,
              forceReport: true,
            );
  }

  HitTestModel hitTestModel = new HitTestModel();
  InitialStoryGenerator initialStoryGenerator = new InitialStoryGenerator()
    ..load(defaultBundle);
  InitialFocusSetter initialFocusSetter = new InitialFocusSetter();

  StoryProviderStoryGenerator storyProviderStoryGenerator =
      new StoryProviderStoryGenerator(
    onNoStories: initialStoryGenerator.createStories,
    onStoriesFirstAvailable: initialFocusSetter.onStoriesFirstAvailable,
  );
  StoryClusterDragStateModel storyClusterDragStateModel =
      new StoryClusterDragStateModel();
  StoryRearrangementScrimModel storyRearrangementScrimModel =
      new StoryRearrangementScrimModel();
  storyClusterDragStateModel.addListener(
    () => storyRearrangementScrimModel
        .onDragAcceptableStateChanged(storyClusterDragStateModel.isAcceptable),
  );
  StoryDragTransitionModel storyDragTransitionModel =
      new StoryDragTransitionModel();
  storyClusterDragStateModel.addListener(
    () => storyDragTransitionModel
        .onDragStateChanged(storyClusterDragStateModel.isDragging),
  );

  UserLogoutter userLogoutter = new UserLogoutter();
  Conductor conductor = new Conductor(
    useSoftKeyboard: false,
    blurScrimmedChildren: false,
    onQuickSettingsOverlayChanged: hitTestModel.onQuickSettingsOverlayChanged,
    onSuggestionsOverlayChanged: hitTestModel.onSuggestionsOverlayChanged,
    storyClusterDragStateModel: storyClusterDragStateModel,
    onLogoutSelected: userLogoutter.logout,
  );
  SuggestionProviderSuggestionModel suggestionProviderSuggestionModel =
      new SuggestionProviderSuggestionModel(hitTestModel: hitTestModel);

  StoryModel storyModel = new StoryModel(
    onFocusChanged: suggestionProviderSuggestionModel.storyClusterFocusChanged,
  );
  storyProviderStoryGenerator.addListener(
    () => storyModel.onStoryClustersChanged(
          storyProviderStoryGenerator.storyClusters,
        ),
  );

  suggestionProviderSuggestionModel.storyModel = storyModel;
  suggestionProviderSuggestionModel.addOnFocusLossListener(() {
    conductor.goToOrigin(storyModel);
  });

  StoryFocuser storyFocuser = (String storyId) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      conductor.requestStoryFocus(
        new StoryId(storyId),
        storyModel,
        jumpToFinish: false,
      );
    });
  };

  initialFocusSetter.storyFocuser = storyFocuser;

  FocusRequestWatcherImpl focusRequestWatcher = new FocusRequestWatcherImpl(
    onFocusRequest: (String storyId) {
      // If we don't know about the story that we've been asked to focus, update
      // the story list first.
      if (!storyProviderStoryGenerator.containsStory(storyId)) {
        storyProviderStoryGenerator.update(() => storyFocuser(storyId));
      } else {
        storyFocuser(storyId);
      }
    },
  );

  NowModel nowModel = new NowModel();
  DebugModel debugModel = new DebugModel();
  PanelResizingModel panelResizingModel = new PanelResizingModel();

  Widget app = _buildApp(
    storyModel: storyModel,
    storyProviderStoryGenerator: storyProviderStoryGenerator,
    debugModel: debugModel,
    armadillo: new Armadillo(
      scopedModelBuilders: <WrapperBuilder>[
        (_, Widget child) => new ScopedModel<StoryModel>(
              model: storyModel,
              child: child,
            ),
        (_, Widget child) => new ScopedModel<SuggestionModel>(
              model: suggestionProviderSuggestionModel,
              child: child,
            ),
        (_, Widget child) => new ScopedModel<NowModel>(
              model: nowModel,
              child: child,
            ),
        (_, Widget child) => new ScopedModel<StoryClusterDragStateModel>(
              model: storyClusterDragStateModel,
              child: child,
            ),
        (_, Widget child) => new ScopedModel<StoryRearrangementScrimModel>(
              model: storyRearrangementScrimModel,
              child: child,
            ),
        (_, Widget child) => new ScopedModel<StoryDragTransitionModel>(
              model: storyDragTransitionModel,
              child: child,
            ),
        (_, Widget child) => new ScopedModel<DebugModel>(
              model: debugModel,
              child: child,
            ),
        (_, Widget child) => new ScopedModel<PanelResizingModel>(
              model: panelResizingModel,
              child: child,
            ),
      ],
      conductor: conductor,
    ),
    hitTestModel: hitTestModel,
  );

  UserShellWidget userShellWidget = new UserShellWidget(
    applicationContext: new ApplicationContext.fromStartupInfo(),
    userShell: new UserShellImpl(
      storyProviderStoryGenerator: storyProviderStoryGenerator,
      suggestionProviderSuggestionModel: suggestionProviderSuggestionModel,
      focusRequestWatcher: focusRequestWatcher,
      initialFocusSetter: initialFocusSetter,
      userLogoutter: userLogoutter,
    ),
    child:
        _kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app,
  )..advertise();

  runApp(
    new MediaQuery(
      data: const MediaQueryData(),
      child: userShellWidget,
    ),
  );
}

Widget _buildApp({
  StoryModel storyModel,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
  DebugModel debugModel,
  Armadillo armadillo,
  HitTestModel hitTestModel,
}) =>
    new StoryTimeRandomizer(
      storyModel: storyModel,
      child: new DebugEnabler(
        debugModel: debugModel,
        child: new DefaultAssetBundle(
          bundle: defaultBundle,
          child: new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new ScopedModel<HitTestModel>(
                model: hitTestModel,
                child: armadillo,
              ),
              new FractionallySizedBox(
                widthFactor: 0.1,
                heightFactor: 1.0,
                alignment: FractionalOffset.centerLeft,
                child: _buildDiscardDragTarget(
                  storyModel: storyModel,
                  storyProviderStoryGenerator: storyProviderStoryGenerator,
                ),
              ),
              new FractionallySizedBox(
                widthFactor: 0.1,
                heightFactor: 1.0,
                alignment: FractionalOffset.centerRight,
                child: _buildDiscardDragTarget(
                  storyModel: storyModel,
                  storyProviderStoryGenerator: storyProviderStoryGenerator,
                ),
              ),
            ],
          ),
        ),
      ),
    );

Widget _buildPerformanceOverlay({Widget child}) => new Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        new Positioned(
          top: 0.0,
          left: 0.0,
          right: 0.0,
          child: new PerformanceOverlay.allEnabled(),
        ),
      ],
    );

Widget _buildDiscardDragTarget({
  StoryModel storyModel,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
}) =>
    new ArmadilloDragTarget<StoryClusterDragData>(
      onWillAccept: (_, __) => storyModel.storyClusters.every(
          (StoryCluster storyCluster) =>
              storyCluster.focusSimulationKey.currentState.progress == 0.0),
      onAccept: (StoryClusterDragData data, _, __) =>
          storyProviderStoryGenerator.removeStoryCluster(
            data.id,
          ),
      builder: (_, Map<StoryClusterDragData, Offset> candidateData, __) =>
          new IgnorePointer(
            child: new Container(
              color: new Color(
                candidateData.isEmpty ? 0x00FF0000 : 0x40FF0000,
              ),
            ),
          ),
    );
