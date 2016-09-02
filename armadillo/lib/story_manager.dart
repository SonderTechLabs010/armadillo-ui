// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'focusable_story.dart';

const String _kJsonUrl = 'packages/armadillo/res/stories.json';

/// A simple story manager that reads stories from json and reorders them with
/// user interaction.
class StoryManager {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  int version = 0;
  List<Story> _stories = const <Story>[];

  StoryManager();

  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      List<Map<String, Object>> storyList = JSON.decode(json);
      _stories = storyList.map((Map<String, Object> storyMap) {
        return new Story(
            id: new ValueKey(storyMap['id']),
            builder: (_) => new Image.asset(storyMap['content'],
                alignment: FractionalOffset.centerLeft, fit: ImageFit.cover),
            title: storyMap['title'],
            icons: (storyMap['icons'] as List<String>).map((String icon) {
              return (BuildContext context) => new Image.asset(icon,
                  fit: ImageFit.cover, color: Colors.white);
            }).toList(),
            avatar: (_) =>
                new Image.asset(storyMap['avatar'], fit: ImageFit.cover),
            lastInteraction: new DateTime.now().subtract(
                new Duration(seconds: int.parse(storyMap['lastInteraction']))),
            cumulativeInteractionDuration: new Duration(
                minutes: int.parse(storyMap['culmulativeInteraction'])),
            themeColor: new Color(int.parse(storyMap['color'])));
      }).toList();
      _notifyListeners();
    });
  }

  List<Story> get stories => _stories;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Updates the [Story.lastInteraction] of [story] to be [DateTime.now].
  /// This method is to be called whenever a [Story]'s [Story.builder] [Widget]
  /// comes into focus.
  void interactionStarted(Story story) {
    _stories.removeWhere((Story s) => s.id == story.id);
    _stories.add(story.copyWith(lastInteraction: new DateTime.now()));
    _notifyListeners();
  }

  void _notifyListeners() {
    version++;
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}

class InheritedStoryManager extends InheritedWidget {
  final StoryManager storyManager;
  final int storyManagerVersion;
  InheritedStoryManager({Key key, Widget child, StoryManager storyManager})
      : this.storyManager = storyManager,
        this.storyManagerVersion = storyManager.version,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedStoryManager oldWidget) =>
      (oldWidget.storyManagerVersion != storyManagerVersion);

  static StoryManager of(BuildContext context) {
    InheritedStoryManager inheritedStoryManager =
        context.inheritFromWidgetOfExactType(InheritedStoryManager);
    return inheritedStoryManager?.storyManager;
  }
}
