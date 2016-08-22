// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/default_bundle.dart';
import 'package:sysui_widgets/delegating_page_route.dart';

import 'child_constraints_changer.dart';
import 'armadillo.dart';

const _kConstraints = const <BoxConstraints>[
  const BoxConstraints.tightFor(width: 440.0, height: 440.0 * 16.0 / 9.0),
  const BoxConstraints()
];

Future main() async {
  runApp(new WidgetsApp(
      onGenerateRoute: (RouteSettings settings) => new DelegatingPageRoute(
          (_) => new ChildConstraintsChanger(
              constraints: _kConstraints,
              child: new DefaultAssetBundle(
                  bundle: defaultBundle, child: new Armadillo())),
          settings: settings)));
  SystemChrome.setEnabledSystemUIOverlays(0);
}
