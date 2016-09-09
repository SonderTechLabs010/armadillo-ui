// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

const String _kUserImage = 'packages/armadillo/res/User.png';
const String _kBatteryImageWhite =
    'packages/armadillo/res/ic_battery_90_white_1x_web_24dp.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';

/// Manages the contents of [Now].
class NowManager {
  final Set<VoidCallback> _listeners = new Set<VoidCallback>();
  int version = 0;
  double _quickSettingsProgress = 0.0;

  NowManager();

  /// Should be called only by those who instantiate
  /// [InheritedNowManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when suggestions change, use
  /// [InheritedNowManager.of].
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Should be called only by those who instantiate
  /// [InheritedNowManager] so they can [State.setState].  If you're a
  /// [Widget] that wants to be rebuilt when suggestions change, use
  /// [InheritedNowManager.of].
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  set quickSettingsProgress(double quickSettingsProgress) {
    _quickSettingsProgress = quickSettingsProgress;
    _notifyListeners();
  }

  Widget get user => new Image.asset(_kUserImage, fit: ImageFit.cover);

  Widget get userContextMaximized => new Text(
        'Saturday 4:23 Sierra Vista'.toUpperCase(),
        style: _textStyle,
      );

  Widget get userContextMinimized => new Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: new Text('4:23'),
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

  Widget get quickSettings => new Align(
        alignment: FractionalOffset.bottomCenter,
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ),
      );

  TextStyle get _textStyle => TextStyle.lerp(
        new TextStyle(color: Colors.white),
        new TextStyle(color: Colors.grey[600]),
        _quickSettingsProgress,
      );

  void _notifyListeners() {
    version++;
    _listeners.toList().forEach((VoidCallback listener) => listener());
  }
}

class InheritedNowManager extends InheritedWidget {
  final NowManager nowManager;
  final int nowManagerVersion;
  InheritedNowManager({Key key, Widget child, NowManager nowManager})
      : this.nowManager = nowManager,
        this.nowManagerVersion = nowManager.version,
        super(key: key, child: child);

  @override
  bool updateShouldNotify(InheritedNowManager oldWidget) =>
      (oldWidget.nowManagerVersion != nowManagerVersion);

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedNowManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static NowManager of(BuildContext context) {
    InheritedNowManager inheritedNowManager =
        context.inheritFromWidgetOfExactType(InheritedNowManager);
    return inheritedNowManager?.nowManager;
  }
}
