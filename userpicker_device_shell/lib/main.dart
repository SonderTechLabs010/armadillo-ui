// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.device/user_provider.fidl.dart';
import 'package:apps.mozart.lib.flutter/child_view.dart';
import 'package:apps.mozart.services.views/view_token.fidl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';
import 'package:lib.widgets/model.dart';
import 'package:lib.widgets/modular.dart';

import 'authentication_context_impl.dart';
import 'child_constraints_changer.dart';
import 'constraints_model.dart';
import 'user_picker.dart';
import 'user_picker_device_shell_model.dart';
import 'user_picker_screen.dart';
import 'user_watcher_impl.dart';

void main() {
  GlobalKey screenManagerKey = new GlobalKey();
  ConstraintsModel constraintsModel = new ConstraintsModel();

  UserPickerDeviceShellModel model = new UserPickerDeviceShellModel();
  _AuthenticationOverlayModel authenticationOverlayModel =
      new _AuthenticationOverlayModel();
  AuthenticationContextImpl authenticationContext =
      new AuthenticationContextImpl(
    onStartOverlay: authenticationOverlayModel.onStartOverlay,
    onStopOverlay: authenticationOverlayModel.onStopOverlay,
  );

  DeviceShellWidget<UserPickerDeviceShellModel> deviceShellWidget =
      new DeviceShellWidget<UserPickerDeviceShellModel>(
    deviceShellModel: model,
    authenticationContext: authenticationContext,
    child: new ChildConstraintsChanger(
      constraintsModel: constraintsModel,
      child: new Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          new _ScreenManager(
            key: screenManagerKey,
            onLogout: model.refreshUsers,
          ),
          new ScopedModel<_AuthenticationOverlayModel>(
            model: authenticationOverlayModel,
            child: new _AuthenticationOverlay(),
          ),
        ],
      ),
    ),
  );

  runApp(
    new MediaQuery(
      data: const MediaQueryData(),
      child: deviceShellWidget,
    ),
  );

  constraintsModel.load(rootBundle);
  deviceShellWidget.advertise();
}

class _ScreenManager extends StatefulWidget {
  final VoidCallback onLogout;

  _ScreenManager({Key key, this.onLogout}) : super(key: key);

  @override
  _ScreenManagerState createState() => new _ScreenManagerState();
}

class _ScreenManagerState extends State<_ScreenManager>
    with TickerProviderStateMixin {
  final TextEditingController _userNameController = new TextEditingController();
  final TextEditingController _deviceNameController =
      new TextEditingController();
  final TextEditingController _serverNameController =
      new TextEditingController();

  UserControllerProxy _userControllerProxy;
  UserWatcherImpl _userWatcherImpl;

  ChildViewConnection _childViewConnection;

  AnimationController _transitionAnimation;
  CurvedAnimation _curvedTransitionAnimation;

  @override
  void initState() {
    super.initState();
    _transitionAnimation = new AnimationController(
      value: 0.0,
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _curvedTransitionAnimation = new CurvedAnimation(
      parent: _transitionAnimation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    super.dispose();
    _userWatcherImpl?.close();
    _userWatcherImpl = null;
    _userControllerProxy?.ctrl?.close();
    _userControllerProxy = null;
  }

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
        animation: _transitionAnimation,
        builder: (BuildContext context, Widget child) =>
            _childViewConnection == null
                ? child
                : new Stack(
                    fit: StackFit.passthrough,
                    children: <Widget>[
                      new ChildView(connection: _childViewConnection),
                      new Opacity(
                        opacity: 1.0 - _curvedTransitionAnimation.value,
                        child: child,
                      ),
                    ],
                  ),
        child: new UserPickerScreen(
          userPicker: new UserPicker(
            onLoginRequest: _login,
            userNameController: _userNameController,
            deviceNameController: _deviceNameController,
            serverNameController: _serverNameController,
          ),
        ),
      );

  void _login(String user, UserProvider userProvider) {
    _userControllerProxy?.ctrl?.close();
    _userControllerProxy = new UserControllerProxy();
    _userWatcherImpl?.close();
    _userWatcherImpl = new UserWatcherImpl(onUserLogout: () {
      print('UserPickerDeviceShell: User logged out!');
      setState(() {
        widget.onLogout?.call();
        _transitionAnimation.reverse();
        // TODO(apwilson): Should not need to remove the child view connection but
        // it causes a mozart deadlock in the compositor if you don't.
        _childViewConnection = null;
      });
    });

    final InterfacePair<ViewOwner> viewOwner = new InterfacePair<ViewOwner>();
    userProvider?.login(
      user,
      null,
      null,
      viewOwner.passRequest(),
      _userControllerProxy.ctrl.request(),
    );
    _userControllerProxy.watch(_userWatcherImpl.getHandle());

    setState(() {
      _childViewConnection = new ChildViewConnection(
        viewOwner.passHandle(),
        onAvailable: (ChildViewConnection connection) {
          print('UserPickerDeviceShell: Child view connection available!');
          _transitionAnimation.forward();
        },
        onUnavailable: (ChildViewConnection connection) {
          print('UserPickerDeviceShell: Child view connection unavailable!');
          widget.onLogout?.call();
          _transitionAnimation.reverse();
          // TODO(apwilson): Should not need to remove the child view
          // connection but it causes a mozart deadlock in the compositor if you
          // don't.
          _childViewConnection = null;
        },
      );
    });
  }
}

class _AuthenticationOverlayModel extends Model implements TickerProvider {
  ChildViewConnection _childViewConnection;

  /// If not null, returns the handle of the current requested overlay.
  ChildViewConnection get childViewConnection => _childViewConnection;

  AnimationController _transitionAnimation;
  CurvedAnimation _curvedTransitionAnimation;

  CurvedAnimation get animation => _curvedTransitionAnimation;

  /// Starts showing an overlay over all other content.
  void onStartOverlay(InterfaceHandle<ViewOwner> overlay) {
    _transitionAnimation = new AnimationController(
      value: 0.0,
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _curvedTransitionAnimation = new CurvedAnimation(
      parent: _transitionAnimation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _childViewConnection = new ChildViewConnection(
      overlay,
      onAvailable: (ChildViewConnection connection) {
        print('AuthenticationOverlayModel: Child view connection available!');
        _transitionAnimation.forward();
      },
      onUnavailable: (ChildViewConnection connection) {
        print('AuthenticationOverlayModel: Child view connection unavailable!');
        _transitionAnimation.reverse();
        // TODO(apwilson): Should not need to remove the child view
        // connection but it causes a mozart deadlock in the compositor if you
        // don't.
        _childViewConnection = null;
      },
    );
    notifyListeners();
  }

  /// Stops showing a previously started overlay.
  void onStopOverlay() {
    _transitionAnimation.reverse();
    // TODO(apwilson): Should not need to remove the child view
    // connection but it causes a mozart deadlock in the compositor if you
    // don't.
    _childViewConnection = null;
    notifyListeners();
  }

  @override
  Ticker createTicker(TickerCallback onTick) => new Ticker(onTick);
}

class _AuthenticationOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      new ScopedModelDescendant<_AuthenticationOverlayModel>(
        builder: (
          BuildContext context,
          Widget child,
          _AuthenticationOverlayModel model,
        ) =>
            model.animation == null
                ? new Offstage()
                : new AnimatedBuilder(
                    animation: model.animation,
                    builder: (BuildContext context, Widget child) =>
                        new Opacity(
                          opacity: model.animation.value,
                          child: child,
                        ),
                    child: new FractionallySizedBox(
                      widthFactor: 0.75,
                      heightFactor: 0.75,
                      child: new ChildView(
                        connection: model.childViewConnection,
                      ),
                    ),
                  ),
      );
}
