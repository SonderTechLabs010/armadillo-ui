// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.auth.account/account.fidl.dart';
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

/// Called when the user wants to login as [accountId] using [userProvider].
typedef void OnLoginRequest(String accountId, UserProvider userProvider);

/// Provides a UI for picking a user.
class UserPicker extends StatelessWidget {
  /// Called when the user want's to log in.
  final OnLoginRequest onLoginRequest;

  /// The text controller for the user name of a new user.
  final TextEditingController userNameController;

  /// The text controller for the server name of a new user.
  final TextEditingController serverNameController;

  /// The add user user name text field's focus node.
  final FocusNode userNameFocusNode;

  /// The add user server name text field's focus node.
  final FocusNode serverNameFocusNode;

  /// Constructor.
  UserPicker({
    this.onLoginRequest,
    this.userNameController,
    this.serverNameController,
    this.userNameFocusNode,
    this.serverNameFocusNode,
  });

  Widget _buildNewUserForm(UserPickerDeviceShellModel model) {
    return new Overlay(initialEntries: <OverlayEntry>[
      new OverlayEntry(
        builder: (BuildContext context) => new Center(
              child: new Material(
                color: Colors.grey[300],
                borderRadius: new BorderRadius.circular(8.0),
                elevation: 4.0,
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
                          hintText: 'username@example.com',
                        ),
                        focusNode: userNameFocusNode,
                        controller: userNameController,
                        onSubmitted: (_) {
                          FocusScope.of(context).requestFocus(
                                serverNameFocusNode,
                              );
                        },
                      ),
                      new hacks.RawKeyboardTextField(
                        decoration: new InputDecoration(
                          hintText: 'firebase_id',
                        ),
                        focusNode: serverNameFocusNode,
                        controller: serverNameController,
                        onSubmitted: (_) => _onSubmit(model),
                      ),
                      new Container(
                        margin: const EdgeInsets.symmetric(vertical: 16.0),
                        child: new RaisedButton(
                          color: Colors.blue[500],
                          onPressed: () => _onSubmit(model),
                          child: new Container(
                            width: _kButtonContentWidth - 32.0,
                            height: _kButtonContentHeight,
                            child: new Center(
                              child: new Text(
                                'Create and Log in',
                                style: new TextStyle(color: Colors.white),
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
      ),
    ]);
  }

  void _onSubmit(UserPickerDeviceShellModel model) {
    userNameFocusNode.unfocus();
    serverNameFocusNode.unfocus();
    if (userNameController.text?.isEmpty ?? true) {
      print('Not creating user: User name needs to be set!');
      return;
    }
    if (serverNameController.text?.isEmpty ?? true) {
      print('Not creating user: Server name needs to be set!');
      return;
    }

    _createAndLoginUser(
      userNameController.text,
      serverNameController.text,
      model,
    );
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
                  color: Colors.white,
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
                  color: Colors.black.withAlpha(240),
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
    List<Widget> children = <Widget>[];
    // Default entry.
    children.add(
      _buildUserEntry(
        user: _kDefaultUserName,
        onTap: () => _loginUser(null, model),
      ),
    );
    children.addAll(
      model.accounts.map(
        (Account account) => _buildUserEntry(
              user: account.displayName,
              onTap: () => _loginUser(account.id, model),
            ),
      ),
    );

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
        if (model.accounts != null) {
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
    String serverName,
    UserPickerDeviceShellModel model,
  ) {
    Iterable<Account> matchingAccounts = model.accounts.where(
      (Account account) => account.displayName == user,
    );
    // Add the user if it doesn't already exist.
    if (!(model.accounts?.contains(user) ?? false)) {
      print('UserPicker: Creating user $user with server $serverName!');
      model.userProvider?.addUser(
        IdentityProvider.google,
        user,
        _kDefaultDeviceName,
        serverName,
        (Account account, String errorCode) {
          if (errorCode == null) {
            _loginUser(account.id, model);
          } else {
            print('ERROR adding user!  $errorCode');
          }
        },
      );
    } else {
      if (matchingAccounts.length > 1) {
        print('WARNING multiple accounts with name $user!');
      }
      _loginUser(matchingAccounts.first.id, model);
      model.hideNewUserForm();
    }
  }

  void _loginUser(String accountId, UserPickerDeviceShellModel model) {
    print('UserPicker: Logging in as $accountId!');
    onLoginRequest?.call(accountId, model.userProvider);
  }
}
