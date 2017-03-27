// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'story.dart';

/// Specifies the type of action to perform when the suggestion is selected.
enum SelectionType {
  /// [launchStory] will trigger the [Story] specified by
  /// [Suggestion.selectionStoryId] to come into focus.
  launchStory,

  /// [modifyStory] will modify the [Story] specified by
  /// [Suggestion.selectionStoryId] in some way.
  modifyStory,

  /// [doNothing] does nothing and is only provided for testing purposes.
  doNothing,

  /// [closeSuggestions] closes the suggestion overlay.
  closeSuggestions
}

/// Determines what the suggestion looks like with respect to
/// [Suggestion.image].
enum ImageType {
  /// A [circular] image is expected to be clipped as a circle.
  circular,

  /// A [rectangular] image is not clipped.
  rectangular
}

/// The unique id of a [Suggestion].
class SuggestionId extends ValueKey<dynamic> {
  /// Constructor.
  SuggestionId(dynamic value) : super(value);
}

/// The model for displaying a suggestion in the suggestion overlay.
class Suggestion {
  /// The unique id of this suggestion.
  final SuggestionId id;

  /// The suggestion's title.
  final String title;

  /// The color to use for the suggestion's background.
  final Color themeColor;

  /// The action to take when the suggestion is selected.
  final SelectionType selectionType;

  /// The story id related to this suggestion.
  final StoryId selectionStoryId;

  /// The icons representing the source for this suggestion.
  final List<WidgetBuilder> icons;

  /// The main image of the suggestion.
  final WidgetBuilder image;

  /// The type of [image].
  final ImageType imageType;

  /// Constructor.
  Suggestion({
    this.id,
    this.title,
    this.themeColor,
    this.selectionType,
    this.selectionStoryId,
    this.icons: const <WidgetBuilder>[],
    this.image,
    this.imageType,
  });

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(dynamic other) => (other is Suggestion && other.id == id);
}
