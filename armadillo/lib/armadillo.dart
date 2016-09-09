// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'conductor.dart';
import 'now_manager.dart';
import 'story_manager.dart';
import 'suggestion_manager.dart';

const _kBackgroundOverlayColor = const Color(0xB0000000);
const _kBackgroundImage = 'packages/armadillo/res/Background.jpg';

/// The main app which controls the Fuchsia UI.
class Armadillo extends StatefulWidget {
  final StoryManager storyManager;
  final SuggestionManager suggestionManager;
  final NowManager nowManager;

  Armadillo({this.storyManager, this.suggestionManager, this.nowManager});

  @override
  ArmadilloState createState() => new ArmadilloState();
}

class ArmadilloState extends State<Armadillo> {
  @override
  void initState() {
    super.initState();
    config.storyManager.addListener(onChange);
    config.suggestionManager.addListener(onChange);
    config.nowManager.addListener(onChange);
  }

  @override
  void dispose() {
    config.nowManager.removeListener(onChange);
    config.suggestionManager.removeListener(onChange);
    config.storyManager.removeListener(onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new Container(
        decoration: new BoxDecoration(
          backgroundImage: new BackgroundImage(
            image: new AssetImage(_kBackgroundImage),
            alignment: const FractionalOffset(0.4, 0.5),
            fit: ImageFit.cover,
            colorFilter: new ui.ColorFilter.mode(
              _kBackgroundOverlayColor,
              ui.TransferMode.srcATop,
            ),
          ),
        ),
        child: new InheritedSuggestionManager(
          suggestionManager: config.suggestionManager,
          child: new InheritedStoryManager(
            storyManager: config.storyManager,
            child: new InheritedNowManager(
              nowManager: config.nowManager,
              child: new Conductor(),
            ),
          ),
        ),
      );

  void onChange() {
    setState(() {});
  }
}
