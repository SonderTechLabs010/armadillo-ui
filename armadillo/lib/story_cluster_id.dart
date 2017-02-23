// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

class StoryClusterId {}

class DraggedStoryClusterData {
  final StoryClusterId id;
  final VoidCallback onFirstHover;
  final VoidCallback onNoTarget;
  DraggedStoryClusterData({this.id, this.onFirstHover, this.onNoTarget});
}
