// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'model.dart';
import 'story_cluster.dart';
import 'suggestion.dart';

export 'model.dart' show ScopedModel, Model;

/// The base class for suggestion models.
abstract class SuggestionModel extends Model {
  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static SuggestionModel of(BuildContext context,
          {bool rebuildOnChange: false}) =>
      new ModelFinder<SuggestionModel>()
          .of(context, rebuildOnChange: rebuildOnChange);

  List<Suggestion> get suggestions;

  set askText(String text);

  set asking(bool asking);

  /// Updates the [suggestions] based on the currently focused storyCluster].  If no
  /// story is in focus, [storyCluster] should be null.
  void storyClusterFocusChanged(StoryCluster storyCluster);

  /// Called when a suggestion is selected by the user.
  void onSuggestionSelected(Suggestion suggestion);
}
