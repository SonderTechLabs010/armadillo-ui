// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:ui' as ui;

import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.lib.app.dart/app.dart';
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:apps.modular.services.user/story_provider.fidl.dart';
import 'package:apps.modular.services.user/user_runner.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:armadillo/armadillo.dart';
import 'package:armadillo/armadillo_drag_target.dart';
import 'package:armadillo/child_constraints_changer.dart';
import 'package:armadillo/conductor.dart';
import 'package:armadillo/constraints_manager.dart';
import 'package:armadillo/now_manager.dart';
import 'package:armadillo/rounded_corner_decoration.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_id.dart';
import 'package:armadillo/story_manager.dart';
import 'package:armadillo/story_time_randomizer.dart';
import 'package:armadillo/suggestion_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'debug.dart';
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
      new SuggestionProviderSuggestionManager();

  userShell = new UserShellImpl(
    storyProviderStoryGenerator: storyProviderStoryGenerator,
    suggestionProviderSuggestionManager: suggestionProviderSuggestionManager,
  );

  new ApplicationContext.fromStartupInfo().outgoingServices.addServiceForName(
    (request) {
      userShell.bind(request);
    },
    UserShell.serviceName,
  );

  StoryManager storyManager = new StoryManager(
    suggestionManager: suggestionProviderSuggestionManager,
    storyGenerator: storyProviderStoryGenerator,
  );
  NowManager nowManager = new NowManager();
  ConstraintsManager constraintsManager = new ConstraintsManager();

  Widget app = _buildApp(
    suggestionManager: suggestionProviderSuggestionManager,
    storyManager: storyManager,
    nowManager: nowManager,
    constraintsManager: constraintsManager,
    storyProviderStoryGenerator: storyProviderStoryGenerator,
  );

  runApp(_kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app);

  SystemChrome.setEnabledSystemUIOverlays([]);
  constraintsManager.load(defaultBundle);
}

Widget _buildApp({
  SuggestionManager suggestionManager,
  StoryManager storyManager,
  NowManager nowManager,
  ConstraintsManager constraintsManager,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
}) =>
    new DefaultAssetBundle(
      bundle: defaultBundle,
      child: new Stack(children: [
        new Armadillo(
          storyManager: storyManager,
          suggestionManager: suggestionManager,
          nowManager: nowManager,
          useSoftKeyboard: false,
        ),
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
          new Container(
            decoration: new BoxDecoration(
              backgroundColor: new Color(
                candidateData.isEmpty ? 0x10FF0000 : 0x80FF0000,
              ),
            ),
          ),
    );
