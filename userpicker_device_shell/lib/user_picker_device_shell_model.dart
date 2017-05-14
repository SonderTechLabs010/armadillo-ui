// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.auth.account/account.fidl.dart';
import 'package:apps.modular.services.device/device_shell.fidl.dart';
import 'package:apps.modular.services.device/user_provider.fidl.dart';
import 'package:lib.widgets/modular.dart';

export 'package:lib.widgets/model.dart' show ScopedModel, ScopedModelDescendant;

/// Contains all the relevant data for displaying the list of users and for
/// logging in and creating new users.
class UserPickerDeviceShellModel extends DeviceShellModel {
  List<Account> _accounts;

  bool _isShowingNewUserForm = false;

  /// The list of previously logged in accounts.
  List<Account> get accounts => _accounts;

  /// True if the 'new user' form is showing.
  bool get isShowingNewUserForm => _isShowingNewUserForm;

  @override
  void onReady(
    UserProvider userProvider,
    DeviceShellContext deviceShellContext,
  ) {
    super.onReady(userProvider, deviceShellContext); // ignore: undefined_super_method
    _loadUsers();
  }

  /// Refreshes the list of users.
  void refreshUsers() {
    _accounts = null;
    notifyListeners();
    _loadUsers();
  }

  void _loadUsers() {
    //userProvider.previousUsers((List<Account> accounts) {
      print('accounts: $accounts');
      _accounts = new List<Account>.from(accounts);
      notifyListeners();
    });
  }

  /// Shows the 'new user' form.
  void showNewUserForm() {
    if (!_isShowingNewUserForm) {
      _isShowingNewUserForm = true;
      notifyListeners();
    }
  }

  /// Hides the 'new user' form.
  void hideNewUserForm() {
    if (_isShowingNewUserForm) {
      _isShowingNewUserForm = false;
      notifyListeners();
    }
  }

  /// Permanently removes the user.
  void removeUser(Account account) {
    //userProvider.removeUser(account.id);
    _accounts.remove(account);
    notifyListeners();
    _loadUsers();
  }

void _loadUsers() {
}

  void notifyListeners() {}
}

class DeviceShellContext {
}

class UserProvider {
}

class DeviceShellModel {
}

class Account {
  get id => null;
}
