// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart';
import 'package:apps.modular.services.story/story_provider.fidl.dart';
import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:apps.modular.services.user/user_context.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'focus_controller_impl.dart';
import 'story_provider_story_generator.dart';
import 'suggestion_provider_suggestion_manager.dart';

class UserShellImpl extends UserShell {
  final UserShellBinding _binding = new UserShellBinding();
  final StoryProviderStoryGenerator storyProviderStoryGenerator;
  final SuggestionProviderSuggestionModel suggestionProviderSuggestionModel;
  final FocusControllerImpl focusController;
  final StoryProviderProxy storyProvider = new StoryProviderProxy();
  final SuggestionProviderProxy suggestionProvider =
      new SuggestionProviderProxy();
  final UserContextProxy userContext = new UserContextProxy();

  UserShellImpl({
    this.storyProviderStoryGenerator,
    this.suggestionProviderSuggestionModel,
    this.focusController,
  });

  void bind(InterfaceRequest<UserShell> request) {
    _binding.bind(this, request);
  }

  @override
  void initialize(
    InterfaceHandle<UserContext> userContextHandle,
    InterfaceHandle<StoryProvider> storyProviderHandle,
    InterfaceHandle<SuggestionProvider> suggestionProviderHandle,
    InterfaceRequest<FocusController> focusControllerRequest,
  ) {
    userContext.ctrl.bind(userContextHandle);
    storyProvider.ctrl.bind(storyProviderHandle);
    suggestionProvider.ctrl.bind(suggestionProviderHandle);
    focusController.bind(focusControllerRequest);
    storyProviderStoryGenerator.storyProvider = storyProvider;
    suggestionProviderSuggestionModel.suggestionProvider = suggestionProvider;
    suggestionProviderSuggestionModel.focusController = focusController;
  }

  @override
  void terminate(void done()) {
    done();
  }
}
