// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.modular.lib.app.dart/app.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:armadillo/armadillo.dart';
import 'package:armadillo/armadillo_drag_target.dart';
import 'package:armadillo/child_constraints_changer.dart';
import 'package:armadillo/conductor.dart';
import 'package:armadillo/constraints_manager.dart';
import 'package:armadillo/now_manager.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_id.dart';
import 'package:armadillo/story.dart';
import 'package:armadillo/story_manager.dart';
import 'package:armadillo/story_time_randomizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'focus_controller_impl.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_manager.dart';
import 'user_shell_impl.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

/// This is global as we need it to be alive as long as we are.
UserShellImpl userShell;

Future main() async {
  StoryProviderStoryGenerator storyProviderStoryGenerator =
      new StoryProviderStoryGenerator();
  SuggestionProviderSuggestionManager suggestionProviderSuggestionManager =
      new SuggestionProviderSuggestionManager(
          storyGenerator: storyProviderStoryGenerator);

  StoryManager storyManager = new StoryManager(
    suggestionManager: suggestionProviderSuggestionManager,
    storyGenerator: storyProviderStoryGenerator,
  );

  Conductor conductor = new Conductor(useSoftKeyboard: false);
  FocusControllerImpl focusController =
      new FocusControllerImpl(onFocusStory: (String storyId) {
    conductor.requestStoryFocus(
      new StoryId(storyId),
      storyManager,
      jumpToFinish: false,
    );
  });

  userShell = new UserShellImpl(
    storyProviderStoryGenerator: storyProviderStoryGenerator,
    suggestionProviderSuggestionManager: suggestionProviderSuggestionManager,
    focusController: focusController,
  );

  new ApplicationContext.fromStartupInfo().outgoingServices.addServiceForName(
    (request) {
      userShell.bind(request);
    },
    UserShell.serviceName,
  );

  NowManager nowManager = new NowManager();
  ConstraintsManager constraintsManager = new ConstraintsManager();

  Widget app = _buildApp(
    storyManager: storyManager,
    storyProviderStoryGenerator: storyProviderStoryGenerator,
    constraintsManager: constraintsManager,
    armadillo: new Armadillo(
      storyManager: storyManager,
      suggestionManager: suggestionProviderSuggestionManager,
      nowManager: nowManager,
      conductor: conductor,
    ),
  );

  runApp(_kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app);

  constraintsManager.load(defaultBundle);
}

Widget _buildApp({
  StoryManager storyManager,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
  ConstraintsManager constraintsManager,
  Armadillo armadillo,
}) =>
    new StoryTimeRandomizer(
      storyManager: storyManager,
      child: new ChildConstraintsChanger(
        constraintsManager: constraintsManager,
        child: new DefaultAssetBundle(
          bundle: defaultBundle,
          child: new Stack(children: [
            armadillo,
            new Positioned(
              left: 0.0,
              top: 0.0,
              bottom: 0.0,
              width: 100.0,
              child: _buildDiscardDragTarget(
                storyManager: storyManager,
                storyProviderStoryGenerator: storyProviderStoryGenerator,
              ),
            ),
            new Positioned(
              right: 0.0,
              top: 0.0,
              bottom: 0.0,
              width: 100.0,
              child: _buildDiscardDragTarget(
                storyManager: storyManager,
                storyProviderStoryGenerator: storyProviderStoryGenerator,
              ),
            ),
          ]),
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

Widget _buildDiscardDragTarget({
  StoryManager storyManager,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
}) =>
    new ArmadilloDragTarget<StoryClusterId>(
      onWillAccept: (StoryClusterId storyClusterId, Point point) =>
          storyManager.storyClusters.every((StoryCluster storyCluster) =>
              storyCluster.focusSimulationKey.currentState.progress == 0.0),
      onAccept: (StoryClusterId storyClusterId, Point point) =>
          storyProviderStoryGenerator.removeStoryCluster(storyClusterId),
      builder: (
        BuildContext context,
        Map<StoryClusterId, Point> candidateData,
        Map<dynamic, Point> rejectedData,
      ) =>
          new IgnorePointer(
            child: new Container(
              decoration: new BoxDecoration(
                backgroundColor: new Color(
                  candidateData.isEmpty ? 0x00FF0000 : 0x40FF0000,
                ),
              ),
            ),
          ),
    );
