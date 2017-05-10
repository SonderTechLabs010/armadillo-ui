// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'time_stringer.dart';

const TextStyle _kTimeTextStyle = const TextStyle(
  color: Colors.white,
  fontSize: 36.0,
  letterSpacing: 4.0,
  fontWeight: FontWeight.w300,
);

const TextStyle _kDateTextStyle = const TextStyle(
  color: Colors.white,
  fontSize: 12.0,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w300,
);

const TextStyle _kLocationTextStyle = const TextStyle(
  color: Colors.white,
  fontSize: 12.0,
  letterSpacing: 1.0,
  fontWeight: FontWeight.w100,
);

const double _kWidthThreshold = 300.0;
const double _kTimeRightMargin = 8.0;
const double _kYInsetFudgeFactor = 6.0;
const double _kEdgeSpacing = 16.0;
const double _kUserSpacing = 32.0;
const double _kTextVerticalGap = 4.0;

/// Displays the time, date, and location context for the user.
class UserContextText extends StatelessWidget {
  final TimeStringer _timeStringer = new TimeStringer();

  /// The color the text in this widget will have.
  final Color textColor;

  /// The device's current contextual location.
  final String contextualLocation;

  /// Constructor.
  UserContextText({
    Key key,
    this.textColor,
    this.contextualLocation: 'Mountain View',
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
        bool tight = constraints.maxWidth <= _kWidthThreshold;
        List<LayoutId> children = <LayoutId>[
          new LayoutId(
            id: _UserContextLayoutDelegateParts.location,
            child: new Text(
              contextualLocation.toUpperCase(),
              softWrap: false,
              overflow: TextOverflow.fade,
              style: _kLocationTextStyle.copyWith(
                color: textColor,
                fontSize: tight ? 10.0 : 12.0,
              ),
            ),
          ),
        ];
        if (tight) {
          children.add(
            new LayoutId(
              id: _UserContextLayoutDelegateParts.time,
              child: new Text(
                _timeStringer.timeOnly,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: _kDateTextStyle.copyWith(
                  color: textColor,
                  fontSize: 10.0,
                ),
              ),
            ),
          );
        } else {
          children.addAll(<LayoutId>[
            new LayoutId(
              id: _UserContextLayoutDelegateParts.time,
              child: new Text(
                _timeStringer.timeOnly,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: _kTimeTextStyle.copyWith(color: textColor),
              ),
            ),
            new LayoutId(
              id: _UserContextLayoutDelegateParts.date,
              child: new Text(
                _timeStringer.dateOnly,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: _kDateTextStyle.copyWith(color: textColor),
              ),
            ),
          ]);
        }
        return new CustomMultiChildLayout(
          delegate: new _UserContextLayoutDelegate(
            time: _timeStringer.timeOnly,
            date: (constraints.maxWidth > _kWidthThreshold)
                ? _timeStringer.dateOnly
                : null,
            location: contextualLocation.toUpperCase(),
          ),
          children: children,
        );
      });
}

enum _UserContextLayoutDelegateParts {
  time,
  date,
  location,
}

class _UserContextLayoutDelegate extends MultiChildLayoutDelegate {
  final String time;
  final String date;
  final String location;

  _UserContextLayoutDelegate({this.time, this.date, this.location});

  @override
  void performLayout(Size size) {
    // Lay out children.
    if (hasChild(_UserContextLayoutDelegateParts.date)) {
      Size timeSize = layoutChild(
        _UserContextLayoutDelegateParts.time,
        new BoxConstraints.loose(size),
      );
      Size dateSize = layoutChild(
        _UserContextLayoutDelegateParts.date,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: timeSize.width + _kTimeRightMargin + _kUserSpacing,
            top: timeSize.height / 2.0,
          ),
        ),
      );
      Size locationSize = layoutChild(
        _UserContextLayoutDelegateParts.location,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: timeSize.width + _kTimeRightMargin + _kUserSpacing,
            top: timeSize.height / 2.0,
          ),
        ),
      );

      double yInset = (size.height - timeSize.height) / 2.0;
      double timeRight = math.max(dateSize.width, locationSize.width) +
          _kTimeRightMargin +
          _kUserSpacing;

      // Position children.
      positionChild(
        _UserContextLayoutDelegateParts.time,
        new Offset(size.width - timeRight - timeSize.width, yInset),
      );
      positionChild(
        _UserContextLayoutDelegateParts.date,
        new Offset(
          size.width - timeRight + _kTimeRightMargin,
          yInset + _kYInsetFudgeFactor,
        ),
      );
      positionChild(
        _UserContextLayoutDelegateParts.location,
        new Offset(
          size.width - timeRight + _kTimeRightMargin,
          size.height - locationSize.height - yInset - _kYInsetFudgeFactor,
        ),
      );
    } else {
      Size timeSize = layoutChild(
        _UserContextLayoutDelegateParts.time,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: _kEdgeSpacing + _kUserSpacing / 2.0,
            top: size.height / 2.0,
          ),
        ),
      );
      Size locationSize = layoutChild(
        _UserContextLayoutDelegateParts.location,
        new BoxConstraints.loose(size).deflate(
          new EdgeInsets.only(
            left: _kEdgeSpacing + _kUserSpacing / 2.0,
            top: size.height / 2.0,
          ),
        ),
      );
      double yInset = (size.height -
              timeSize.height -
              locationSize.height -
              _kTextVerticalGap) /
          2.0;

      // Position children.
      positionChild(
        _UserContextLayoutDelegateParts.time,
        new Offset(_kEdgeSpacing, yInset),
      );
      positionChild(
        _UserContextLayoutDelegateParts.location,
        new Offset(_kEdgeSpacing, size.height - yInset - locationSize.height),
      );
    }
  }

  @override
  bool shouldRelayout(_UserContextLayoutDelegate oldDelegate) =>
      time != oldDelegate.time ||
      date != oldDelegate.date ||
      location != oldDelegate.location;
}
