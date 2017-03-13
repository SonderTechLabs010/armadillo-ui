// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'story_cluster.dart';
import 'model.dart';

export 'model.dart' show ScopedModel, Model, ScopedModelDecendant;

/// Tracks a [StoryCluster], notifying listeners when it changes.
/// Using a [StoryClusterPanelsModel] allows the [StoryCluster]'s panels it
/// tracks to be passed down the widget tree using an [ScopedModel].
class StoryClusterPanelsModel extends Model {
  final StoryCluster _storyCluster;

  StoryClusterPanelsModel(this._storyCluster);

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static StoryClusterPanelsModel of(BuildContext context) =>
      new ModelFinder<StoryClusterPanelsModel>().of(context);

  StoryCluster get storyCluster => _storyCluster;
}
