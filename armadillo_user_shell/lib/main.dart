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
import 'package:sysui_widgets/default_bundle.dart';

import 'focus_controller_impl.dart';
import 'hit_test_manager.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_manager.dart';
import 'user_shell_impl.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

/// This is global as we need it to be alive as long as we are.
UserShellImpl _userShell;

/// This is global as we need it to be alive as long as we are.
ApplicationContext _applicationContext;

Future main() async {
  HitTestManager hitTestManager = new HitTestManager();
  StoryProviderStoryGenerator storyProviderStoryGenerator =
      new StoryProviderStoryGenerator();
  SuggestionProviderSuggestionManager suggestionProviderSuggestionManager =
      new SuggestionProviderSuggestionManager(
    storyGenerator: storyProviderStoryGenerator,
    hitTestManager: hitTestManager,
  );

  StoryManager storyManager = new StoryManager(
    suggestionManager: suggestionProviderSuggestionManager,
    storyGenerator: storyProviderStoryGenerator,
  );

  Conductor conductor = new Conductor(
    useSoftKeyboard: false,
    onQuickSettingsOverlayChanged: hitTestManager.onQuickSettingsOverlayChanged,
    onSuggestionsOverlayChanged: hitTestManager.onSuggestionsOverlayChanged,
  );
  FocusControllerImpl focusController =
      new FocusControllerImpl(onFocusStory: (String storyId) {
    // If we don't know about the story that we've been asked to focus, update
    // the story list first.
    VoidCallback focusOnStory = () {
      conductor.requestStoryFocus(
        new StoryId(storyId),
        storyManager,
        jumpToFinish: false,
      );
    };
    if (storyProviderStoryGenerator.storyClusters
        .expand((cluster) => cluster.stories)
        .any((Story story) => story.id == new StoryId(storyId))) {
      storyProviderStoryGenerator.update(focusOnStory);
    } else {
      focusOnStory();
    }
  });

  _userShell = new UserShellImpl(
    storyProviderStoryGenerator: storyProviderStoryGenerator,
    suggestionProviderSuggestionManager: suggestionProviderSuggestionManager,
    focusController: focusController,
  );

  _applicationContext = new ApplicationContext.fromStartupInfo();
  _applicationContext.outgoingServices.addServiceForName(
    (request) {
      _userShell.bind(request);
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
    hitTestManager: hitTestManager,
  );

  runApp(_kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app);

  constraintsManager.load(defaultBundle);
}

Widget _buildApp({
  StoryManager storyManager,
  StoryProviderStoryGenerator storyProviderStoryGenerator,
  ConstraintsManager constraintsManager,
  Armadillo armadillo,
  HitTestManager hitTestManager,
}) =>
    new StoryTimeRandomizer(
      storyManager: storyManager,
      child: new ChildConstraintsChanger(
        constraintsManager: constraintsManager,
        child: new DefaultAssetBundle(
          bundle: defaultBundle,
          child: new Stack(children: [
            new InheritedHitTestManager(
              hitTestManager: hitTestManager,
              child: armadillo,
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
