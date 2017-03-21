// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'key_mappings.dart';
import 'scrollable_input_text.dart';

typedef void OnTextChanged(String text);
typedef void OnTextCommitted(String text);

/// Listens for raw key input and shows typed characters in a [Text].
/// Keys will only be listened to if [focused] is true.
/// We use this instead of [EditableText] as we don't want to trigger the
/// platform's soft keyboard (if it has one).  We hook up our own soft keyboard
/// for now that calls: [RawKeyboardInputState.clear],
/// [RawKeyboardInputState.append], and [RawKeyboardInputState.backspace] to set
/// the [Text] in the case no hard keyboard exists (which would render our
/// [RawKeyboardListener] child useless).
/// TODO(apwilson): Handle non-Latin-1 characters.
class RawKeyboardInput extends StatefulWidget {
  /// Keys will only be listened to if [focused] is true.
  final bool focused;

  /// Called when the text changes.
  final OnTextChanged onTextChanged;

  /// Called when the user indicates the text should be committed.
  final OnTextCommitted onTextCommitted;

  /// Constructor.
  RawKeyboardInput({
    Key key,
    this.focused,
    this.onTextChanged,
    this.onTextCommitted,
  })
      : super(key: key);

  @override
  RawKeyboardInputState createState() => new RawKeyboardInputState();
}

class RawKeyboardInputState extends State<RawKeyboardInput> {
  final GlobalKey<ScrollableInputTextState> _scrollableInputTextKey =
      new GlobalKey<ScrollableInputTextState>();

  @override
  Widget build(BuildContext context) => new RawKeyboardListener(
        onKey: _handleKey,
        focused: config.focused,
        child: new ScrollableInputText(
          key: _scrollableInputTextKey,
          focused: config.focused,
        ),
      );

  ScrollableInputTextState get _textState =>
      _scrollableInputTextKey.currentState;

  /// See [ScrollableInputTextState.clear].
  void clear() {
    String text = _textState?.text;
    if (text.isNotEmpty) {
      _textState?.clear();
      _notifyTextChanged();
    }
  }

  /// See [ScrollableInputTextState.text].
  String get text => _textState?.text;

  /// See [ScrollableInputTextState.append].
  void append(String text) => _textState?.append(text);

  /// See [ScrollableInputTextState.backspace].
  bool backspace() => _textState?.backspace();

  void _handleKey(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.data is RawKeyEventDataAndroid) {
        RawKeyEventDataAndroid data = event.data;
        if (data.keyCode == keyCodeEnter) {
          String text = _textState?.text;
          if (config.onTextCommitted != null && text.isNotEmpty) {
            config.onTextCommitted(text);
          }
        } else if (data.keyCode == keyCodeBackspace) {
          if (_textState?.backspace() ?? false) {
            _notifyTextChanged();
          }
        } else {
          if (data.metaState == metaStateNormal) {
            if (keyCodeMap.containsKey(data.keyCode)) {
              _textState?.append(keyCodeMap[data.keyCode]);
              _notifyTextChanged();
            }
          } else if (data.metaState == metaStateLeftShiftDown ||
              data.metaState == metaStateRightShiftDown) {
            if (shiftedKeyCodeMap.containsKey(data.keyCode)) {
              _textState?.append(shiftedKeyCodeMap[data.keyCode]);
              _notifyTextChanged();
            }
          }
        }
      } else if (event.data is RawKeyEventDataFuchsia) {
        RawKeyEventDataFuchsia data = event.data;
        if (data.codePoint != 0) {
          _textState?.append(new String.fromCharCode(data.codePoint));
          _notifyTextChanged();
        } else if (data.hidUsage == 40) {
          String text = _textState?.text;
          if (config.onTextCommitted != null && text.isNotEmpty) {
            config.onTextCommitted(text);
          }
        } else if (data.hidUsage == 42) {
          if (_textState?.backspace() ?? false) {
            _notifyTextChanged();
          }
        }
      }
    }
  }

  void _notifyTextChanged() {
    if (config.onTextChanged != null) {
      config.onTextChanged(_textState?.text);
    }
  }
}
