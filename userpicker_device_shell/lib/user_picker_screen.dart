// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:apps.modular.services.auth.account/account.fidl.dart';
import 'package:flutter/material.dart';

import 'user_picker_buttons.dart';
import 'user_picker.dart';

/// Called when the user is removing [account].
typedef void OnRemoveUser(Account account);

/// Displays a [UserPicker] a shutdown button, a new user button, the
/// fuchsia logo, and a background image.
class UserPickerScreen extends StatelessWidget {
  /// The widget that allows a user to be picked.
  final UserPicker userPicker;

  /// Called when the add user button is pressed.
  final VoidCallback onAddUser;

  /// Called when the user is removing an account.
  final OnRemoveUser onRemoveUser;

  /// Indicates the remove user indicator should be shown.
  final bool showBlackHole;

  /// Constructor.
  UserPickerScreen({
    this.userPicker,
    this.onAddUser,
    this.onRemoveUser,
    this.showBlackHole,
  });

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

              // Add black hole for removing users.
              new Align(
                alignment: FractionalOffset.bottomCenter,
                child: new Container(
                  margin: const EdgeInsets.only(bottom: 56.0),
                  child: new DragTarget<Account>(
                    onWillAccept: (Account data) => true,
                    onAccept: (Account data) => onRemoveUser?.call(data),
                    builder: (
                      _,
                      List<Account> candidateData,
                      __,
                    ) =>
                        new _BlackHole(
                          show: showBlackHole,
                          grow: candidateData.isNotEmpty,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Displays a spinning black hole.
class _BlackHole extends StatefulWidget {
  /// Grows the black hole by some percentage.
  final bool grow;

  /// Shows the black hole.
  final bool show;

  /// Constructor.
  _BlackHole({this.show, this.grow});

  @override
  _BlackHoleState createState() => new _BlackHoleState();
}

class _BlackHoleState extends State<_BlackHole> with TickerProviderStateMixin {
  AnimationController _rotationController;
  AnimationController _initialScaleController;
  CurvedAnimation _initialScaleCurvedAnimation;
  AnimationController _scaleController;
  CurvedAnimation _scaleCurvedAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = new AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _initialScaleController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initialScaleController.addStatusListener((AnimationStatus status) {
      if (!widget.show && _initialScaleController.isDismissed) {
        _rotationController.stop();
      }
    });
    _initialScaleCurvedAnimation = new CurvedAnimation(
      parent: _initialScaleController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _scaleController = new AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleCurvedAnimation = new CurvedAnimation(
      parent: _scaleController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );

    if (widget.show) {
      _rotationController.repeat();
      _initialScaleController.forward();
      if (widget.grow) {
        _scaleController.forward();
      }
    }
  }

  @override
  void didUpdateWidget(_) {
    super.didUpdateWidget(_);
    if (widget.grow) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
    }
    if (widget.show) {
      _rotationController.repeat();
      _initialScaleController.forward();
    } else {
      _initialScaleController.reverse();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    _initialScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => new AnimatedBuilder(
        animation: _rotationController,
        builder: (BuildContext context, Widget child) => new Transform(
              alignment: FractionalOffset.center,
              transform: new Matrix4.rotationZ(
                2.0 * math.PI * _rotationController.value,
              )
                  .scaled(
                lerpDouble(1.0, 1.75, _scaleCurvedAnimation.value) *
                    _initialScaleCurvedAnimation.value,
                lerpDouble(1.0, 1.75, _scaleCurvedAnimation.value) *
                    _initialScaleCurvedAnimation.value,
              ),
              child: child,
            ),
        child: new Image.asset(
          'packages/userpicker_device_shell/res/BlackHole.png',
          fit: BoxFit.cover,
          width: 200.0,
          height: 200.0,
        ),
      );
}
