// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:apps.modular.services.user/user_context.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'focus_request_watcher_impl.dart';
import 'initial_focus_setter.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_model.dart';
import 'user_logoutter.dart';

/// Implements a UserShell for receiving the services a [UserShell] needs to
/// operate.  When [initialize] is called, the services it receives are routed
/// by this class to the various classes which need them.
class UserShellImpl extends UserShell {
  final UserContextProxy _userContext = new UserContextProxy();
  final FocusProviderProxy _focusProvider = new FocusProviderProxy();
  final FocusControllerProxy _focusController = new FocusControllerProxy();
  final VisibleStoriesControllerProxy _visibleStoriesController =
      new VisibleStoriesControllerProxy();
  final StoryProviderProxy _storyProvider = new StoryProviderProxy();
  final SuggestionProviderProxy _suggestionProvider =
      new SuggestionProviderProxy();

  /// Receives the [StoryProvider].
  final StoryProviderStoryGenerator storyProviderStoryGenerator;

  /// Receives the [SuggestionProvider], [FocusController], and
  /// [VisibleStoriesController].
  final SuggestionProviderSuggestionModel suggestionProviderSuggestionModel;

  /// Watches the [FocusController].
  final FocusRequestWatcherImpl focusRequestWatcher;

  /// Receives the [FocusProvider].
  final InitialFocusSetter initialFocusSetter;

  /// Receives the [UserContext].
  final UserLogoutter userLogoutter;

  /// Constructor.
  UserShellImpl({
    this.storyProviderStoryGenerator,
    this.suggestionProviderSuggestionModel,
    this.focusRequestWatcher,
    this.initialFocusSetter,
    this.userLogoutter,
  });

  @override
  void initialize(
    InterfaceHandle<UserContext> userContextHandle,
    InterfaceHandle<UserShellContext> userShellContextHandle,
  ) {
    _userContext.ctrl.bind(userContextHandle);
    userLogoutter.userContext = _userContext;

    UserShellContextProxy userShellContext = new UserShellContextProxy();
    userShellContext.ctrl.bind(userShellContextHandle);
    userShellContext.getStoryProvider(_storyProvider.ctrl.request());
    userShellContext.getSuggestionProvider(_suggestionProvider.ctrl.request());
    userShellContext.getVisibleStoriesController(
      _visibleStoriesController.ctrl.request(),
    );
    userShellContext.getFocusController(_focusController.ctrl.request());
    userShellContext.getFocusProvider(_focusProvider.ctrl.request());
    userShellContext.ctrl.close();

    _focusController.watchRequest(focusRequestWatcher.getHandle());
    initialFocusSetter.focusProvider = _focusProvider;
    storyProviderStoryGenerator.storyProvider = _storyProvider;
    suggestionProviderSuggestionModel.suggestionProvider = _suggestionProvider;
    suggestionProviderSuggestionModel.focusController = _focusController;
    suggestionProviderSuggestionModel.visibleStoriesController =
        _visibleStoriesController;
  }

  @override
  void terminate(void done()) => done();
}
