// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import '../lib/constraints_manager.dart';

void main() {
  test('Before loading we have one unconstrained constraint.', () {
    ConstraintsManager constraintsManager = new ConstraintsManager();
    expect(constraintsManager.constraints.length, 1);
    expect(constraintsManager.constraints[0], const BoxConstraints());
  });

  test('Reading bad json results in unconstrained constraints.', () {
    ConstraintsManager constraintsManager = new ConstraintsManager();
    bool caughtError = false;
    try {
      constraintsManager.parseJson('foo');
    } catch (exception) {
      caughtError = true;
    }
    expect(caughtError, true);
    expect(constraintsManager.constraints.length, 1);
    expect(constraintsManager.constraints[0], const BoxConstraints());
  });

  test('Reading valid json results in proper constraints.', () {
    ConstraintsManager constraintsManager = new ConstraintsManager();
    constraintsManager.parseJson(
        '{ "screen_sizes": [ { "width": "360.0", "height": "640.0" }, { "width": "1280.0", "height": "800.0" } ] }');
    expect(constraintsManager.constraints.length, 3);
    expect(constraintsManager.constraints[0], const BoxConstraints());
    expect(constraintsManager.constraints[1],
        const BoxConstraints.tightFor(width: 360.0, height: 640.0));
    expect(constraintsManager.constraints[2],
        const BoxConstraints.tightFor(width: 1280.0, height: 800.0));
  });

  test('Reading valid json with empty list results in proper constraints.', () {
    ConstraintsManager constraintsManager = new ConstraintsManager();
    constraintsManager.parseJson('{ "screen_sizes": [ ] }');
    expect(constraintsManager.constraints.length, 1);
    expect(constraintsManager.constraints[0], const BoxConstraints());
  });
}
