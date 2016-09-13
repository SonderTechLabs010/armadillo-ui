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
import 'constraints_manager.dart';
import 'now_manager.dart';
import 'story_manager.dart';
import 'suggestion_manager.dart';

Future main() async {
  SuggestionManager suggestionManager = new SuggestionManager();
  StoryManager storyManager = new StoryManager(
    suggestionManager: suggestionManager,
  );
  NowManager nowManager = new NowManager();
  ConstraintsManager constraintsManager = new ConstraintsManager();

  runApp(
    new WidgetsApp(
      onGenerateRoute: (RouteSettings settings) => new DelegatingPageRoute(
            (_) => new ChildConstraintsChanger(
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
            settings: settings,
          ),
    ),
  );

  SystemChrome.setEnabledSystemUIOverlays(0);
  storyManager.load(defaultBundle);
  suggestionManager.load(defaultBundle);
  constraintsManager.load(defaultBundle);
}
