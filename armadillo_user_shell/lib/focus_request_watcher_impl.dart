// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/focus.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'debug.dart';

/// Called when we receive a request to focus on [storyId];
typedef void OnFocusRequest(String storyId);

/// Listens for requests to change the currently focused story.
class FocusRequestWatcherImpl extends FocusRequestWatcher {
  final FocusRequestWatcherBinding _binding = new FocusRequestWatcherBinding();

  /// Called when we receive a request to focus on a story.
  final OnFocusRequest onFocusRequest;

  /// Constructor.
  FocusRequestWatcherImpl({this.onFocusRequest});

  /// Returns the handle for this [FocusRequestWatcher].
  InterfaceHandle<FocusRequestWatcher> getHandle() => _binding.wrap(this);

  @override
  void onRequest(String storyId) {
    armadilloPrint('Received request to focus story: $storyId');
    onFocusRequest(storyId);
  }
}
