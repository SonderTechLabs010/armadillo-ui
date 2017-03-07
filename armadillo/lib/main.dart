// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'armadillo.dart';
import 'child_constraints_changer.dart';
import 'conductor.dart';
import 'constraints_model.dart';
import 'debug_enabler.dart';
import 'debug_model.dart';
import 'json_story_generator.dart';
import 'json_suggestion_model.dart';
import 'now_model.dart';
import 'panel_resizing_model.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_drag_transition_model.dart';
import 'story_model.dart';
import 'story_time_randomizer.dart';
import 'story_rearrangement_scrim_model.dart';
import 'suggestion_model.dart';

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

  JsonSuggestionModel jsonSuggestionModel = new JsonSuggestionModel();
  JsonStoryGenerator jsonStoryGenerator = new JsonStoryGenerator();
  StoryModel storyModel = new StoryModel(
    onFocusChanged: jsonSuggestionModel.storyClusterFocusChanged,
  );
  jsonStoryGenerator.addListener(
    () => storyModel.onStoryClustersChanged(jsonStoryGenerator.storyClusters),
  );

  NowModel nowModel = new NowModel();
  DebugModel debugModel = new DebugModel();
  PanelResizingModel panelResizingModel = new PanelResizingModel();
  ConstraintsModel constraintsModel = new ConstraintsModel();
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

  Widget app = _buildApp(
    suggestionModel: jsonSuggestionModel,
    storyModel: storyModel,
    nowModel: nowModel,
    constraintsModel: constraintsModel,
    storyClusterDragStateModel: storyClusterDragStateModel,
    storyRearrangementScrimModel: storyRearrangementScrimModel,
    storyDragTransitionModel: storyDragTransitionModel,
    debugModel: debugModel,
    panelResizingModel: panelResizingModel,
  );

  runApp(_kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app);

  await SystemChrome.setEnabledSystemUIOverlays(<SystemUiOverlay>[]);
  jsonStoryGenerator.load(defaultBundle);
  jsonSuggestionModel.load(defaultBundle);
  constraintsModel.load(defaultBundle);
}

Widget _buildApp({
  SuggestionModel suggestionModel,
  StoryModel storyModel,
  NowModel nowModel,
  ConstraintsModel constraintsModel,
  StoryClusterDragStateModel storyClusterDragStateModel,
  StoryRearrangementScrimModel storyRearrangementScrimModel,
  StoryDragTransitionModel storyDragTransitionModel,
  DebugModel debugModel,
  PanelResizingModel panelResizingModel,
}) =>
    new CheckedModeBanner(
      child: new StoryTimeRandomizer(
        storyModel: storyModel,
        child: new ChildConstraintsChanger(
          constraintsModel: constraintsModel,
          child: new DebugEnabler(
            debugModel: debugModel,
            child: new DefaultAssetBundle(
              bundle: defaultBundle,
              child: new Armadillo(
                storyModel: storyModel,
                suggestionModel: suggestionModel,
                nowModel: nowModel,
                storyClusterDragStateModel: storyClusterDragStateModel,
                storyRearrangementScrimModel: storyRearrangementScrimModel,
                storyDragTransitionModel: storyDragTransitionModel,
                debugModel: debugModel,
                panelResizingModel: panelResizingModel,
                conductor: new Conductor(
                  storyClusterDragStateModel: storyClusterDragStateModel,
                ),
              ),
            ),
          ),
        ),
      ),
    );

Widget _buildPerformanceOverlay({Widget child}) => new Stack(
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
