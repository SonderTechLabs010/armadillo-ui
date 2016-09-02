// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/default_bundle.dart';
import 'package:sysui_widgets/delegating_page_route.dart';

import 'armadillo.dart';
import 'child_constraints_changer.dart';
import 'story_manager.dart';
import 'suggestion_manager.dart';

const _kConstraints = const <BoxConstraints>[
  const BoxConstraints.tightFor(width: 440.0, height: 440.0 * 16.0 / 9.0),
  const BoxConstraints.tightFor(width: 440.0 * 16.0 / 9.0, height: 440.0),
  const BoxConstraints(),
  const BoxConstraints.tightFor(width: 360.0, height: 640.0),
  const BoxConstraints.tightFor(width: 640.0, height: 360.0),
  const BoxConstraints.tightFor(width: 480.0, height: 800.0),
  const BoxConstraints.tightFor(width: 800.0, height: 480.0),
  const BoxConstraints.tightFor(width: 800.0, height: 1280.0),
  const BoxConstraints.tightFor(width: 1280.0, height: 800.0),
];

Future main() async {
  SuggestionManager suggestionManager = new SuggestionManager();
  StoryManager storyManager =
      new StoryManager(suggestionManager: suggestionManager);
  runApp(new WidgetsApp(
      onGenerateRoute: (RouteSettings settings) => new DelegatingPageRoute(
          (_) => new ChildConstraintsChanger(
              constraints: _kConstraints,
              child: new DefaultAssetBundle(
                  bundle: defaultBundle,
                  child: new Armadillo(storyManager: storyManager))),
          settings: settings)));
  SystemChrome.setEnabledSystemUIOverlays(0);
  storyManager.load(defaultBundle);
  suggestionManager.load(defaultBundle);
}
