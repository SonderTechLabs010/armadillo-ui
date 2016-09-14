// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dart:math' as math;

import 'config_manager.dart';
import 'quick_settings.dart';
import 'time_stringer.dart';

const String _kUserImage = 'packages/armadillo/res/User.png';
const String _kBatteryImageWhite =
    'packages/armadillo/res/ic_battery_90_white_1x_web_24dp.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';
const String _kWifiImageGrey600 =
    'packages/armadillo/res/ic_signal_wifi_3_bar_grey600_24dp.png';
const String _kNetworkSignalImageGrey600 =
    'packages/armadillo/res/ic_signal_cellular_connected_no_internet_0_bar_grey600_24dp.png';

const double _kImportantInfoIconSize = 24.0;

// Reserve a width of 24 in important info so you're always showing
// the first icon (the battery icon)
const double _kImportantInfoMinWidth = _kImportantInfoIconSize;

// The width of the quick settings background when fully maximized
const double _kQuickSettingsBackgroundMaximizedWidth = 424.0;

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

  // These are animation values, updated by the Now widget through the two
  // listeners below
  double _quickSettingsProgress = 0.0;
  double _quickSettingsSlideUpProgress = 0.0;

  set quickSettingsProgress(double quickSettingsProgress) {
    _quickSettingsProgress = quickSettingsProgress;
    notifyListeners();
  }

  set quickSettingsSlideUpProgress(double quickSettingsSlideUpProgress) {
    _quickSettingsSlideUpProgress = quickSettingsSlideUpProgress;
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

  double get importantInfoMinWidth => _kImportantInfoMinWidth;

  double get quickSettingsBackgroundMaximizedWidth =>
      _kQuickSettingsBackgroundMaximizedWidth;

  Widget get importantInfoMaximized {
    double maxWidth = _kQuickSettingsBackgroundMaximizedWidth;
    return new Container(
      // TODO(mikejurka): don't hardcode height after OverflowBox is fixed
      height: 32.0,
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // battery icon
          new Container(
            width: _kImportantInfoMinWidth,
            child: new Stack(
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
            ),
          ),
          new Flexible(
            child: new ClipRect(
              child: new OverflowBox(
                alignment: FractionalOffset.centerLeft,
                minHeight: 0.0,
                maxHeight: double.INFINITY,
                maxWidth: double.INFINITY,
                minWidth: 0.0,
                child: new Container(
                  width: math.max(0.0, maxWidth - _kImportantInfoMinWidth),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // battery text
                      new Flexible(
                        child: new Opacity(
                          opacity: _quickSettingsSlideUpProgress,
                          child: new Text(
                            '84% 2H 54MIN',
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.left,
                            style: new TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      // wifi icon
                      new Opacity(
                        opacity: _quickSettingsSlideUpProgress,
                        child: new Image.asset(
                          _kWifiImageGrey600,
                          width: _kImportantInfoIconSize,
                          height: _kImportantInfoIconSize,
                          fit: ImageFit.cover,
                        ),
                      ),
                      // wifi text
                      new Flexible(
                        child: new Opacity(
                          opacity: _quickSettingsSlideUpProgress,
                          child: new Text(
                            '0024b10000021ecd',
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.left,
                            style: new TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),

                      // network icon
                      new Opacity(
                        opacity: _quickSettingsSlideUpProgress,
                        child: new Image.asset(
                          _kNetworkSignalImageGrey600,
                          width: _kImportantInfoIconSize,
                          height: _kImportantInfoIconSize,
                          fit: ImageFit.cover,
                        ),
                      ),
                      // network text
                      new Flexible(
                        child: new Opacity(
                          opacity: _quickSettingsSlideUpProgress,
                          child: new Text(
                            'T-MOBILE',
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.left,
                            style: new TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get importantInfoMinimized => new Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          new Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 4.0),
            child: new Text('89%'),
          ),
          new Image.asset(_kBatteryImageWhite, fit: ImageFit.cover),
        ],
      );

  Widget get quickSettings => new QuickSettings();

  TextStyle get _textStyle => TextStyle.lerp(
        new TextStyle(color: Colors.white),
        new TextStyle(color: Colors.grey[600]),
        _quickSettingsProgress,
      );
}

class InheritedNowManager extends InheritedConfigManager<NowManager> {
  InheritedNowManager({Key key, Widget child, NowManager nowManager})
      : super(key: key, child: child, configManager: nowManager);

  /// [Widget]s who call [of] will be rebuilt whenever [updateShouldNotify]
  /// returns true for the [InheritedNowManager] returned by
  /// [BuildContext.inheritFromWidgetOfExactType].
  static NowManager of(BuildContext context) {
    InheritedNowManager inheritedNowManager =
        context.inheritFromWidgetOfExactType(InheritedNowManager);
    return inheritedNowManager?.configManager;
  }
}
