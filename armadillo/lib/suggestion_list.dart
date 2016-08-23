// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/quadrilateral_painter.dart';

/// Colors for dummy suggestions.
const _kDummySuggestionColors = const <int>[
  0xFFFF5722,
  0xFFFF9800,
  0xFFFFC107,
  0xFFFFEB3B,
  0xFFCDDC39,
  0xFF8BC34A,
  0xFF4CAF50,
  0xFF009688,
  0xFF00BCD4,
  0xFF03A9F4,
  0xFF2196F3,
  0xFF3F51B5,
  0xFF673AB7,
  0xFF9C27B0,
  0xFFE91E63,
  0xFFF44336
];

const String _kMicImageGrey600 =
    'packages/armadillo/res/ic_mic_grey600_1x_web_24dp.png';

class SuggestionList extends StatefulWidget {
  final VoidCallback onAskingStarted;
  final VoidCallback onAskingEnded;

  SuggestionList({this.onAskingStarted, this.onAskingEnded});

  @override
  SuggestionListState createState() => new SuggestionListState();
}

class SuggestionListState extends State<SuggestionList> {
  bool _asking = false;
  @override
  Widget build(BuildContext context) => new Stack(children: [
        new Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            height: 84.0,
            child: new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  new Flexible(
                      flex: 3,
                      child: new GestureDetector(
                          onTap: () {
                            _asking = !_asking;
                            if (_asking) {
                              if (config.onAskingStarted != null) {
                                config.onAskingStarted();
                              }
                            } else {
                              if (config.onAskingEnded != null) {
                                config.onAskingEnded();
                              }
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: new Align(
                              alignment: FractionalOffset.topLeft,
                              child: new Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, top: 36.0),
                                  child: new Text('ASK ANYTHING',
                                      style: new TextStyle(
                                          color: Colors.grey[600])))))),
                  new Flexible(
                      flex: 1,
                      child: new GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            print('tap!');
                          },
                          child: new Align(
                              alignment: FractionalOffset.topRight,
                              child: new Padding(
                                  padding: const EdgeInsets.only(
                                      right: 10.0, top: 28.0),
                                  child: new Image.asset(_kMicImageGrey600,
                                      fit: ImageFit.cover)))))
                ])),
        new Positioned(
            top: 84.0,
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: new Block(
              children: _kDummySuggestionColors.reversed
                  .map(
                    (int color) => new Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          height: 200.0,
                          decoration: new BoxDecoration(
                              backgroundColor: Colors.white,
                              boxShadow: kElevationToShadow[3]),
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
                                  child: new Text('suggestion',
                                      style: new TextStyle(
                                          color: Colors.grey[600])))),
                        ),
                  )
                  .toList(),
            ))
      ]);
}
