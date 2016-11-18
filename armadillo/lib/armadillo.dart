// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'conductor.dart';
import 'now_manager.dart';
import 'rounded_corner_decoration.dart';
import 'story_manager.dart';
import 'suggestion_manager.dart';

const _kBackgroundOverlayColor = const Color(0xB0000000);
const _kBackgroundImage = 'packages/armadillo/res/Background.jpg';
const double _kDeviceScreenInnerBezelRadius = 12.0;

/// The main app which controls the Fuchsia UI.
class Armadillo extends StatelessWidget {
  final StoryManager storyManager;
  final SuggestionManager suggestionManager;
  final NowManager nowManager;
  final bool useSoftKeyboard;

  Armadillo({
    this.storyManager,
    this.suggestionManager,
    this.nowManager,
    this.useSoftKeyboard: true,
  });

  @override
  Widget build(BuildContext context) => new Container(
        decoration: new BoxDecoration(
          backgroundColor: Colors.black,
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
        foregroundDecoration: new RoundedCornerDecoration(
          radius: _kDeviceScreenInnerBezelRadius,
          color: Colors.black,
        ),
        child: new InheritedSuggestionManager(
          suggestionManager: suggestionManager,
          child: new InheritedStoryManager(
            storyManager: storyManager,
            child: new InheritedNowManager(
              nowManager: nowManager,
              child: new Conductor(useSoftKeyboard: useSoftKeyboard),
            ),
          ),
        ),
      );
}
