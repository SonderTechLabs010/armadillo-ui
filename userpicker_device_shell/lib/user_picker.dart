// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.device/user_provider.fidl.dart';
import 'package:flutter/material.dart';
import 'package:lib.widgets/hacks.dart' as hacks;
import 'package:lib.widgets/widgets.dart';

import 'user_picker_device_shell_model.dart';

const String _kDefaultUserName = 'Guest';
const String _kDefaultDeviceName = 'fuchsia';
const String _kDefaultServerName = 'ledger.fuchsia.com';
const Color _kFuchsiaColor = const Color(0xFFFF0080);
const double _kButtonContentWidth = 220.0;
const double _kButtonContentHeight = 80.0;

/// Called when the user wants to login as [user] using [userProvider].
typedef void OnLoginRequest(String user, UserProvider userProvider);

/// Provides a UI for picking a user.
class UserPicker extends StatelessWidget {
  /// Called when the user want's to log in.
  final OnLoginRequest onLoginRequest;

  /// The text controller for the user name of a new user.
  final TextEditingController userNameController;

  /// The text controller for the device name of a new user.
  final TextEditingController deviceNameController;

  /// The text controller for the server name of a new user.
  final TextEditingController serverNameController;

  /// Constructor.
  UserPicker({
    this.onLoginRequest,
    this.userNameController,
    this.deviceNameController,
    this.serverNameController,
  });

  Widget _buildNewUserForm(UserPickerDeviceShellModel model) {
    return new Overlay(initialEntries: <OverlayEntry>[
      new OverlayEntry(
        builder: (BuildContext context) => new Material(
              color: Colors.grey[300],
              borderRadius: new BorderRadius.circular(8.0),
              elevation: 4,
              child: new Container(
                width: _kButtonContentWidth,
                padding: const EdgeInsets.all(16.0),
                child: new Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // TODO(apwilson): Use TextField ONCE WE HAVE A PROPER
                    // IME ON FUCHSIA!
                    new hacks.RawKeyboardTextField(
                      decoration: new InputDecoration(
                        hintText: 'Enter user name',
                      ),
                      controller: userNameController,
                    ),
                    new hacks.RawKeyboardTextField(
                      decoration: new InputDecoration(
                        hintText: 'Enter device name',
                      ),
                      controller: deviceNameController,
                    ),
                    new hacks.RawKeyboardTextField(
                      decoration: new InputDecoration(
                        hintText: 'Enter server name',
                      ),
                      controller: serverNameController,
                    ),
                    new Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 16.0,
                      ),
                      child: new RaisedButton(
                        color: Colors.blue[500],
                        onPressed: () => _createAndLoginUser(
                              userNameController.text,
                              deviceNameController.text,
                              serverNameController.text,
                              model,
                            ),
                        child: new Container(
                          width: _kButtonContentWidth - 32.0,
                          height: _kButtonContentHeight,
                          child: new Center(
                            child: new Text(
                              'Create and Log in',
                              style: new TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    ]);
  }

  Widget _buildUserEntry({String user, VoidCallback onTap}) => new InkWell(
        highlightColor: _kFuchsiaColor.withAlpha(200),
        onTap: () => onTap(),
        borderRadius: new BorderRadius.all(new Radius.circular(8.0)),
        child: new Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new Container(
                padding: const EdgeInsets.all(2.0),
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.all(
                    new Radius.circular(40.0),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: new Alphatar.fromName(
                  name: user.toUpperCase(),
                  size: 80.0,
                ),
              ),
              new Container(
                margin: const EdgeInsets.only(top: 16.0),
                padding: const EdgeInsets.all(4.0),
                decoration: new BoxDecoration(
                  borderRadius: new BorderRadius.all(new Radius.circular(4.0)),
                  backgroundColor: Colors.black.withAlpha(240),
                ),
                child: new Text(
                  user.toUpperCase(),
                  style: new TextStyle(
                    color: Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildUserList(UserPickerDeviceShellModel model) {
    List<Widget> children;
    if (model.users.isEmpty) {
      children = <Widget>[
        _buildUserEntry(
          user: _kDefaultUserName,
          onTap: () {
            _createAndLoginUser(
              _kDefaultUserName,
              _kDefaultDeviceName,
              _kDefaultServerName,
              model,
            );
          },
        ),
      ];
    } else {
      children = model.users.map((String user) {
        return _buildUserEntry(
          user: user,
          onTap: () => _loginUser(user, model),
        );
      }).toList();
    }

    return new Material(
      borderRadius: new BorderRadius.all(new Radius.circular(8.0)),
      color: Colors.black.withAlpha(0),
      child: new Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<UserPickerDeviceShellModel>(builder: (
        BuildContext context,
        Widget child,
        UserPickerDeviceShellModel model,
      ) {
        if (model.users != null) {
          List<Widget> stackChildren = <Widget>[
            new Center(
              child: new Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _buildUserList(model),
                ],
              ),
            ),
          ];

          if (model.isShowingNewUserForm) {
            stackChildren.add(new GestureDetector(
              onTapUp: (_) => model.hideNewUserForm(),
              child: new Container(
                color: Colors.black.withAlpha(180),
              ),
            ));
            stackChildren.add(new Center(
              child: _buildNewUserForm(model),
            ));
          }

          return new Stack(
            fit: StackFit.passthrough,
            children: stackChildren,
          );
        } else {
          return new Container(
            width: 64.0,
            height: 64.0,
            child: new CircularProgressIndicator(
              valueColor: new AlwaysStoppedAnimation<Color>(_kFuchsiaColor),
            ),
          );
        }
      });

  void _createAndLoginUser(
    String user,
    String deviceName,
    String serverName,
    UserPickerDeviceShellModel model,
  ) {
    // Add the user if it doesn't already exist.
    if (!(model.users?.contains(user) ?? false)) {
      if (user?.isEmpty ?? true) {
        print('Not creating user: User name needs to be set!');
        return;
      }
      if (deviceName?.isEmpty ?? true) {
        print('Not creating user: Device name needs to be set!');
        return;
      }
      if (serverName?.isEmpty ?? true) {
        print('Not creating user: Server name needs to be set!');
        return;
      }
      print(
          'UserPicker: Creating user $user with device $deviceName and server $serverName!');
      model.userProvider?.addUser(
        user,
        null,
        deviceName,
        serverName,
      );
    }

    _loginUser(user, model);
  }

  void _loginUser(String user, UserPickerDeviceShellModel model) {
    print('UserPicker: Logging in as $user!');
    onLoginRequest?.call(user, model.userProvider);
  }
}
