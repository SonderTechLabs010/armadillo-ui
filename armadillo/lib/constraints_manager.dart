// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'config_manager.dart';

const String _kJsonUrl = 'packages/armadillo/res/screen_config.json';

/// Reads possible screen sizes from a configuraion json file.
class ConstraintsManager extends ConfigManager {
  List<BoxConstraints> _currentConstraints = const <BoxConstraints>[
    const BoxConstraints()
  ];

  void load(AssetBundle assetBundle) {
    assetBundle.loadString(_kJsonUrl).then((String json) {
      final decodedJson = JSON.decode(json);

      // Load screen sizes.
      _currentConstraints = decodedJson['screen_sizes']
          .map(
            (Map<String, Object> constraint) => new BoxConstraints.tightFor(
                  width: constraint['width'] != null
                      ? double.parse(constraint['width'])
                      : null,
                  height: constraint['height'] != null
                      ? double.parse(constraint['height'])
                      : null,
                ),
          )
          .toList();
      _currentConstraints.insert(0, const BoxConstraints());
      notifyListeners();
    });
  }

  List<BoxConstraints> get constraints => _currentConstraints;
}

class InheritedConstraintManager
    extends InheritedConfigManager<ConstraintsManager> {
  InheritedConstraintManager({
    Key key,
    Widget child,
    ConstraintsManager constraintsManager,
  })
      : super(
          key: key,
          child: child,
          configManager: constraintsManager,
        );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedConstraintManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static ConstraintsManager of(BuildContext context) {
    InheritedConstraintManager inheritedConstraintManager =
        context.inheritFromWidgetOfExactType(InheritedConstraintManager);
    return inheritedConstraintManager?.configManager;
  }
}
