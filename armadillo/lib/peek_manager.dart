// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'peeking_overlay.dart';
import 'story_cluster_drag_state_model.dart';

/// Manages if the [PeekingOverlay] with the [peekingOverlayKey] should
/// be peeking or not.
class PeekManager {
  /// The peeking overlay managed by this manager.
  final GlobalKey<PeekingOverlayState> peekingOverlayKey;

  /// Provides whether or not a drag is happening.
  final StoryClusterDragStateModel storyClusterDragStateModel;

  bool _nowMinimized = false;
  bool _isDragging = false;

  /// Constructor.
  PeekManager({this.peekingOverlayKey, this.storyClusterDragStateModel}) {
    storyClusterDragStateModel.addListener(_onStoryClusterDragStateChanged);
  }

  /// Sets whether now is minimized or not.
  set nowMinimized(bool value) {
    if (_nowMinimized != value) {
      _nowMinimized = value;
      _updatePeek();
    }
  }

  void _onStoryClusterDragStateChanged() {
    if (_isDragging != storyClusterDragStateModel.isDragging) {
      _isDragging = storyClusterDragStateModel.isDragging;
      _updatePeek();
    }
  }

  void _updatePeek() {
    peekingOverlayKey.currentState.peek = (!_nowMinimized && !_isDragging);
  }
}
