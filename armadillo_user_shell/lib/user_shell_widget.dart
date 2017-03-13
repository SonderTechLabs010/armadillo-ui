// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:application.lib.app.dart/app.dart';
import 'package:apps.modular.services.user/user_shell.fidl.dart';
import 'package:flutter/widgets.dart';
import 'package:lib.fidl.dart/bindings.dart';

import 'user_shell_impl.dart';

/// A wrapper widget intended to be the root of the application that is
/// a [UserShell].  Its main purpose is to hold the [applicationContext] and
/// [userShell] instances so they aren't garbage collected.
/// For convienence, [advertise] does the advertising of the app as a
/// [UserShell] to the rest of the system via the [applicationContext].
class UserShellWidget extends StatelessWidget {
  final ApplicationContext applicationContext;
  final UserShellImpl userShell;
  final Widget child;

  UserShellWidget({this.applicationContext, this.userShell, this.child});

  @override
  Widget build(BuildContext context) => child;

  /// Advertises [userShell] as a [UserShell] to the rest of the system via the
  /// [applicationContext].
  void advertise() => applicationContext.outgoingServices.addServiceForName(
        (InterfaceRequest<UserShell> request) => userShell.bind(request),
        UserShell.serviceName,
      );
}
