// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard/keyboard.dart';
import 'package:keyboard/keys.dart';
import 'package:sysui_widgets/device_extension_state.dart';

/// A device extension for the [Keyboard].
class KeyboardDeviceExtension extends StatefulWidget {
  final Key keyboardKey;
  final OnText onText;
  final OnText onSuggestion;
  final OnDelete onDelete;
  final OnGo onGo;
  KeyboardDeviceExtension(
      {Key key,
      this.keyboardKey,
      this.onText,
      this.onSuggestion,
      this.onDelete,
      this.onGo})
      : super(key: key);
  @override
  KeyboardDeviceExtensionState createState() =>
      new KeyboardDeviceExtensionState();
}

class KeyboardDeviceExtensionState
    extends DeviceExtensionState<KeyboardDeviceExtension> {
  @override
  Widget createWidget(BuildContext context) => new Container(
      decoration: new BoxDecoration(backgroundColor: Colors.black),
      child: new Keyboard(
          key: config.keyboardKey,
          onText: config.onText,
          onSuggestion: config.onSuggestion,
          onDelete: config.onDelete,
          onGo: config.onGo));
}
