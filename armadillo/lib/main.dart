// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/default_bundle.dart';

import 'armadillo.dart';
import 'child_constraints_changer.dart';
import 'constraints_manager.dart';
import 'now_manager.dart';
import 'story_manager.dart';
import 'story_time_randomizer.dart';
import 'suggestion_manager.dart';

/// Set to true to enable the performance overlay.
const bool _kShowPerformanceOverlay = false;

Future main() async {
  SuggestionManager suggestionManager = new SuggestionManager();
  StoryManager storyManager = new StoryManager(
    suggestionManager: suggestionManager,
  );
  NowManager nowManager = new NowManager();
  ConstraintsManager constraintsManager = new ConstraintsManager();

  Widget app = _buildApp(
    suggestionManager: suggestionManager,
    storyManager: storyManager,
    nowManager: nowManager,
    constraintsManager: constraintsManager,
  );

  runApp(_kShowPerformanceOverlay ? _buildPerformanceOverlay(child: app) : app);

  SystemChrome.setEnabledSystemUIOverlays([]);
  storyManager.load(defaultBundle);
  suggestionManager.load(defaultBundle);
  constraintsManager.load(defaultBundle);
}

Widget _buildApp({
  SuggestionManager suggestionManager,
  StoryManager storyManager,
  NowManager nowManager,
  ConstraintsManager constraintsManager,
}) =>
    new CheckedModeBanner(
      child: new StoryTimeRandomizer(
        storyManager: storyManager,
        child: new ChildConstraintsChanger(
          constraintsManager: constraintsManager,
          child: new DefaultAssetBundle(
            bundle: defaultBundle,
            child: new Armadillo(
              storyManager: storyManager,
              suggestionManager: suggestionManager,
              nowManager: nowManager,
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
