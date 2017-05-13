// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:test/test.dart';
import 'package:userpicker_device_shell/constraints_model.dart';

void main() {
  test('Before loading we have one unconstrained constraint.', () {
    ConstraintsModel constraintsModel = new ConstraintsModel();
    expect(constraintsModel.constraints.length, 1);
    expect(constraintsModel.constraints[0], const BoxConstraints()); // ignore: argument_type_not_assignable
  });

  test('Reading bad json results in unconstrained constraints.', () {
    ConstraintsModel constraintsModel = new ConstraintsModel();
    bool caughtError = false;
    try {
      constraintsModel.parseJson('foo');
    } catch (exception) {
      caughtError = true;
    }
    expect(caughtError, true);
    expect(constraintsModel.constraints.length, 1);
    expect(constraintsModel.constraints[0], const BoxConstraints()); // ignore: argument_type_not_assignable
  });

  test('Reading valid json results in proper constraints.', () {
    ConstraintsModel constraintsModel = new ConstraintsModel();
    constraintsModel.parseJson(
        '{ "screen_sizes": [ { "width": "360.0", "height": "640.0" }, { "width": "1280.0", "height": "800.0" } ] }');
    expect(constraintsModel.constraints.length, 3);
    expect(constraintsModel.constraints[0], const BoxConstraints()); // ignore: argument_type_not_assignable
    expect(constraintsModel.constraints[1],
        const BoxConstraints.tightFor(width: 360.0, height: 640.0)); // ignore: argument_type_not_assignable
    expect(constraintsModel.constraints[2],
        const BoxConstraints.tightFor(width: 1280.0, height: 800.0)); // ignore: argument_type_not_assignable
  });

  test('Reading valid json with empty list results in proper constraints.', () {
    ConstraintsModel constraintsModel = new ConstraintsModel();
    constraintsModel.parseJson('{ "screen_sizes": [ ] }');
    expect(constraintsModel.constraints.length, 1);
    expect(constraintsModel.constraints[0], const BoxConstraints()); // ignore: argument_type_not_assignable
  });
}

class BoxConstraints {
}

void expect(length, int i) {
}

class ConstraintsModel {
  get constraints => null;

  void parseJson(String s) {}
}

void test(String s, Function arg1) {
}
