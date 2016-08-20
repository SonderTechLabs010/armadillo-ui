// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A widget that changes [child]'s constraints to one within [constraints]. An
/// affordance to perform this change is placed in [ChildConstraintsChanger]'s
/// top right.  Each tap of the affordance steps through the [constraints] list
/// applying each constraint to [child] in turn.
class ChildConstraintsChanger extends StatefulWidget {
  final List<BoxConstraints> constraints;
  final Widget child;
  ChildConstraintsChanger({this.constraints, this.child});

  @override
  ChildConstraintsChangerState createState() =>
      new ChildConstraintsChangerState();
}

class ChildConstraintsChangerState extends State<ChildConstraintsChanger> {
  int _currentConstraintIndex = 0;
  @override
  Widget build(BuildContext context) => new Stack(children: [
        new Container(
            decoration:
                new BoxDecoration(backgroundColor: new Color(0xFF404040)),
            child: new Center(child: new Container(
                decoration: new BoxDecoration(
                    backgroundColor: Colors.black,
                    boxShadow: kElevationToShadow[12]),
                child: new ConstrainedBox(
                    constraints: _currentConstraint, child: config.child)))),
        new Positioned(
            right: 0.0,
            top: 0.0,
            width: 50.0,
            height: 50.0,
            child: new GestureDetector(
                onTap: _switchConstraints,
                child: new Container(
                    decoration: new BoxDecoration(
                        backgroundColor: new Color(0x80FF0080)),
                    child: new Center(child: new Text('~')))))
      ]);

  BoxConstraints get _currentConstraint {
    if (config.constraints == null || config.constraints.isEmpty) {
      return new BoxConstraints();
    }
    return config.constraints[
        _currentConstraintIndex % config.constraints.length];
  }

  void _switchConstraints() => setState(() {
        _currentConstraintIndex++;
      });
}
