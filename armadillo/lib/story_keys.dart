// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'simulation_builder.dart';
import 'story.dart';
import 'story_bar.dart';
import 'story_cluster.dart';

class StoryKeys {
  static GlobalKey<StoryBarState> storyBarKey(Story story) =>
      new GlobalObjectKey<StoryBarState>(story.storyBarKeyObject);
  static GlobalKey<SimulationBuilderState> storyClusterFocusSimulationKey(
          StoryCluster storyCluster) =>
      new GlobalObjectKey(storyCluster.id);
}
