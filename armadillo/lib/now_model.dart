// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dart:math' as math;

import 'model.dart';
import 'now.dart';
import 'opacity_model.dart';
import 'quick_settings.dart';
import 'time_stringer.dart';

export 'model.dart' show ScopedModel, Model;

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

// Padding between an icon and the text label to the right in important info
const double _kIconLabelPadding = 4.0;

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
  double _quickSettingsSlideUpProgress = 0.0;

  set quickSettingsProgress(double quickSettingsProgress) {
    _quickSettingsProgress = quickSettingsProgress;
    notifyListeners();
  }

  set quickSettingsSlideUpProgress(double quickSettingsSlideUpProgress) {
    _quickSettingsSlideUpProgress = quickSettingsSlideUpProgress;
    notifyListeners();
  }

  Widget get user => new Image.asset(_kUserImage, fit: BoxFit.cover);

  Widget userContextMaximized({double opacity: 1.0}) => new Opacity(
        opacity: opacity,
        child: new Text(
          '${_timeStringer.longString} Mountain View'.toUpperCase(),
          style: _textStyle,
        ),
      );

  Widget get userContextMinimized => new Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: new RepaintBoundary(
          child: new ScopedModelDecendant<OpacityModel>(
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

  double get importantInfoMinWidth =>
      _kImportantInfoMinWidth +
      2 * 8.0; // TODO(mikejurka): pull this into constant

  Widget importantInfoMaximized({double maxWidth, double opacity: 1.0}) {
    return new Container(
      // TODO(mikejurka): don't hardcode height after OverflowBox is fixed
      height: 32.0,
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // battery icon
          new Container(
            width: _kImportantInfoMinWidth,
            child: new Image.asset(
              _kBatteryImageWhite,
              color: Color
                  .lerp(Colors.white, Colors.grey[600], _quickSettingsProgress)
                  .withOpacity(opacity),
              fit: BoxFit.cover,
            ),
          ),
          new Expanded(
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
                    children: <Widget>[
                      // spacer
                      new Container(width: _kIconLabelPadding, height: 1.0),
                      // battery text
                      new Expanded(
                        child: new Opacity(
                          opacity: _quickSettingsSlideUpProgress * opacity,
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
                      new Image.asset(
                        _kWifiImageGrey600,
                        color: Colors.grey[600].withOpacity(
                          _quickSettingsSlideUpProgress * opacity,
                        ),
                        width: _kImportantInfoIconSize,
                        height: _kImportantInfoIconSize,
                        fit: BoxFit.cover,
                      ),
                      // spacer
                      new Container(width: _kIconLabelPadding, height: 1.0),
                      // wifi text
                      new Expanded(
                        child: new Opacity(
                          opacity: _quickSettingsSlideUpProgress * opacity,
                          child: new Text(
                            'GoogleGuest',
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.left,
                            style: new TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),

                      // network icon
                      new Image.asset(
                        _kNetworkSignalImageGrey600,
                        color: Colors.grey[600].withOpacity(
                          _quickSettingsSlideUpProgress * opacity,
                        ),
                        width: _kImportantInfoIconSize,
                        height: _kImportantInfoIconSize,
                        fit: BoxFit.cover,
                      ),
                      // spacer
                      new Container(width: _kIconLabelPadding, height: 1.0),
                      // network text
                      new Expanded(
                        child: new Opacity(
                          opacity: _quickSettingsSlideUpProgress * opacity,
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
        children: <Widget>[
          new Padding(
            padding: const EdgeInsets.only(top: 4.0, right: 4.0),
            child: new RepaintBoundary(
              child: new ScopedModelDecendant<OpacityModel>(
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
            child: new ScopedModelDecendant<OpacityModel>(
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

  Widget quickSettings({double opacity: 1.0}) =>
      new QuickSettings(opacity: opacity);

  TextStyle get _textStyle => TextStyle.lerp(
        new TextStyle(
            color: Colors.white,
            fontSize: 18.0,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w300),
        new TextStyle(color: Colors.grey[600]),
        _quickSettingsProgress,
      );
}
