// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'story.dart';

class StoryListRenderBlockParentData extends BlockParentData {
  final RenderObject owner;
  Story story;
  double _focusProgress;

  StoryListRenderBlockParentData(this.owner);

  set focusProgress(double focusProgress) {
    _focusProgress = focusProgress;
    owner.markNeedsLayout();
  }

  double get focusProgress => _focusProgress;
}
