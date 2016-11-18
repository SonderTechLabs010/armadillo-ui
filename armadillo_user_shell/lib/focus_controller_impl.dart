// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'debug.dart';

class FocusControllerImpl extends FocusController {
  final FocusControllerBinding _binding = new FocusControllerBinding();
  final List<FocusListenerProxy> _listeners = <FocusListenerProxy>[];

  void bind(InterfaceRequest<FocusController> request) {
    _binding.bind(this, request);
  }

  @override
  void focusStory(String storyId) {
    armadilloPrint('focus story: $storyId');
  }

  @override
  void watch(InterfaceHandle<FocusListener> focusListenerHandle) {
    armadilloPrint('watch: $focusListener');
    FocusListenerProxy focusListener = new FocusListenerProxy();
    focusListener.ctrl.bind(focusListenerHandle);
    _listeners.add(focusListener);
  }
}
