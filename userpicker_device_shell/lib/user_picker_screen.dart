// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'user_picker_buttons.dart';
import 'user_picker.dart';

/// Displays a [UserPicker] a shutdown button, a new user button, the
/// fuchsia logo, and a background image.
class UserPickerScreen extends StatelessWidget {
  /// The widget that allows a user to be picked.
  final UserPicker userPicker;

  /// Called when the add user button is pressed.
  final VoidCallback onAddUser;

  /// Constructor.
  UserPickerScreen({this.userPicker, this.onAddUser});

  @override
  Widget build(BuildContext context) => new Material(
        color: Colors.grey[900],
        child: new Container(
          child: new Stack(
            fit: StackFit.passthrough,
            children: <Widget>[
              new Image.asset(
                'packages/userpicker_device_shell/res/bg.jpg',
                fit: BoxFit.cover,
              ),

              /// Add Fuchsia logo.
              new Align(
                alignment: FractionalOffset.bottomRight,
                child: new Container(
                  margin: const EdgeInsets.all(16.0),
                  child: new Image.asset(
                    'packages/userpicker_device_shell/res/fuchsia.png',
                    width: 64.0,
                    height: 64.0,
                  ),
                ),
              ),
              new Center(child: userPicker),
              // Add shutdown button and new user button.
              new Align(
                alignment: FractionalOffset.bottomLeft,
                child: new Container(
                  margin: const EdgeInsets.all(16.0),
                  child: new UserPickerButtons(onAddUser: onAddUser),
                ),
              ),
            ],
          ),
        ),
      );
}
