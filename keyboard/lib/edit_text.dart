// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/scrollable_input_text.dart';

const Color kTurquoiseAccentColor = const Color(0xFF68EFAD);

class InputText extends StatelessWidget {
  static const double _kInputTextHorizontalPadding = 40.0;
  static const double _kInputTextVerticalPadding = 12.0;
  static const double _kInputTextHeight = 100.0;

  final ScrollableInputText _scrollableInputText;

  InputText({Key editTextKey})
      : _scrollableInputText = new ScrollableInputText(
            key: editTextKey, alignment: const FractionalOffset(0.5, 0.5));

  @override
  Widget build(BuildContext context) => new Container(
      height: _kInputTextHeight,
      padding: new EdgeInsets.symmetric(
          vertical: _kInputTextVerticalPadding,
          horizontal: _kInputTextHorizontalPadding),
      child: new Center(child: _scrollableInputText));
}
