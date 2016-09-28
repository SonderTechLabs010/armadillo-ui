// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

typedef Widget WrapperBuilder(BuildContext context, Widget child);

/// Builds [builder] with [child] if [useWrapper] is true.
/// Builds only [child] if [useWrapper] is false.
class OptionalWrapper extends StatelessWidget {
  final WrapperBuilder builder;
  final Widget child;
  final bool useWrapper;

  OptionalWrapper({this.builder, this.child, this.useWrapper: true});

  @override
  Widget build(BuildContext context) =>
      useWrapper ? builder(context, child) : child;
}
