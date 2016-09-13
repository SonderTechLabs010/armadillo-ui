// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:sky_services/sky/input_event.mojom.dart' as mojom;

import 'key_mappings.dart';
import 'scrollable_input_text.dart';

typedef void OnTextChanged(String text);
typedef void OnTextCommitted(String text);

/// Listens for raw key input and shows typed characters in a [Text].
/// Keys will only be listened to if [focused] is true.
/// We use this instead of [Input] as we don't want to trigger the platform's
/// soft keyboard (if it has one).  We hook up our own soft keyboard for now
/// that calls: [clear], [append], and [backspace] to set the [Text] in the case
/// no hard keyboard exists (which would render our [RawKeyboardListener]
/// child useless).
/// TODO(apwilson): Handle non-Latin-1 characters.
class RawKeyboardInput extends StatefulWidget {
  final bool focused;
  final OnTextChanged onTextChanged;
  final OnTextCommitted onTextCommitted;

  RawKeyboardInput(
      {Key key, this.focused, this.onTextChanged, this.onTextCommitted})
      : super(key: key);

  @override
  RawKeyboardInputState createState() => new RawKeyboardInputState();
}

class RawKeyboardInputState extends State<RawKeyboardInput> {
  final _scrollableInputTextKey = new GlobalKey<ScrollableInputTextState>();
  @override
  Widget build(BuildContext context) => new RawKeyboardListener(
        onKey: _handleKey,
        focused: config.focused,
        child: new ScrollableInputText(
          key: _scrollableInputTextKey,
          focused: config.focused,
        ),
      );

  ScrollableInputTextState get textState =>
      _scrollableInputTextKey.currentState;

  void clear() {
    String text = textState?.text;
    if (text.isNotEmpty) {
      textState?.clear();
      _notifyTextChanged();
    }
  }

  String get text => textState?.text;
  void append(String text) => textState?.append(text);
  bool backspace() => textState?.backspace();

  void _handleKey(mojom.InputEvent event) {
    if (event.type == mojom.EventType.keyPressed) {
      if (event.keyData.keyCode == keyCodeEnter) {
        String text = textState?.text;
        if (config.onTextCommitted != null && text.isNotEmpty) {
          config.onTextCommitted(text);
        }
        clear();
      } else if (event.keyData.keyCode == keyCodeBackspace) {
        if (textState?.backspace() ?? false) {
          _notifyTextChanged();
        }
      } else {
        if (event.keyData.metaState == metaStateNormal) {
          if (keyCodeMap.containsKey(event.keyData.keyCode)) {
            textState?.append(keyCodeMap[event.keyData.keyCode]);
            _notifyTextChanged();
          }
        } else if (event.keyData.metaState == metaStateLeftShiftDown ||
            event.keyData.metaState == metaStateRightShiftDown) {
          if (shiftedKeyCodeMap.containsKey(event.keyData.keyCode)) {
            textState?.append(shiftedKeyCodeMap[event.keyData.keyCode]);
            _notifyTextChanged();
          }
        }
      }
    }
  }

  void _notifyTextChanged() {
    if (config.onTextChanged != null) {
      config.onTextChanged(textState?.text);
    }
  }
}
