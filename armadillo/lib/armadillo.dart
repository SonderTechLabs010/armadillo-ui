// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'conductor.dart';
import 'now_model.dart';
import 'rounded_corner_decoration.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_model.dart';
import 'suggestion_model.dart';

const _kBackgroundOverlayColor = const Color(0xB0000000);
const _kBackgroundImage = 'packages/armadillo/res/Background.jpg';
const double _kDeviceScreenInnerBezelRadius = 8.0;

/// The main app which controls the Fuchsia UI.
class Armadillo extends StatelessWidget {
  final StoryModel storyModel;
  final SuggestionModel suggestionModel;
  final NowModel nowModel;
  final StoryClusterDragStateModel storyClusterDragStateModel;
  final Conductor conductor;

  Armadillo({
    this.storyModel,
    this.suggestionModel,
    this.nowModel,
    this.storyClusterDragStateModel,
    this.conductor,
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
              ui.BlendMode.srcATop,
            ),
          ),
        ),
        foregroundDecoration: new RoundedCornerDecoration(
          radius: _kDeviceScreenInnerBezelRadius,
          color: Colors.black,
        ),
        child: new ScopedModel<SuggestionModel>(
          model: suggestionModel,
          child: new ScopedModel<StoryModel>(
            model: storyModel,
            child: new ScopedModel<NowModel>(
              model: nowModel,
              child: new ScopedModel<StoryClusterDragStateModel>(
                model: storyClusterDragStateModel,
                child: conductor,
              ),
            ),
          ),
        ),
      );
}
