// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/story_info.fidl.dart';
import 'package:apps.modular.services.user/story_provider.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:armadillo/story.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_id.dart';
import 'package:armadillo/story_generator.dart';
import 'package:flutter/material.dart';

import 'debug.dart';
import 'hit_test_manager.dart';
import 'story_provider_watcher_impl.dart';

const String _kUserImage = 'packages/armadillo/res/User.png';

/// Creates a list of stories for the StoryList using
/// modular's [StoryProvider].
class StoryProviderStoryGenerator extends StoryGenerator {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();

  /// Set from an external source - typically the UserShell.
  StoryProviderProxy _storyProvider;

  List<StoryCluster> _storyClusters = <StoryCluster>[];

  final Map<String, StoryControllerProxy> _storyControllerMap =
      <String, StoryControllerProxy>{};
  final Map<String, StoryCluster> _storyClusterMap = <String, StoryCluster>{};
  StoryProviderWatcherImpl _storyProviderWatcher;

  set storyProvider(StoryProviderProxy storyProvider) {
    _storyProvider = storyProvider;
    _storyProviderWatcher = new StoryProviderWatcherImpl(
      onStoryChanged: _onStoryChanged,
      onStoryDeleted: (String storyId) => _removeStory(storyId),
    );
    _storyProvider.watch(_storyProviderWatcher.getHandle());
    update();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  @override
  List<StoryCluster> get storyClusters => _storyClusters;

  void removeStoryCluster(StoryClusterId storyClusterId) {
    armadilloPrint('removing story cluster: $storyClusterId');
    StoryCluster storyCluster = _storyClusters
        .where((StoryCluster storyCluster) => storyCluster.id == storyClusterId)
        .single;
    storyCluster.stories.forEach((Story story) {
      armadilloPrint('Deleting story ${story.id.value}...');
      _storyProvider.deleteStory(story.id.value, () {
        armadilloPrint('Story ${story.id.value} deleted!');
      });
      _removeStory(story.id.value, notify: false);
    });
    _storyClusters.remove(storyCluster);

    _notifyListeners();
  }

  /// Loads the list of previous stories from the [StoryProvider].
  /// If no stories exist, we create some.
  /// If stories do exist, we resume them.
  /// If set, [callback] will be called when the stories have been updated.
  /// TODO(apwilson): listen for changes in the previous story list.
  void update([VoidCallback callback]) {
    _storyProvider.previousStories((List<String> storyIds) {
      armadilloPrint('Got previousStories! $storyIds');
      if (storyIds.isEmpty) {
        // We have no previous stories, so create some!
        // TODO(apwilson): Remove when suggestions can create stories and we can
        // listener for new stories.
        List<String> storyUrls = [
          'file:///system/apps/color',
          'file:///system/apps/noodles_view',
          'file:///system/apps/spinning_square_view',
          'file:///system/apps/hello_material',
        ];
        storyUrls.forEach((String storyUrl) {
          final StoryControllerProxy controller = new StoryControllerProxy();
          armadilloPrint('creating story!');
          _storyProvider.createStory(
            storyUrl,
            controller.ctrl.request(),
          );
          controller.ctrl.close();
        });
      } else {
        /// We have previous stories so lets resume them so they can be
        /// displayed in a child view.
        int added = 0;
        storyIds.forEach((String storyId) {
          _addStoryCluster(storyId, () {
            added++;
            if (added == storyIds.length) {
              callback?.call();
            }
          });
        });
      }
    });
  }

  void _onStoryChanged(StoryInfo storyInfo) {
    if (_storyControllerMap[storyInfo.id] == null) {
      _addStoryCluster(storyInfo.id);
    }
  }

  void _removeStory(String storyId, {bool notify: true}) {
    if (_storyControllerMap[storyId] != null) {
      _storyControllerMap[storyId].ctrl.close();
      _storyControllerMap.remove(storyId);
      _storyClusters.remove(_storyClusterMap[storyId]);
      _storyClusterMap.remove(storyId);
      if (notify) {
        _notifyListeners();
      }
    }
  }

  _addStoryCluster(String storyId, [VoidCallback callback]) {
    final StoryControllerProxy controller = new StoryControllerProxy();
    _storyControllerMap[storyId] = controller;
    _storyProvider.resumeStory(
      storyId,
      controller.ctrl.request(),
    );

    // Get its info!
    controller.getInfo((StoryInfo storyInfo) {
      armadilloPrint('story info: $storyInfo');

      // Start it!
      ViewOwnerProxy viewOwner = new ViewOwnerProxy();
      controller.start(viewOwner.ctrl.request());

      // Create a flutter view from its view!
      ChildViewConnection childViewConnection = new ChildViewConnection(
        viewOwner.ctrl.unbind(),
      );

      StoryCluster storyCluster = new StoryCluster(stories: [
        _createStory(
          storyInfo: storyInfo,
          childViewConnection: childViewConnection,
        ),
      ]);

      _storyClusterMap[storyId] = storyCluster;
      _storyClusters.add(storyCluster);
      _notifyListeners();
      callback?.call();
    });
  }

  void _notifyListeners() {
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }

  Story _createStory(
          {StoryInfo storyInfo, ChildViewConnection childViewConnection}) =>
      new Story(
        id: new StoryId(storyInfo.id),
        builder: (BuildContext context) {
          bool hitTestable = InheritedHitTestManager
              .of(context, rebuildOnChange: true)
              .isStoryHitTestable(storyInfo.id);
          armadilloPrint('Story ${storyInfo.id} is hitTestable? $hitTestable');

          return new ChildView(
            hitTestable: hitTestable,
            connection: childViewConnection,
          );
        },
        // TODO(apwilson): Improve title.
        title:
            '[${Uri.parse(storyInfo.url).pathSegments[Uri.parse(storyInfo.url).pathSegments.length-1]} // ${storyInfo.id}]',
        icons: [],
        avatar: (_, double opacity) => new Opacity(
              opacity: opacity,
              child: new Image.asset(_kUserImage, fit: ImageFit.cover),
            ),
        lastInteraction: new DateTime.now(),
        cumulativeInteractionDuration: new Duration(
          minutes: 0,
        ),
        themeColor: _kStoryColors[storyInfo.url] == null
            ? Colors.grey[500]
            : _kStoryColors[storyInfo.url],
        inactive: false,
      );
}

final Map<String, Color> _kStoryColors = <String, Color>{
  'file:///system/apps/paint_view': new Color(0xffad1457),
  'file:///system/apps/hello_material': new Color(0xff4caf50),
  'file:///system/apps/video_player': new Color(0xff9575cd),
  'file:///system/apps/youtube_story': new Color(0xffe52d27),
  'file:///system/apps/email_story': new Color(0xff4285f4),
  'file:///system/apps/music_story': new Color(0xffff8c00),
  'file:///system/apps/color': new Color(0xff5affd6),
  'file:///system/apps/spinning_square_view': new Color(0xff512da8),
  'file:///system/apps/moterm': new Color(0xff212121),
  'file:///system/apps/noodles_view': new Color(0xff212121),
};
