// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'blinking_cursor.dart';

final Color _kTextColor = Colors.grey[600];
final Color _kHintTextColor = Colors.grey[600];
const double _kTextSize = 16.0;

/// Handles the display of typed characters in a [Text].
///
/// TODO(apwilson): Handle non-Latin-1 characters.
class ScrollableInputText extends StatefulWidget {
  final FractionalOffset alignment;
  final bool focused;
  ScrollableInputText({Key key, this.alignment, this.focused})
      : super(key: key);

  @override
  ScrollableInputTextState createState() => new ScrollableInputTextState();
}

/// State for [ScrollableInputText].
class ScrollableInputTextState extends State<ScrollableInputText> {
  String _text = '';

  @override
  Widget build(BuildContext context) {
    List<Widget> blockChildren = <Widget>[
      new Align(
          alignment: config.alignment ?? const FractionalOffset(0.0, 0.5),
          child: new Text(
              (_text.isEmpty && !config.focused) ? 'Ask for anything' : _text,
              style: new TextStyle(
                  fontSize: _kTextSize,
                  color: _text.isEmpty ? _kHintTextColor : _kTextColor)))
    ];

    if (config.focused) {
      blockChildren.add(new Align(
          alignment: config.alignment ?? const FractionalOffset(0.0, 0.5),
          child: new BlinkingCursor(
              height: _kTextSize,
              color: _kTextColor,
              duration: const Duration(milliseconds: 500))));
    }

    return new Block(
        scrollDirection: Axis.horizontal,
        scrollAnchor: ViewportAnchor.end,
        children: blockChildren);
  }

  /// Returns the current text value of the [ScrollableInputTextState].
  String get text => _text;

  /// Clears the [ScrollableInputTextState]'s text.
  void clear() {
    setState(() {
      _text = '';
    });
  }

  /// Appends the give [text] to the [ScrollableInputTextState]'s text.
  void append(String text) => setState(() {
        _text += text;
      });

  /// Deletes the last character off the [ScrollableInputTextState]'s text.
  /// Returns true if this changed [ScrollableInputTextState]'s text; returns
  /// false otherwise.
  bool backspace() {
    bool returnValue = _text.isNotEmpty;
    if (_text.isNotEmpty) {
      setState(() {
        _text = _text.substring(0, _text.length - 1);
      });
    }
    return returnValue;
  }
}
