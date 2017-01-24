// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'constraints_manager.dart';

/// Bezel constants.  Used to give the illusion of a device.
const double _kBezelMinimumWidth = 8.0;
const double _kBezelExtension = 16.0;
const double _kOuterBezelRadius = 16.0;

/// A widget that changes [child]'s constraints to one within [constraints]. An
/// affordance to perform this change is placed in [ChildConstraintsChanger]'s
/// top right.  Each tap of the affordance steps through the [constraints] list
/// applying each constraint to [child] in turn.
class ChildConstraintsChanger extends StatefulWidget {
  final ConstraintsModel constraintsModel;
  final Widget child;
  ChildConstraintsChanger({this.constraintsModel, this.child});

  @override
  ChildConstraintsChangerState createState() =>
      new ChildConstraintsChangerState();
}

class ChildConstraintsChangerState extends State<ChildConstraintsChanger> {
  List<BoxConstraints> _constraints;
  int _currentConstraintIndex = 0;

  @override
  void initState() {
    super.initState();
    _constraints = config.constraintsModel.constraints;
    config.constraintsModel.addListener(_onChange);
  }

  @override
  void dispose() {
    config.constraintsModel.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => (_constraints?.isEmpty ?? true) ||
          (_constraints.length == 1 &&
              _constraints[0] == const BoxConstraints())
      ? config.child
      : new Stack(
          children: [
            _constrainedChild,
            _constraintSwitchingButton,
          ],
        );

  Widget get _constrainedChild => _currentConstraint == const BoxConstraints()
      ? config.child
      : new Container(
          decoration: new BoxDecoration(backgroundColor: new Color(0xFF404040)),
          child: new Center(
            child: new Container(
              padding: new EdgeInsets.only(
                  bottom:
                      _currentConstraint.maxHeight > _currentConstraint.maxWidth
                          ? _kBezelExtension
                          : 0.0,
                  right:
                      _currentConstraint.maxHeight > _currentConstraint.maxWidth
                          ? 0.0
                          : _kBezelExtension),
              decoration: new BoxDecoration(
                  backgroundColor: Colors.black,
                  border: new Border.all(
                      color: Colors.black, width: _kBezelMinimumWidth),
                  borderRadius: new BorderRadius.circular(_kOuterBezelRadius),
                  boxShadow: kElevationToShadow[12]),
              child: new ConstrainedBox(
                constraints: _currentConstraint,
                child: new ClipRect(
                  child: config.child,
                ),
              ),
            ),
          ),
        );

  Widget get _constraintSwitchingButton => new Positioned(
        right: 0.0,
        top: 0.0,
        width: 50.0,
        height: 50.0,
        child: new GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _switchConstraints,
        ),
      );

  BoxConstraints get _currentConstraint {
    if (_constraints == null || _constraints.isEmpty) {
      return new BoxConstraints();
    }
    return _constraints[_currentConstraintIndex % _constraints.length];
  }

  void _switchConstraints() => setState(() {
        _currentConstraintIndex++;
      });

  void _onChange() {
    setState(() {
      _constraints = config.constraintsModel.constraints;
    });
  }
}
