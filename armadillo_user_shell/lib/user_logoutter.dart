// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modular.services.user/user_context.fidl.dart';

/// Performs the logging out of the user.
class UserLogoutter {
  UserContext _userContext;

  /// Set from an external source - typically the UserShell.
  set userContext(UserContext userContext) {
    _userContext = userContext;
  }

  /// Logs out the user.
  void logout() {
    _userContext?.logout();
  }
}
