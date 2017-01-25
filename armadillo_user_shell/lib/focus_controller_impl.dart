// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'debug.dart';

typedef void OnFocusStory(String storyId);

class FocusControllerImpl extends FocusController {
  final List<FocusControllerBinding> _bindings = <FocusControllerBinding>[];
  final List<FocusListenerProxy> _listeners = <FocusListenerProxy>[];
  final OnFocusStory onFocusStory;

  FocusControllerImpl({this.onFocusStory});

  void bind(InterfaceRequest<FocusController> request) {
    FocusControllerBinding binding = new FocusControllerBinding();
    binding.bind(this, request);
    _bindings.add(binding);
  }

  @override
  void focusStory(String storyId) {
    armadilloPrint('focus story: $storyId');
    onFocusStory(storyId);
  }

  @override
  void watch(InterfaceHandle<FocusListener> focusListenerHandle) {
    FocusListenerProxy focusListener = new FocusListenerProxy();
    focusListener.ctrl.bind(focusListenerHandle);
    _listeners.add(focusListener);
  }

  @override
  void duplicate(InterfaceRequest<FocusController> request) {
    bind(request);
  }

  void onFocusedStoriesChanged(List<String> focusedStories) {
    _listeners.toList().forEach((FocusListenerProxy focusListener) {
      focusListener.onFocusChanged(focusedStories);
    });
  }
}
