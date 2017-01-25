// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'story.dart';

/// Specifies the type of action to perform when the suggestion is selected.
/// [launchStory] will trigger the [Story] specified by
/// [Suggestion.selectionStoryId] to come into focus.
/// [modifyStory] will modify the [Story] specified by
/// [Suggestion.selectionStoryId] in some way.
/// [doNothing] does nothing and is only provided for testing purposes.
/// [closeSuggestions] closes the suggestion overlay.
enum SelectionType { launchStory, modifyStory, doNothing, closeSuggestions }

/// Determines what the suggestion looks like with respect to
/// [Suggestion.image].
enum ImageType { person, other }

class SuggestionId extends ValueKey<dynamic> {
  SuggestionId(dynamic value) : super(value);
}

class Suggestion {
  final SuggestionId id;
  final String title;
  final Color themeColor;
  final SelectionType selectionType;
  final StoryId selectionStoryId;
  final List<WidgetBuilder> icons;
  final WidgetBuilder image;
  final ImageType imageType;
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
