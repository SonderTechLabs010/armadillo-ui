// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dart:ui' show lerpDouble;

import 'important_info.dart';
import 'model.dart';
import 'now.dart';
import 'opacity_model.dart';
import 'quick_settings.dart';
import 'time_stringer.dart';
import 'user_context_text.dart';

export 'model.dart' show ScopedModel, Model;

const String _kUserImage = 'packages/armadillo/res/User.png';
const String _kBatteryImageWhite =
    'packages/armadillo/res/ic_battery_90_white_1x_web_24dp.png';

/// Manages the contents of [Now].
class NowModel extends Model {
  final TimeStringer _timeStringer = new TimeStringer();

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static NowModel of(BuildContext context) =>
      new ModelFinder<NowModel>().of(context);

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (listenerCount == 1) {
      _timeStringer.addListener(notifyListeners);
    }
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (listenerCount == 0) {
      _timeStringer.removeListener(notifyListeners);
    }
  }

  // These are animation values, updated by the Now widget through the two
  // listeners below
  double _quickSettingsProgress = 0.0;

  /// Updates the progress of quick settings being shown.
  set quickSettingsProgress(double quickSettingsProgress) {
    _quickSettingsProgress = quickSettingsProgress;
    notifyListeners();
  }

  /// Returns an avatar of the current user.
  Widget get user => new Image.asset(_kUserImage, fit: BoxFit.cover);

  /// Returns a verbose representation of the user's current context.
  Widget userContextMaximized({double opacity: 1.0}) => new Opacity(
        opacity: opacity < 0.8 ? 0.0 : ((opacity - 0.8) / 0.2),
        child: new Transform(
          transform: new Matrix4.translationValues(
            lerpDouble(
              -16.0,
              0.0,
              opacity < 0.8 ? 0.0 : ((opacity - 0.8) / 0.2),
            ),
            lerpDouble(0.0, 32.0, _quickSettingsProgress),
            0.0,
          ),
          child: new UserContextText(
            textColor: Color.lerp(
              Colors.white,
              Colors.grey[600],
              _quickSettingsProgress,
            ),
          ),
        ),
      );

  /// Returns a succinct representation of the user's current context.
  Widget get userContextMinimized => new Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: new RepaintBoundary(
          child: new ScopedModelDescendant<OpacityModel>(
            builder: (
              BuildContext context,
              Widget child,
              OpacityModel opacityModel,
            ) =>
                new Opacity(
                  opacity: opacityModel.opacity,
                  child: child,
                ),
            child: new Text('${_timeStringer.shortString}'),
          ),
        ),
      );

  /// Returns a verbose representation of the important information to the user
  /// with the given [opacity].
  Widget importantInfoMaximized({double opacity: 1.0}) => new Opacity(
        opacity: opacity < 0.8 ? 0.0 : ((opacity - 0.8) / 0.2),
        child: new Transform(
          transform: new Matrix4.translationValues(
            lerpDouble(
              16.0,
              0.0,
              opacity < 0.8 ? 0.0 : ((opacity - 0.8) / 0.2),
            ),
            lerpDouble(0.0, 32.0, _quickSettingsProgress),
            0.0,
          ),
          child: new ImportantInfo(
            textColor: Color.lerp(
              Colors.white,
              Colors.grey[600],
              _quickSettingsProgress,
            ),
          ),
        ),
      );

  /// Returns a succinct representation of the important information to the
  /// user.
  Widget get importantInfoMinimized => new Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 4.0),
            child: new RepaintBoundary(
              child: new ScopedModelDescendant<OpacityModel>(
                builder: (
                  BuildContext context,
                  Widget child,
                  OpacityModel opacityModel,
                ) =>
                    new Opacity(
                      opacity: opacityModel.opacity,
                      child: child,
                    ),
                child: new Text('89%'),
              ),
            ),
          ),
          new RepaintBoundary(
            child: new ScopedModelDescendant<OpacityModel>(
              builder: (
                BuildContext context,
                Widget child,
                OpacityModel opacityModel,
              ) =>
                  new Image.asset(
                    _kBatteryImageWhite,
                    color: Colors.white.withOpacity(opacityModel.opacity),
                    fit: BoxFit.cover,
                  ),
            ),
          ),
        ],
      );

  /// Returns the quick settings to show when [Now] is in its quick settings
  /// mode.
  Widget quickSettings({double opacity: 1.0, VoidCallback onLogoutSelected}) =>
      new QuickSettings(opacity: opacity, onLogoutSelected: onLogoutSelected);
}
