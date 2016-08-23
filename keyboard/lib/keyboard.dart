// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
// TODO(apwilson): Once we have a mojom solution in Fuchsia, reenable.
// import 'package:flutter/services.dart';
// import 'package:mojo_services/prediction/prediction.mojom.dart';

import 'edit_text.dart';
import 'keys.dart';
import 'word_suggestion_service.dart';

const double _kSuggestionRowHeight = 40.0;

enum KeyboardType { lowerCase, upperCase, symbolsOne, symbolsTwo }

typedef void OnDelete();
typedef void OnGo();

const String kKeyType = 'type'; // defaults to kKeyTypeNormal
const String kKeyTypeSuggestion = 'suggestion';
const String kKeyTypeNormal = 'normal';
const String kKeyTypeSpecial = 'special';

const String kKeyVisualType = 'visualtype'; // defaults to kKeyVisualTypeText
const String kKeyVisualTypeText = 'text';
const String kKeyVisualTypeImage = 'image';
const String kKeyVisualTypeActionText = 'actiontext';

const String kKeyAction =
    'action'; // defaults to kKeyActionEmitText, a number indicates an index into the kayboard layouts array.
const String kKeyActionEmitText = 'emittext';
const String kKeyActionDelete = 'delete';
const String kKeyActionSpace = 'space';
const String kKeyActionGo = 'go';

const String kKeyImage = 'image'; // defaults to null
const String kKeyText = 'text'; // defaults to null
const String kKeyWidth = 'width'; // defaults to 1
const String kKeyAlign = 'align'; // defaults to 0.5

const int kKeyboardLayoutIndexLowerCase = 0;
const int kKeyboardLayoutIndexUpperCase = 1;
const int kKeyboardLayoutIndexSymbolsOne = 2;
const int kKeyboardLayoutIndexSymbolsTwo = 3;

const String kKeyboardLayoutsJson = "["
// Lower Case Layout
    "["
    "["
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"call\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"text\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$kKeyText\":\"q\"},"
    "{\"$kKeyText\":\"w\"},"
    "{\"$kKeyText\":\"e\"},"
    "{\"$kKeyText\":\"r\"},"
    "{\"$kKeyText\":\"t\"},"
    "{\"$kKeyText\":\"y\"},"
    "{\"$kKeyText\":\"u\"},"
    "{\"$kKeyText\":\"i\"},"
    "{\"$kKeyText\":\"o\"},"
    "{\"$kKeyText\":\"p\"}"
    "],"
    "["
    "{\"$kKeyText\":\"a\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.66666666\"},"
    "{\"$kKeyText\":\"s\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"d\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"f\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"g\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"h\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"j\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"k\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"l\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$kKeyImage\":\"packages/keyboard/res/ArrowUp.png\", \"$kKeyAction\":\"$kKeyboardLayoutIndexUpperCase\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"3\"},"
    "{\"$kKeyText\":\"z\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"x\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"c\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"v\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"b\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"n\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"m\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$kKeyAction\":\"$kKeyActionDelete\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$kKeyText\":\"?123\", \"$kKeyAction\":\"$kKeyboardLayoutIndexSymbolsOne\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"5\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Space.png\", \"$kKeyAction\":\"$kKeyActionSpace\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"10\"},"
    "{\"$kKeyText\":\".\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"Go\", \"$kKeyAction\":\"$kKeyActionGo\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"}"
    "]"
    "],"
// Upper Case Layout
    "["
    "["
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"call\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"text\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$kKeyText\":\"Q\"},"
    "{\"$kKeyText\":\"W\"},"
    "{\"$kKeyText\":\"E\"},"
    "{\"$kKeyText\":\"R\"},"
    "{\"$kKeyText\":\"T\"},"
    "{\"$kKeyText\":\"Y\"},"
    "{\"$kKeyText\":\"U\"},"
    "{\"$kKeyText\":\"I\"},"
    "{\"$kKeyText\":\"O\"},"
    "{\"$kKeyText\":\"P\"}"
    "],"
    "["
    "{\"$kKeyText\":\"A\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.66666666\"},"
    "{\"$kKeyText\":\"S\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"D\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"F\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"G\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"H\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"J\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"K\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"L\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$kKeyImage\":\"packages/keyboard/res/ArrowDown.png\", \"$kKeyAction\":\"$kKeyboardLayoutIndexLowerCase\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"3\"},"
    "{\"$kKeyText\":\"Z\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"X\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"C\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"V\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"B\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"N\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"M\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$kKeyAction\":\"$kKeyActionDelete\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$kKeyText\":\"?123\", \"$kKeyAction\":\"$kKeyboardLayoutIndexSymbolsOne\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"5\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Space.png\", \"$kKeyAction\":\"$kKeyActionSpace\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"10\"},"
    "{\"$kKeyText\":\".\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"Go\", \"$kKeyAction\":\"$kKeyActionGo\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"}"
    "]"
    "],"
// Symbols One Layout
    "["
    "["
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"call\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"text\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$kKeyText\":\"1\"},"
    "{\"$kKeyText\":\"2\"},"
    "{\"$kKeyText\":\"3\"},"
    "{\"$kKeyText\":\"4\"},"
    "{\"$kKeyText\":\"5\"},"
    "{\"$kKeyText\":\"6\"},"
    "{\"$kKeyText\":\"7\"},"
    "{\"$kKeyText\":\"8\"},"
    "{\"$kKeyText\":\"9\"},"
    "{\"$kKeyText\":\"0\"}"
    "],"
    "["
    "{\"$kKeyText\":\"@\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.66666666\"},"
    "{\"$kKeyText\":\"#\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\$\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"%\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"&\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"-\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"+\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"(\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\")\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$kKeyText\":\"=\\\\<\", \"$kKeyAction\":\"$kKeyboardLayoutIndexSymbolsTwo\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"},"
    "{\"$kKeyText\":\"*\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\\\\\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\'\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\":\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\";\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"!\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"?\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$kKeyAction\":\"$kKeyActionDelete\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$kKeyText\":\"ABC\", \"$kKeyAction\":\"$kKeyboardLayoutIndexLowerCase\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"},"
    "{\"$kKeyText\":\",\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"_\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Space.png\", \"$kKeyAction\":\"$kKeyActionSpace\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"6\"},"
    "{\"$kKeyText\":\"/\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\".\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"Go\", \"$kKeyAction\":\"$kKeyActionGo\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"}"
    "]"
    "],"
// Symbols Two Layout
    "["
    "["
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"call\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"text\"},"
    "{\"$kKeyType\":\"$kKeyTypeSuggestion\", \"$kKeyText\":\"play\"}"
    "],"
    "["
    "{\"$kKeyText\":\"~\"},"
    "{\"$kKeyText\":\"`\"},"
    "{\"$kKeyText\":\"|\"},"
    "{\"$kKeyText\":\"\u{2022}\"},"
    "{\"$kKeyText\":\"\u{221A}\"},"
    "{\"$kKeyText\":\"\u{03C0}\"},"
    "{\"$kKeyText\":\"\u{00F7}\"},"
    "{\"$kKeyText\":\"\u{00D7}\"},"
    "{\"$kKeyText\":\"\u{00B6}\"},"
    "{\"$kKeyText\":\"\u{2206}\"}"
    "],"
    "["
    "{\"$kKeyText\":\"\u{00A3}\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.66666666\"},"
    "{\"$kKeyText\":\"\u{00A2}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\u{20AC}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\u{00A5}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"^\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\u{00B0}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"=\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"{\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"}\", \"$kKeyWidth\":\"3\", \"$kKeyAlign\":\"0.33333333\"}"
    "],"
    "["
    "{\"$kKeyText\":\"?123\", \"$kKeyAction\":\"$kKeyboardLayoutIndexSymbolsOne\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"},"
    "{\"$kKeyText\":\"\\\\\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\u{00A9}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\u{00AE}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\u{2122}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"\u{2105}\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"[\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"]\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Delete.png\", \"$kKeyAction\":\"$kKeyActionDelete\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"3\"}"
    "],"
    "["
    "{\"$kKeyText\":\"ABC\", \"$kKeyAction\":\"$kKeyboardLayoutIndexLowerCase\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"},"
    "{\"$kKeyText\":\",\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"<\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyImage\":\"packages/keyboard/res/Space.png\", \"$kKeyAction\":\"$kKeyActionSpace\", \"$kKeyType\":\"$kKeyTypeSpecial\", \"$kKeyVisualType\":\"$kKeyVisualTypeImage\", \"$kKeyWidth\":\"6\"},"
    "{\"$kKeyText\":\">\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\".\", \"$kKeyWidth\":\"2\"},"
    "{\"$kKeyText\":\"Go\", \"$kKeyAction\":\"$kKeyActionGo\", \"$kKeyVisualType\":\"$kKeyVisualTypeActionText\", \"$kKeyWidth\":\"3\"}"
    "]"
    "]"
    "]";

final List kKeyboardLayouts = JSON.decode(kKeyboardLayoutsJson);

class Keyboard extends StatefulWidget {
  final OnText onText;
  final OnText onSuggestion;
  final OnDelete onDelete;
  final OnGo onGo;

  Keyboard({Key key, this.onText, this.onSuggestion, this.onDelete, this.onGo})
      : super(key: key);

  @override
  KeyboardState createState() => new KeyboardState();
}

class KeyboardState extends State<Keyboard> {
  static const bool _kUsePredictionService = false;
  static const double _kGoKeyTextSize = 16.0;
  static const double _kSuggestionTextSize = 16.0;
  static const TextStyle _kSuggestionTextStyle = const TextStyle(
      color: kTurquoiseAccentColor,
      fontSize: _kSuggestionTextSize,
      letterSpacing: 2.0);

  // TODO(apwilson): Once we have a mojom solution in Fuchsia, reenable.
  // PredictionServiceProxy _prediction;
  final _suggestionKeys = <GlobalKey>[];
  Widget _keyboardWidget;
  List<Widget> _keyboards;

  @override
  void initState() {
    super.initState();
    // TODO(apwilson): Once we have a mojom solution in Fuchsia, reenable.
    /*
    if (_kUsePredictionService) {
      _prediction = shell.connectToApplicationService(
          "mojo:prediction_service", PredictionService.connectToService);
    }
    */
    _keyboards = <Widget>[];
    kKeyboardLayouts.forEach((keyboard) {
      _keyboards.add(new IntrinsicHeight(
          child: new Column(
              children:
                  keyboard.map((jsonRow) => _makeRow(jsonRow)).toList())));
    });
    _keyboardWidget = _keyboards[0];
  }

  @override
  Widget build(BuildContext context) => _keyboardWidget;

  void updateSuggestions(String text) {
    // If we have no text, clear the suggestions.  If the text ends in
    // whitespace also clear the suggestions (as there is no current word to
    // create suggestions from).
    if (text == null || text == '' || text.endsWith(' ')) {
      _clearSuggestions();
      return;
    }

    final stringList = text.split(' ');

    // If we have no words at all, clear the suggestions.
    if (stringList.isEmpty) {
      _clearSuggestions();
      return;
    }

    final currentWord = stringList.removeLast();

    if (_kUsePredictionService) {
      // TODO(apwilson): Once we have a mojom solution in Fuchsia, reenable.
      /*
      PredictionInfo predictionInfo = new PredictionInfo();
      // we are not using bigram atm
      predictionInfo.previousWords = [];
      predictionInfo.currentWord = currentWord;
      _prediction.getPredictionList(predictionInfo, (predictionList) {
        _clearSuggestions();
        if (predictionList == null) {
          return;
        }
        for (int i = 0;
            i < min(_suggestionKeys.length, predictionList.length);
            i++) {
          (_suggestionKeys[i].currentState as TextKeyState)?.text =
              predictionList[i];
        }
      });
      */
    } else {
      final wordSuggestionService = new WordSuggestionService();
      List<String> suggestedWords =
          wordSuggestionService.suggestWords(currentWord);
      _clearSuggestions();
      for (int i = 0;
          i < min(_suggestionKeys.length, suggestedWords.length);
          i++) {
        (_suggestionKeys[i].currentState as TextKeyState)?.text =
            suggestedWords[i];
      }
    }
  }

  void _clearSuggestions() {
    _suggestionKeys.forEach((suggestionKey) {
      (suggestionKey.currentState as TextKeyState)?.text = '';
    });
  }

  Row _makeRow(final List jsonRow) {
    return new Row(
        children: jsonRow.map((jsonKey) => _makeKey(jsonKey)).toList(),
        mainAxisAlignment: MainAxisAlignment.center);
  }

  Widget _makeKey(final Map jsonKey) {
    String visualType = jsonKey[kKeyVisualType] ?? kKeyVisualTypeText;
    String action = jsonKey[kKeyAction] ?? kKeyActionEmitText;
    int width = int.parse(jsonKey[kKeyWidth] ?? '1');

    switch (visualType) {
      case kKeyVisualTypeImage:
        String image = jsonKey[kKeyImage];
        return _createImageKey(image, width, action);
      case kKeyVisualTypeText:
      case kKeyVisualTypeActionText:
      default:
        String type = jsonKey[kKeyType] ?? kKeyTypeNormal;
        String text = jsonKey[kKeyText];
        double align = double.parse(jsonKey[kKeyAlign] ?? '0.5');
        return _createTextKey(text, width, action, align, type, visualType);
    }
  }

  Widget _createTextKey(String text, int width, String action, double align,
      String type, String visualType) {
    TextStyle style = (type == kKeyTypeSuggestion)
        ? _kSuggestionTextStyle
        : (visualType == kKeyVisualTypeActionText)
            ? (type == kKeyTypeSpecial)
                ? TextKey.kDefaultTextStyle.copyWith(
                    fontSize: _kGoKeyTextSize,
                    fontWeight: FontWeight.bold,
                    color: ImageKey.kImageColor)
                : TextKey.kDefaultTextStyle.copyWith(
                    fontSize: _kGoKeyTextSize, fontWeight: FontWeight.bold)
            : TextKey.kDefaultTextStyle;
    bool isSuggestion = type == kKeyTypeSuggestion;
    GlobalKey key = isSuggestion ? new GlobalKey() : null;
    TextKey textKey = new TextKey(isSuggestion ? '' : text,
        key: key,
        flex: width,
        onKeyPressed: _getAction(action),
        onText: isSuggestion ? _onSuggestion : _onText,
        horizontalAlign: align,
        style: style,
        height: isSuggestion ? _kSuggestionRowHeight : kDefaultRowHeight,
        verticalAlign: 0.5);
    if (isSuggestion) {
      _suggestionKeys.add(key);
    }
    return textKey;
  }

  Widget _createImageKey(String image, int width, String action) {
    return new ImageKey(image, _getAction(action), flex: width);
  }

  Function _getAction(String action) {
    switch (action) {
      case kKeyActionEmitText:
        return null;
      case kKeyActionDelete:
        return _onDeletePressed;
      case kKeyActionSpace:
        return _onSpacePressed;
      case kKeyActionGo:
        return _onGoPressed;
      default:
        return () {
          setState(() {
            _keyboardWidget = _keyboards[int.parse(action)];
          });
        };
    }
  }

  void _onText(String text) {
    config.onText(text);
  }

  void _onSuggestion(String suggestion) {
    config.onSuggestion(suggestion);
  }

  void _onSpacePressed() {
    config.onText(' ');
  }

  void _onGoPressed() {
    config.onGo();
  }

  void _onDeletePressed() {
    config.onDelete();
  }
}

class KeyboardInputOverlay {
  final GlobalKey editTextKey = new GlobalKey();

  Keyboard _keyboard;

  Widget createInputArea(_) => new InputText(editTextKey: editTextKey);

  Widget createDeviceExtension(Key key) {
    _keyboard = new Keyboard(
        key: key,
        onText: _onText,
        onSuggestion: _onSuggestion,
        onDelete: _onDelete,
        onGo: _onGo);
    return new RepaintBoundary(child: _keyboard);
  }

  void _onText(String text) {
    _addText(text);
    _updateSuggestions();
  }

  void _onSuggestion(String suggestion) {
    final stringList = _text.split(' ');
    if (stringList.isEmpty) {
      return;
    }

    _deleteLast(stringList[stringList.length - 1].length);
    _addText(suggestion + ' ');
    _updateSuggestions();
  }

  void _onDelete() {
    _deleteLast(1);
    _updateSuggestions();
  }

  void _onGo() {
    editTextKey.currentState.clear();
  }

  String get _text => editTextKey.currentState.text;

  void _addText(String text) {
    editTextKey.currentState.append(text);
  }

  void _deleteLast(int beforeLength) {
    editTextKey.currentState.backspace();
  }

  void _updateSuggestions() {
    ((_keyboard.key as GlobalKey).currentState as KeyboardState)
        .updateSuggestions(_text);
  }
}
