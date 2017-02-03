// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'armadillo.dart';
import 'child_constraints_changer.dart';
import 'conductor.dart';
import 'constraints_model.dart';
import 'json_story_generator.dart';
import 'json_suggestion_model.dart';
import 'now_model.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_model.dart';
import 'story_time_randomizer.dart';
import 'story_rearrangement_scrim_model.dart';
import 'suggestion_model.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

Future<Null> main() async {
  JsonSuggestionModel jsonSuggestionModel = new JsonSuggestionModel();
  JsonStoryGenerator jsonStoryGenerator = new JsonStoryGenerator();
  StoryModel storyModel = new StoryModel(
    suggestionModel: jsonSuggestionModel,
    storyGenerator: jsonStoryGenerator,
  );
  NowModel nowModel = new NowModel();
  ConstraintsModel constraintsModel = new ConstraintsModel();
  StoryClusterDragStateModel storyClusterDragStateModel =
      new StoryClusterDragStateModel();
  StoryRearrangementScrimModel storyRearrangementScrimModel =
      new StoryRearrangementScrimModel(
    storyClusterDragStateModel: storyClusterDragStateModel,
  );

  Widget app = _buildApp(
    suggestionModel: jsonSuggestionModel,
    storyModel: storyModel,
    nowModel: nowModel,
    constraintsModel: constraintsModel,
    storyClusterDragStateModel: storyClusterDragStateModel,
    storyRearrangementScrimModel: storyRearrangementScrimModel,
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
}) =>
    new CheckedModeBanner(
      child: new StoryTimeRandomizer(
        storyModel: storyModel,
        child: new ChildConstraintsChanger(
          constraintsModel: constraintsModel,
          child: new DefaultAssetBundle(
            bundle: defaultBundle,
            child: new Armadillo(
              storyModel: storyModel,
              suggestionModel: suggestionModel,
              nowModel: nowModel,
              storyClusterDragStateModel: storyClusterDragStateModel,
              storyRearrangementScrimModel: storyRearrangementScrimModel,
              conductor: new Conductor(
                storyClusterDragStateModel: storyClusterDragStateModel,
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
