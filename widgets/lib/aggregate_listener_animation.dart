// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

/// Used to allow [AnimatedBuilder] to listen to a list of [Animation]s instead
/// of just one.
/// As this [Animation] is for use with [AnimatedBuilder] and [AnimatedBuilder]
/// doesn't use [addStatusListener], [removeStatusListener], [status], or
/// [value] we don't implement them.
class AggregateListenerAnimation extends Animation {
  final List<Animation> children;

  AggregateListenerAnimation({this.children});

  @override
  void addListener(VoidCallback listener) =>
      children.forEach((Animation child) => child.addListener(listener));

  @override
  void removeListener(VoidCallback listener) =>
      children.forEach((Animation child) => child.removeListener(listener));

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      throw new UnsupportedError(
          'addStatusListener cannot be called on AggregateListenerAnimation');

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      throw new UnsupportedError(
          'removeStatusListener cannot be called on AggregateListenerAnimation');

  @override
  AnimationStatus get status => throw new UnsupportedError(
      'status cannot be called on AggregateListenerAnimation');

  @override
  Object get value => throw new UnsupportedError(
      'value cannot be called on AggregateListenerAnimation.');

  @override
  String toString() => "AggregateListenerAnimation";
}
