// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'circular_button.dart';

import 'user_picker_device_shell_model.dart';

/// Main buttons (Shutdown, New User) for the User Picker
class UserPickerButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<UserPickerDeviceShellModel>(
        builder: (
          BuildContext context,
          Widget child,
          UserPickerDeviceShellModel model,
        ) => new Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new CircularButton(
              icon: Icons.power_settings_new,
              onTap: () => model.deviceShellContext?.shutdown(),
            ),
            new Container(
              margin: const EdgeInsets.only(left: 16.0),
              child: new CircularButton(
                icon: Icons.person_add,
                onTap: () => model.showNewUserForm(),
              ),
            ),
          ],
        )
      );
}
