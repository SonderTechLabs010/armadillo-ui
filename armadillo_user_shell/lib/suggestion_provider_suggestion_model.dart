// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.maxwell.services.suggestion/suggestion_display.fidl.dart'
    as maxwell;
import 'package:apps.maxwell.services.suggestion/suggestion_provider.fidl.dart'
    as maxwell;
import 'package:apps.maxwell.services.suggestion/user_input.fidl.dart'
    as maxwell;
import 'package:armadillo/story.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_cluster_id.dart';
import 'package:armadillo/story_generator.dart';
import 'package:armadillo/story_model.dart';
import 'package:armadillo/suggestion.dart';
import 'package:armadillo/suggestion_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'focus_controller_impl.dart';
import 'hit_test_model.dart';

final Map<maxwell.SuggestionImageType, ImageType> _kImageTypeMap =
    <maxwell.SuggestionImageType, ImageType>{
  maxwell.SuggestionImageType.person: ImageType.person,
  maxwell.SuggestionImageType.other: ImageType.other
};

/// Listens to a maxwell suggestion list.  As suggestions change it
/// notifies its [suggestionListener].
class MaxwellSuggestionListenerImpl extends maxwell.SuggestionListener {
  final String prefix;
  final VoidCallback suggestionListener;
  final maxwell.SuggestionListenerBinding _binding =
      new maxwell.SuggestionListenerBinding();
  final Map<String, Suggestion> _suggestions = <String, Suggestion>{};

  MaxwellSuggestionListenerImpl({this.prefix, this.suggestionListener});

  InterfaceHandle<maxwell.SuggestionListener> getHandle() =>
      _binding.wrap(this);

  List<Suggestion> get suggestions => _suggestions.values.toList();

  @override
  void onAdd(List<maxwell.Suggestion> suggestions) {
    suggestions.forEach((maxwell.Suggestion suggestion) {
      _suggestions[suggestion.uuid] = new Suggestion(
        id: new SuggestionId(suggestion.uuid),
        title: suggestion.display.headline,
        themeColor: new Color(suggestion.display.color),
        selectionType: SelectionType.closeSuggestions,
        icons: const <WidgetBuilder>[],
        image: suggestion.display.imageUrl?.isNotEmpty ?? false
            ? (_) => new Image.network(
                  suggestion.display.imageUrl,
                  fit: ImageFit.cover,
                )
            : null,
        imageType: suggestion.display.imageUrl?.isNotEmpty ?? false
            ? _kImageTypeMap[suggestion.display.imageType]
            : ImageType.person,
      );
    });
    suggestionListener?.call();
  }

  @override
  void onRemove(String uuid) {
    _suggestions.remove(uuid);
    suggestionListener?.call();
  }

  @override
  void onRemoveAll() {
    _suggestions.clear();
    suggestionListener?.call();
  }
}

/// Creates a list of suggestions for the SuggestionList using the
/// [maxwell.SuggestionProvider].
class SuggestionProviderSuggestionModel extends SuggestionModel {
  // Controls how many suggestions we receive from maxwell's Ask suggestion
  // stream as well as indicates what the user is asking.
  final maxwell.AskControllerProxy _askControllerProxy =
      new maxwell.AskControllerProxy();

  // Listens for changes to maxwell's ask suggestion list.
  MaxwellSuggestionListenerImpl _askListener;

  // Controls how many suggestions we receive from maxwell's Next suggestion
  // stream.
  final maxwell.NextControllerProxy _nextControllerProxy =
      new maxwell.NextControllerProxy();

  // Listens for changes to maxwell's next suggestion list.
  MaxwellSuggestionListenerImpl _nextListener;

  List<Suggestion> _currentSuggestions = const <Suggestion>[];

  /// When the user is asking via text or voice we want to show the maxwell ask
  /// suggestions rather than the normal maxwell suggestion list.
  String _askText;
  bool _asking = false;

  /// Set from an external source - typically the UserShell.
  maxwell.SuggestionProviderProxy _suggestionProviderProxy;

  /// Set from an external source - typically the UserShell.
  FocusControllerImpl _focusController;

  // Set from an external source - typically the UserShell.
  StoryModel _storyModel;

  StoryClusterId _lastFocusedStoryClusterId;

  final StoryGenerator storyGenerator;
  final HitTestModel hitTestModel;
  final Set<VoidCallback> _focusLossListeners = new Set<VoidCallback>();

  SuggestionProviderSuggestionModel({
    this.storyGenerator,
    this.hitTestModel,
  });

  /// Setting [suggestionProvider] triggers the loading on suggestions.
  /// This is typically set by the UserShell.
  set suggestionProvider(
      maxwell.SuggestionProviderProxy suggestionProviderProxy) {
    _suggestionProviderProxy = suggestionProviderProxy;
    _askListener = new MaxwellSuggestionListenerImpl(
      prefix: 'ask',
      suggestionListener: _onAskSuggestionsChanged,
    );
    _nextListener = new MaxwellSuggestionListenerImpl(
      prefix: 'next',
      suggestionListener: _onNextSuggestionsChanged,
    );
    _load();
  }

  set focusController(FocusControllerImpl focusController) {
    _focusController = focusController;
  }

  set storyModel(StoryModel storyModel) {
    _storyModel = storyModel;
    storyModel.addListener(_onStoryClusterListChanged);
  }

  void addOnFocusLossListener(VoidCallback listener) {
    _focusLossListeners.add(listener);
  }

  void _load() {
    _suggestionProviderProxy.initiateAsk(
      _askListener.getHandle(),
      _askControllerProxy.ctrl.request(),
    );
    _askControllerProxy.setResultCount(20);

    _suggestionProviderProxy.subscribeToNext(
      _nextListener.getHandle(),
      _nextControllerProxy.ctrl.request(),
    );
    _nextControllerProxy.setResultCount(20);
  }

  @override
  List<Suggestion> get suggestions => _currentSuggestions;

  @override
  void onSuggestionSelected(Suggestion suggestion) {
    _suggestionProviderProxy.notifyInteraction(
      suggestion.id.value,
      new maxwell.Interaction()..type = maxwell.InteractionType.selected,
    );
  }

  @override
  set askText(String text) {
    String newAskText = text?.toLowerCase();
    if (_askText != newAskText) {
      _askText = newAskText;
      _askControllerProxy.setUserInput(
        new maxwell.UserInput()..text = newAskText ?? '',
      );
    }
  }

  @override
  set asking(bool asking) {
    if (_asking != asking) {
      _asking = asking;
      if (_asking) {
        _currentSuggestions = _askListener.suggestions;
      } else {
        _currentSuggestions = _nextListener.suggestions;
      }
      notifyListeners();
    }
  }

  @override
  void storyClusterFocusChanged(StoryCluster storyCluster) {
    _lastFocusedStoryCluster?.removeStoryListListener(_onStoryListChanged);
    storyCluster?.addStoryListListener(_onStoryListChanged);
    _lastFocusedStoryClusterId = storyCluster?.id;
    _onStoryListChanged();
  }

  void _onStoryClusterListChanged() {
    if (_lastFocusedStoryClusterId != null) {
      if (_lastFocusedStoryCluster == null) {
        _lastFocusedStoryClusterId = null;
        _onStoryListChanged();
        _focusLossListeners.forEach((VoidCallback listener) => listener());
      }
    }
  }

  void _onStoryListChanged() {
    List<String> focusedStoryIds = _lastFocusedStoryCluster?.stories
            ?.map<String>((Story story) => story.id.value)
            ?.toList() ??
        <String>[];
    _focusController.onFocusedStoriesChanged(focusedStoryIds);
    hitTestModel.onFocusedStoriesChanged(focusedStoryIds);
  }

  StoryCluster get _lastFocusedStoryCluster {
    if (_lastFocusedStoryClusterId == null) {
      return null;
    }
    Iterable<StoryCluster> storyClusters = _storyModel.storyClusters.where(
      (StoryCluster storyCluster) =>
          storyCluster.id == _lastFocusedStoryClusterId,
    );
    if (storyClusters.isEmpty) {
      return null;
    }
    assert(storyClusters.length == 1);
    return storyClusters.first;
  }

  void _onAskSuggestionsChanged() {
    if (_asking) {
      _currentSuggestions = _askListener.suggestions;
      notifyListeners();
    }
  }

  void _onNextSuggestionsChanged() {
    if (!_asking) {
      _currentSuggestions = _nextListener.suggestions;
      notifyListeners();
    }
  }
}
