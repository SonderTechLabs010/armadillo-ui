// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'conductor.dart';
import 'debug_model.dart';
import 'now_model.dart';
import 'panel_resizing_model.dart';
import 'rounded_corner_decoration.dart';
import 'default_scroll_configuration.dart';
import 'story_cluster_drag_state_model.dart';
import 'story_drag_transition_model.dart';
import 'story_model.dart';
import 'story_rearrangement_scrim_model.dart';
import 'suggestion_model.dart';

const Color _kBackgroundOverlayColor = const Color(0xB0000000);
const String _kBackgroundImage = 'packages/armadillo/res/Background.jpg';
const double _kDeviceScreenInnerBezelRadius = 8.0;

/// [Armadillo] is the main Widget.  Its purpose is to set up [Model]s the rest
/// of the Widgets depend upon. It uses the [Conductor] to display the actual UI
/// Widgets.
class Armadillo extends StatelessWidget {
  final StoryModel storyModel;
  final SuggestionModel suggestionModel;
  final NowModel nowModel;
  final StoryClusterDragStateModel storyClusterDragStateModel;
  final StoryRearrangementScrimModel storyRearrangementScrimModel;
  final StoryDragTransitionModel storyDragTransitionModel;
  final DebugModel debugModel;
  final PanelResizingModel panelResizingModel;
  final Conductor conductor;

  Armadillo({
    @required this.storyModel,
    @required this.suggestionModel,
    @required this.nowModel,
    @required this.storyClusterDragStateModel,
    @required this.storyRearrangementScrimModel,
    @required this.storyDragTransitionModel,
    @required this.debugModel,
    @required this.panelResizingModel,
    @required this.conductor,
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
                child: new ScopedModel<StoryRearrangementScrimModel>(
                  model: storyRearrangementScrimModel,
                  child: new ScopedModel<StoryDragTransitionModel>(
                    model: storyDragTransitionModel,
                    child: new ScopedModel<DebugModel>(
                        model: debugModel,
                        child: new ScopedModel<PanelResizingModel>(
                          model: panelResizingModel,
                          child: new DefaultScrollConfiguration(
                            child: conductor,
                          ),
                        )),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
