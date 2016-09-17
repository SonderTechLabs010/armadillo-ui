// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'config_manager.dart';
import 'time_stringer.dart';

const String _kUserImage = 'packages/armadillo/res/User.png';
const String _kBatteryImageWhite =
    'packages/armadillo/res/ic_battery_90_white_1x_web_24dp.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';

/// Manages the contents of [Now].
class NowManager extends ConfigManager {
  final TimeStringer _timeStringer = new TimeStringer();

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

  double _quickSettingsProgress = 0.0;

  set quickSettingsProgress(double quickSettingsProgress) {
    _quickSettingsProgress = quickSettingsProgress;
    notifyListeners();
  }

  Widget get user => new Image.asset(_kUserImage, fit: ImageFit.cover);

  Widget get userContextMaximized => new Text(
        '${_timeStringer.longString} Mountain View'.toUpperCase(),
        style: _textStyle,
      );

  Widget get userContextMinimized => new Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: new Text('${_timeStringer.shortString}'),
      );

  Widget get importantInfoMaximized => new Stack(
        children: [
          new Opacity(
            opacity: 1.0 - _quickSettingsProgress,
            child: new Image.asset(
              _kBatteryImageWhite,
              fit: ImageFit.cover,
            ),
          ),
          new Opacity(
            opacity: _quickSettingsProgress,
            child: new Image.asset(
              _kBatteryImageGrey600,
              fit: ImageFit.cover,
            ),
          ),
        ],
      );

  Widget get importantInfoMinimized => new Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          new Padding(
              padding: const EdgeInsets.only(top: 4.0, right: 4.0),
              child: new Text('89%')),
          new Image.asset(_kBatteryImageWhite, fit: ImageFit.cover),
        ],
      );

  Widget get quickSettings => new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          new Container(
            padding: const EdgeInsets.all(16.0),
            child: new Text(
              'quick settings',
              textAlign: TextAlign.center,
              style: new TextStyle(color: Colors.grey[600]),
            ),
          ),
          new Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: new Divider(height: 1.0, color: Colors.grey[600]),
          ),
          new GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              print('Make Inline Quick Settings into Story!');
            },
            child: new Container(
              padding: const EdgeInsets.all(16.0),
              child: new Text(
                'MORE',
                textAlign: TextAlign.center,
                style: new TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      );

  TextStyle get _textStyle => TextStyle.lerp(
        new TextStyle(color: Colors.white),
        new TextStyle(color: Colors.grey[600]),
        _quickSettingsProgress,
      );
}

class InheritedNowManager extends InheritedConfigManager<NowManager> {
  InheritedNowManager({
    Key key,
    Widget child,
    NowManager nowManager,
  })
      : super(
          key: key,
          child: child,
          configManager: nowManager,
        );

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedNowManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static NowManager of(BuildContext context) {
    InheritedNowManager inheritedNowManager =
        context.inheritFromWidgetOfExactType(InheritedNowManager);
    return inheritedNowManager?.configManager;
  }
}
