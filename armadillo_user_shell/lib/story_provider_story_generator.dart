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

/// Creates a list of stories for the StoryList using
/// modular's [StoryProvider].
class StoryProviderStoryGenerator extends StoryGenerator {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();

  /// Set from an external source - typically the UserShell.
  StoryProviderProxy _storyProvider;

  List<StoryCluster> _storyClusters = <StoryCluster>[];

  final List<StoryControllerProxy> _storyControllers = <StoryControllerProxy>[];

  set storyProvider(StoryProviderProxy storyProvider) {
    _storyProvider = storyProvider;
    _load();
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
    });
    _storyClusters.remove(storyCluster);
    _notifyListeners();
  }

  /// Loads the list of previous stories from the [StoryProvider].
  /// If no stories exist, we create some.
  /// If stores do exist, we resume them.
  /// TODO(apwilson): listen for changes int he previous story list.
  void _load() {
    _storyProvider.previousStories((List<String> storyIds) {
      armadilloPrint('Got previousStories! $storyIds');

      if (storyIds.isEmpty) {
        // We have no previous stories, so create some!
        // TODO(apwilson): Remove when suggestions can create stories and we can
        // listener for new stories.
        List<String> storyUrls = [
          'file:///system/apps/email_story',
          'file:///system/apps/noodles_view',
          'file:///system/apps/spinning_square_view',
          'file:///system/apps/shapes_view',
          'file:///system/apps/paint_view',
          'file:///system/apps/moterm',
          'file:///system/apps/color',
        ];
        storyUrls.forEach((String storyUrl) {
          final StoryControllerProxy controller = new StoryControllerProxy();
          _storyControllers.add(controller);
          armadilloPrint('creating story!');
          _storyProvider.createStory(
            storyUrl,
            controller.ctrl.request(),
          );

          // Get its info!
          controller.getInfo((StoryInfo storyInfo) {
            armadilloPrint('story info: $storyInfo');
            armadilloPrint('   url: ${storyInfo.url}');
            armadilloPrint('   id: ${storyInfo.id}');
            armadilloPrint('   isRunning: ${storyInfo.isRunning}');

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
                  childViewConnection: childViewConnection),
            ]);
            _storyClusters.add(storyCluster);
            _notifyListeners();
          });
        });
      } else {
        /// We have previous stories so lets resume them so they can be
        /// displayed in a child view.

        storyIds.forEach((String storyId) {
          final StoryControllerProxy controller = new StoryControllerProxy();
          _storyControllers.add(controller);

          /// Resume it!
          _storyProvider.resumeStory(
            storyId,
            controller.ctrl.request(),
          );

          // Get its info!
          controller.getInfo((StoryInfo storyInfo) {
            armadilloPrint('story info: $storyInfo');
            armadilloPrint('   url: ${storyInfo.url}');
            armadilloPrint('   id: ${storyInfo.id}');
            armadilloPrint('   isRunning: ${storyInfo.isRunning}');

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
                  childViewConnection: childViewConnection),
            ]);
            _storyClusters.add(storyCluster);
            _notifyListeners();
          });
        });
      }
    });
  }

  void _notifyListeners() {
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }

  Story _createStory(
          {StoryInfo storyInfo, ChildViewConnection childViewConnection}) =>
      new Story(
        id: new StoryId(storyInfo.id),
        builder: (_) => new ChildView(connection: childViewConnection),
        // TODO(apwilson): Improve title.
        title:
            '[${Uri.parse(storyInfo.url).pathSegments[Uri.parse(storyInfo.url).pathSegments.length-1]} // ${storyInfo.id}]',
        icons: [],
        avatar: (_, double opacity) => new Opacity(
              opacity: opacity,
              child: new Container(width: 10.0, height: 10.0),
            ),
        lastInteraction: new DateTime.now(),
        cumulativeInteractionDuration: new Duration(
          minutes: 0,
        ),
        themeColor: Colors.grey[500],
        inactive: false,
      );
}
