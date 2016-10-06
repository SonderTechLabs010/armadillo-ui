// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/icon_slider.dart';

import 'toggle_icon.dart';

// Width and height of the icons
const double _kIconSize = 24.0;

// Image assets
const String _kAirplaneModeInactiveGrey600 =
    'packages/armadillo/res/ic_airplanemode_inactive_grey600.png';
const String _kAirplaneModeActiveBlack =
    'packages/armadillo/res/ic_airplanemode_active_black.png';
const String _kDoNoDisturbOffGrey600 =
    'packages/armadillo/res/ic_do_not_disturb_off_grey600.png';
const String _kDoNoDisturbOnBlack =
    'packages/armadillo/res/ic_do_not_disturb_on_black.png';
const String kScreenLockRotationBlack =
    'packages/armadillo/res/ic_screen_lock_rotation_black.png';
const String kScreenRotationBlack =
    'packages/armadillo/res/ic_screen_rotation_black.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';
const String _kMicImageGrey600 =
    'packages/armadillo/res/ic_mic_grey600_1x_web_24dp.png';
const String _kBrightnessHighGrey600 =
    'packages/armadillo/res/ic_brightness_high_grey600.png';
const String _kVolumeUpGrey600 =
    'packages/armadillo/res/ic_volume_up_grey600.png';

const Color _kTurquoise = const Color(0xFF1DE9B6);
const Color _kActiveSliderColor = _kTurquoise;

/// If [QuickSettings size] is wider than this, the contents will be laid out
/// into multiple columns instead of a single column.
const double _kMultiColumnWidthThreshold = 450.0;

class QuickSettings extends StatefulWidget {
  @override
  _QuickSettingsState createState() => new _QuickSettingsState();
}

class _QuickSettingsState extends State<QuickSettings> {
  double _volumeSliderValue = 0.0;
  double _brightnessSliderValue = 0.0;

  final GlobalKey _kAirplaneModeToggle = new GlobalKey();
  final GlobalKey _kDoNotDisturbModeToggle = new GlobalKey();
  final GlobalKey _kScreenRotationToggle = new GlobalKey();

  Widget _divider() {
    return new Divider(height: 4.0, color: Colors.grey[300]);
  }

  Widget _volumeIconSlider() => new IconSlider(
        value: _volumeSliderValue,
        min: 0.0,
        max: 100.0,
        activeColor: _kActiveSliderColor,
        thumbImage: new AssetImage(_kVolumeUpGrey600),
        onChanged: (double value) {
          setState(() {
            _volumeSliderValue = value;
          });
        },
      );

  Widget _brightnessIconSlider() => new IconSlider(
        value: _brightnessSliderValue,
        min: 0.0,
        max: 100.0,
        activeColor: _kActiveSliderColor,
        thumbImage: new AssetImage(_kBrightnessHighGrey600),
        onChanged: (double value) {
          setState(() {
            _brightnessSliderValue = value;
          });
        },
      );

  Widget _airplaneModeToggleIcon() => new ToggleIcon(
        key: _kAirplaneModeToggle,
        imageList: [
          _kAirplaneModeInactiveGrey600,
          _kAirplaneModeActiveBlack,
        ],
        initialImageIndex: 1,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _doNotDisturbToggleIcon() => new ToggleIcon(
        key: _kDoNotDisturbModeToggle,
        imageList: [
          _kDoNoDisturbOnBlack,
          _kDoNoDisturbOffGrey600,
        ],
        initialImageIndex: 0,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _screenRotationToggleIcon() => new ToggleIcon(
        key: _kScreenRotationToggle,
        imageList: [
          kScreenLockRotationBlack,
          kScreenRotationBlack,
        ],
        initialImageIndex: 0,
        width: _kIconSize,
        height: _kIconSize,
      );

  Widget _buildForNarrowScreen(BuildContext context) {
    return new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _volumeIconSlider(),
          _brightnessIconSlider(),
          _divider(),
          new Row(children: [
            new Flexible(
              flex: 1,
              child: _airplaneModeToggleIcon(),
            ),
            new Flexible(
              flex: 1,
              child: _doNotDisturbToggleIcon(),
            ),
            new Flexible(
              flex: 1,
              child: _screenRotationToggleIcon(),
            ),
          ]),
        ]);
  }

  Widget _buildForWideScreen(BuildContext context) => new Row(children: [
        new Flexible(
          flex: 3,
          child: _volumeIconSlider(),
        ),
        new Flexible(
          flex: 3,
          child: _brightnessIconSlider(),
        ),
        new Flexible(
          flex: 1,
          child: _airplaneModeToggleIcon(),
        ),
        new Flexible(
          flex: 1,
          child: _doNotDisturbToggleIcon(),
        ),
        new Flexible(
          flex: 1,
          child: _screenRotationToggleIcon(),
        ),
      ]);

  @override
  Widget build(BuildContext context) {
    return new Material(
      type: MaterialType.canvas,
      color: Colors.transparent,
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _divider(),
          new Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: new LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) =>
                    (constraints.maxWidth > _kMultiColumnWidthThreshold)
                        ? _buildForWideScreen(context)
                        : _buildForNarrowScreen(context)),
          ),
          _divider(),
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
                    fontWeight: FontWeight.w700, color: Colors.grey[600]),
              ),
            ),
          )
        ],
      ),
    );
  }
}
