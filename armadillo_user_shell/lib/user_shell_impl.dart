// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:apps.modular.services.user/story_provider.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'debug.dart';
import 'focus_controller_impl.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_manager.dart';

class UserShellImpl extends UserShell {
  final UserShellBinding _binding = new UserShellBinding();
  final StoryProviderStoryGenerator storyProviderStoryGenerator;
  final SuggestionProviderSuggestionManager suggestionProviderSuggestionManager;
  final StoryProviderProxy storyProvider = new StoryProviderProxy();
  final SuggestionProviderProxy suggestionProvider =
      new SuggestionProviderProxy();
  final FocusControllerImpl _focusControllerImpl = new FocusControllerImpl();

  UserShellImpl({
    this.storyProviderStoryGenerator,
    this.suggestionProviderSuggestionManager,
  });

  void bind(InterfaceRequest<UserShell> request) {
    _binding.bind(this, request);
  }

  @override
  void initialize(
    InterfaceHandle<StoryProvider> storyProviderHandle,
    InterfaceHandle<SuggestionProvider> suggestionProviderHandle,
    InterfaceRequest<FocusController> focusControllerRequest,
  ) {
    storyProvider.ctrl.bind(storyProviderHandle);
    suggestionProvider.ctrl.bind(suggestionProviderHandle);
    _focusControllerImpl.bind(focusControllerRequest);
    storyProviderStoryGenerator.storyProvider = storyProvider;
    suggestionProviderSuggestionManager.suggestionProvider = suggestionProvider;
    suggestionProviderSuggestionManager.focusController = _focusControllerImpl;
  }
}
