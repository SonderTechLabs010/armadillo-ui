// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/quadrilateral_painter.dart';

import 'suggestion_manager.dart';

const String _kMicImageGrey600 =
    'packages/armadillo/res/ic_mic_grey600_1x_web_24dp.png';

class SuggestionWidget extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onSelected;
  final bool visible;

  SuggestionWidget(
      {Key key, this.suggestion, this.onSelected, this.visible: false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    int color = suggestion.themeColor.value;
    return new Container(
      height: 200.0,
      decoration: visible
          ? null
          : new BoxDecoration(
              backgroundColor: Colors.white, boxShadow: kElevationToShadow[3]),
      child: visible
          ? null
          : new GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelected,
              child: new CustomPaint(
                painter: new QuadrilateralPainter(
                  // 'Randomize' insets a bit.
                  topLeftInset: new Offset(
                      325.0 +
                          ((color % 2 == 0)
                              ? 15.0 + (color % 26).toDouble()
                              : 0.0),
                      0.0),
                  bottomLeftInset: new Offset(
                      325.0 +
                          ((color % 2 == 0)
                              ? 0.0
                              : 15.0 + (color % 26).toDouble()),
                      0.0),
                  color: new Color(color),
                ),
                child: new Center(
                  child: new Text(
                    suggestion.title,
                    style: new TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
            ),
    );
  }
}
