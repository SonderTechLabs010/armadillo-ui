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
  /// The flutter [Key] for the [Keyboard] child of this [Widget].
  final Key keyboardKey;

  /// Called when a key is tapped on the keyboard.
  final OnText onText;

  /// Called when a suggestion is tapped on the keyboard.
  final OnText onSuggestion;

  /// Called when 'Delete' is tapped on the keyboard.
  final VoidCallback onDelete;

  /// Called when 'Go' is tapped on the keyboard.
  final VoidCallback onGo;

  /// Constructor.
  KeyboardDeviceExtension(
      {Key key,
      this.keyboardKey,
      this.onText,
      this.onSuggestion,
      this.onDelete,
      this.onGo})
      : super(key: key);

  @override
  _KeyboardDeviceExtensionState createState() =>
      new _KeyboardDeviceExtensionState();
}

class _KeyboardDeviceExtensionState
    extends DeviceExtensionState<KeyboardDeviceExtension> {
  @override
  Widget createWidget(BuildContext context) => new Container(
        color: Colors.black,
        child: new Keyboard(
          key: widget.keyboardKey,
          onText: widget.onText,
          onSuggestion: widget.onSuggestion,
          onDelete: widget.onDelete,
          onGo: widget.onGo,
        ),
      );
}
