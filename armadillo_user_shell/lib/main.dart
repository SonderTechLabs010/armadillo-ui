// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.lib.app.dart/app.dart';
import 'package:apps.modular.services.user/story_provider.fidl.dart';
import 'package:apps.modular.services.user/user_runner.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:armadillo/armadillo.dart';
import 'package:armadillo/child_constraints_changer.dart';
import 'package:armadillo/constraints_manager.dart';
import 'package:armadillo/now_manager.dart';
import 'package:armadillo/story_manager.dart';
import 'package:armadillo/story_time_randomizer.dart';
import 'package:armadillo/suggestion_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'debug.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_manager.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

class UserShellImpl extends UserShell {
  final UserShellBinding _binding = new UserShellBinding();
  final StoryProviderStoryGenerator storyProviderStoryGenerator;
  final SuggestionProviderSuggestionManager suggestionProviderSuggestionManager;
  final StoryProviderProxy storyProvider = new StoryProviderProxy();
  final SuggestionProviderProxy suggestionProvider =
      new SuggestionProviderProxy();

  UserShellImpl({
    this.storyProviderStoryGenerator,
    this.suggestionProviderSuggestionManager,
  });

  void bind(InterfaceRequest<UserShell> request) {
    _binding.bind(this, request);
  }

  @override
  void initialize(
    InterfaceHandle<StoryProvider> storyProviderInterface,
    InterfaceHandle<SuggestionProvider> suggestionProviderInterface,
    _,
  ) {
    storyProvider.ctrl.bind(storyProviderInterface);
    suggestionProvider.ctrl.bind(suggestionProviderInterface);
    storyProviderStoryGenerator.storyProvider = storyProvider;
    suggestionProviderSuggestionManager.suggestionProvider = suggestionProvider;
  }
}

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
}) =>
    new DefaultAssetBundle(
            bundle: defaultBundle,
            child: new Armadillo(
              storyManager: storyManager,
              suggestionManager: suggestionManager,
              nowManager: nowManager,
              useSoftKeyboard: false,
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
