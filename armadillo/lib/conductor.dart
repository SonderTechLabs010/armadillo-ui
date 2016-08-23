// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard/keyboard.dart';
import 'package:sysui_widgets/device_extension_state.dart';

import 'device_extender.dart';
import 'keyboard_device_extension.dart';
import 'now.dart';
import 'peeking_overlay.dart';
import 'recent_list.dart';
import 'suggestion_list.dart';

/// Manages the position, size, and state of the recent list, user context,
/// suggestion overlay, device extensions. interruption overlay, and quick
/// settings overlay.
class Conductor extends StatefulWidget {
  @override
  ConductorState createState() => new ConductorState();
}

const String _kUserImage = 'packages/armadillo/res/User.png';
const String _kBatteryImageWhite =
    'packages/armadillo/res/ic_battery_90_white_1x_web_24dp.png';
const String _kBatteryImageGrey600 =
    'packages/armadillo/res/ic_battery_90_grey600_1x_web_24dp.png';

/// The height of [Now]'s bar when minimized.'
const _kMinimizedNowHeight = 50.0;

/// The height of [Now] when maximized.
const _kMaximizedNowHeight = 400.0;

/// How far [Now] should raise when quick settings is activated inline.
const _kQuickSettingsHeightBump = 240.0;

/// How far above the bottom the suggestions overlay peeks.
const _kSuggestionOverlayPeekHeight = 76.0;

/// When the recent list's scrollOffset exceeds this value we minimize [Now].
const _kNowMinimizationScrollOffsetThreshold = 120.0;

/// When the recent list's scrollOffset exceeds this value we hide quick
/// settings [Now].
const _kNowQuickSettingsHideScrollOffsetThreshold = 16.0;

class ConductorState extends State<Conductor> {
  final GlobalKey _recentListKey = new GlobalKey();
  final GlobalKey<ScrollableState> _recentListScrollableKey =
      new GlobalKey<ScrollableState>();
  final GlobalKey<NowState> _nowKey = new GlobalKey<NowState>();
  final GlobalKey<PeekingOverlayState> _suggestionOverlayKey =
      new GlobalKey<PeekingOverlayState>();
  final GlobalKey<DeviceExtensionState> _keyboardDeviceExtensionKey =
      new GlobalKey<DeviceExtensionState>();
  final GlobalKey<KeyboardState> _keyboardKey = new GlobalKey<KeyboardState>();

  double _quickSettingsProgress = 0.0;
  double _lastScrollOffset = 0.0;

  /// Note in particular the magic we're employing here to make the user
  /// state appear to be a part of the recent list:
  /// By giving the recent list bottom padding and clipping its bottom to the
  /// size of the final user state bar we have the user state appear to be
  /// a part of the recent list and yet prevent the recent list from painting
  /// behind it.
  @override
  Widget build(BuildContext context) => new DeviceExtender(
          deviceExtensions: [
            new KeyboardDeviceExtension(
                key: _keyboardDeviceExtensionKey,
                keyboardKey: _keyboardKey,
                onText: (String text) {
                  print('text $text');
                },
                onSuggestion: (String suggestion) {
                  print('suggestion $suggestion');
                },
                onDelete: () {
                  print('delete');
                },
                onGo: () {
                  print('go');
                }),
          ],
          child: new Stack(children: [
            // Recent List.
            new Positioned(
                left: 0.0,
                right: 0.0,
                top: -_quickSettingsHeightDelta,
                bottom: _quickSettingsHeightDelta,
                child: new ClipRect(
                    clipper: new BottomClipper(bottom: _kMinimizedNowHeight),
                    child: new RecentList(
                        key: _recentListKey,
                        scrollableKey: _recentListScrollableKey,
                        padding:
                            new EdgeInsets.only(bottom: _kMaximizedNowHeight),
                        onScroll: (double scrollOffset) => setState(() {
                              _suggestionOverlayKey.currentState.peek =
                                  scrollOffset <=
                                      _kNowMinimizationScrollOffsetThreshold;
                              if (scrollOffset >
                                  _kNowMinimizationScrollOffsetThreshold) {
                                _nowKey.currentState.minimize();
                              } else {
                                _nowKey.currentState.maximize();
                              }
                              // When we're past the quick settings threshold and are
                              // scrolling further, hide quick settings.
                              if (scrollOffset >
                                      _kNowQuickSettingsHideScrollOffsetThreshold &&
                                  _lastScrollOffset < scrollOffset) {
                                _nowKey.currentState.hideQuickSettings();
                              }
                              _lastScrollOffset = scrollOffset;
                            })))),

            // Now.
            new Positioned(
                bottom: 0.0,
                left: 0.0,
                right: 0.0,
                top: 0.0,
                child: new RepaintBoundary(
                    child: new Now(
                        key: _nowKey,
                        minHeight: _kMinimizedNowHeight,
                        maxHeight: _kMaximizedNowHeight,
                        scrollOffset: _lastScrollOffset,
                        quickSettingsHeightBump: _kQuickSettingsHeightBump,
                        onQuickSettingsProgressChange:
                            (double quickSettingsProgress) => setState(() {
                                  // When quick settings starts being shown, scroll to 0.0.
                                  if (_quickSettingsProgress == 0.0 &&
                                      quickSettingsProgress > 0.0) {
                                    _recentListScrollableKey.currentState
                                        .scrollTo(0.0,
                                            duration: const Duration(
                                                milliseconds: 500),
                                            curve: Curves.fastOutSlowIn);
                                  }
                                  _quickSettingsProgress =
                                      quickSettingsProgress;
                                }),
                        onReturnToOriginButtonTap: () {
                          _recentListScrollableKey.currentState.scrollTo(0.0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.fastOutSlowIn);
                        },
                        onQuickSettingsOverlayButtonTap: () {
                          print('Toggle quick settings overlay!');
                        },
                        onInterruptionsOverlayButtonTap: () {
                          print('Toggle interruptions overlay!');
                        },
                        user: new Image.asset(_kUserImage, fit: ImageFit.cover),
                        userContextMaximized: new Text(
                            'Saturday 4:23 Sierra Vista'.toUpperCase(),
                            style: _textStyle),
                        userContextMinimized: new Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: new Text('4:23')),
                        importantInfoMaximized: new Stack(children: [
                          new Opacity(
                              opacity: 1.0 - _quickSettingsProgress,
                              child: new Image.asset(_kBatteryImageWhite,
                                  fit: ImageFit.cover)),
                          new Opacity(
                              opacity: _quickSettingsProgress,
                              child: new Image.asset(_kBatteryImageGrey600,
                                  fit: ImageFit.cover))
                        ]),
                        importantInfoMinimized: new Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              new Padding(
                                  padding: const EdgeInsets.only(
                                      top: 4.0, right: 4.0),
                                  child: new Text('89%')),
                              new Image.asset(_kBatteryImageWhite,
                                  fit: ImageFit.cover)
                            ]),
                        quickSettings: new Align(
                          alignment: FractionalOffset.bottomCenter,
                          child: new Text('quick settings',
                              style: new TextStyle(color: Colors.grey[600])),
                        )))),

            // Suggestions Overlay.
            new PeekingOverlay(
                key: _suggestionOverlayKey,
                peekHeight: _kSuggestionOverlayPeekHeight,
                onHide: () {
                  _keyboardDeviceExtensionKey?.currentState?.hide();
                },
                child: new SuggestionList(onAskingStarted: () {
                  _keyboardDeviceExtensionKey.currentState.show();
                }, onAskingEnded: () {
                  _keyboardDeviceExtensionKey.currentState.hide();
                }))
          ]));

  double get _quickSettingsHeightDelta =>
      _quickSettingsProgress * (_kQuickSettingsHeightBump - 120.0);

  TextStyle get _textStyle => TextStyle.lerp(new TextStyle(color: Colors.white),
      new TextStyle(color: Colors.grey[600]), _quickSettingsProgress);
}

/// Clips the [bottom] off of [ClipRect]'s child.
class BottomClipper extends CustomClipper<Rect> {
  final double bottom;

  BottomClipper({this.bottom});

  @override
  Rect getClip(Size size) =>
      new Rect.fromLTWH(0.0, 0.0, size.width, size.height - bottom);

  @override
  Rect getApproximateClipRect(Size size) => getClip(size);

  @override
  bool shouldRepaint(BottomClipper oldClipper) => bottom != oldClipper.bottom;
}
