// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/quadrilateral_painter.dart';
import 'package:sysui_widgets/raw_keyboard_input.dart';

import 'suggestion_manager.dart';

const String _kMicImageGrey600 =
    'packages/armadillo/res/ic_mic_grey600_1x_web_24dp.png';

class SuggestionList extends StatefulWidget {
  final Key scrollableKey;
  final VoidCallback onAskingStarted;
  final VoidCallback onAskingEnded;

  SuggestionList({
    Key key,
    this.scrollableKey,
    this.onAskingStarted,
    this.onAskingEnded,
  })
      : super(key: key);

  @override
  SuggestionListState createState() => new SuggestionListState();
}

class SuggestionListState extends State<SuggestionList> {
  final GlobalKey<RawKeyboardInputState> _inputKey =
      new GlobalKey<RawKeyboardInputState>();
  bool _asking = false;

  String get text => _inputKey.currentState?.text;
  void append(String text) {
    _inputKey.currentState?.append(text);
    InheritedSuggestionManager.of(context).askText = this.text;
  }

  bool backspace() {
    bool result = _inputKey.currentState?.backspace();
    InheritedSuggestionManager.of(context).askText = text;
    return result;
  }

  void clear() {
    _inputKey.currentState?.clear();
    InheritedSuggestionManager.of(context).askText = null;
  }

  @override
  Widget build(BuildContext context) => new Stack(
        children: [
          // Ask Anything text field.
          new Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            height: 84.0,
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                new Flexible(
                  flex: 3,
                  child: new GestureDetector(
                    onTap: () {
                      setState(() {
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
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: new Align(
                      alignment: FractionalOffset.centerLeft,
                      child: new Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: new RawKeyboardInput(
                          key: _inputKey,
                          focused: _asking,
                          onTextChanged: (String text) {
                            InheritedSuggestionManager.of(context).askText =
                                text;
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Microphone.
                new Flexible(
                  flex: 1,
                  child: new GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      print('Start asking!');
                    },
                    child: new Align(
                      alignment: FractionalOffset.centerRight,
                      child: new Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: new Image.asset(
                          _kMicImageGrey600,
                          fit: ImageFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          new Positioned(
            top: 84.0,
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: new Block(
              scrollableKey: config.scrollableKey,
              children: InheritedSuggestionManager.of(context).suggestions.map(
                (Suggestion suggestion) {
                  int color = suggestion.themeColor.value;
                  return new Container(
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
                        child: new Text(
                          suggestion.title,
                          style: new TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),
          ),
        ],
      );
}
