// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/story_info.fidl.dart';
import 'package:apps.modular.services.user/story_provider.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'debug.dart';

typedef void OnStoryChanged(StoryInfo storyInfo);
typedef void OnStoryDeleted(String storyId);

class StoryProviderWatcherImpl extends StoryProviderWatcher {
  final StoryProviderWatcherBinding _binding =
      new StoryProviderWatcherBinding();
  final OnStoryChanged onStoryChanged;
  final OnStoryDeleted onStoryDeleted;

  StoryProviderWatcherImpl({this.onStoryChanged, this.onStoryDeleted});

  InterfaceHandle<StoryProviderWatcher> getHandle() => _binding.wrap(this);

  @override
  void onChange(StoryInfo storyInfo) {
    armadilloPrint('story changed! $storyInfo');
    onStoryChanged?.call(storyInfo);
  }

  @override
  void onDelete(String storyId) {
    armadilloPrint('story deleted! $storyId');
    onStoryDeleted?.call(storyId);
  }
}
