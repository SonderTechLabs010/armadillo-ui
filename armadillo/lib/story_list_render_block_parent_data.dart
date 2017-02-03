// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'story_list_layout.dart';

class StoryListRenderBlockParentData extends BlockParentData {
  final RenderObject owner;
  StoryLayout storyLayout;
  double _focusProgress;
  double _inlinePreviewScaleProgress;

  StoryListRenderBlockParentData(this.owner);

  set focusProgress(double focusProgress) {
    if (_focusProgress != focusProgress) {
      _focusProgress = focusProgress;
      owner.markNeedsLayout();
    }
  }

  double get focusProgress => _focusProgress;

  set inlinePreviewScaleProgress(double inlinePreviewScaleProgress) {
    if (_inlinePreviewScaleProgress != inlinePreviewScaleProgress) {
      _inlinePreviewScaleProgress = inlinePreviewScaleProgress;
      owner.markNeedsLayout();
    }
  }

  double get inlinePreviewScaleProgress => _inlinePreviewScaleProgress;
}
