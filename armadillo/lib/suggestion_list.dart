// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/raw_keyboard_input.dart';

import 'suggestion.dart';
import 'suggestion_manager.dart';
import 'suggestion_widget.dart';

const String _kImage = 'packages/armadillo/res/logo_googleg_24dpx4.png';

typedef void OnSuggestionSelected(Suggestion suggestion, Rect globalBounds);
typedef void OnAskTextChanged(String text);

class SuggestionList extends StatefulWidget {
  final Key scrollableKey;
  final VoidCallback onAskingStarted;
  final VoidCallback onAskingEnded;
  final OnSuggestionSelected onSuggestionSelected;
  final OnAskTextChanged onAskTextChanged;
  final int columnCount;

  SuggestionList({
    Key key,
    this.scrollableKey,
    this.onAskingStarted,
    this.onAskingEnded,
    this.onSuggestionSelected,
    this.onAskTextChanged,
    this.columnCount: 1,
  })
      : super(key: key);

  @override
  SuggestionListState createState() => new SuggestionListState();
}

class SuggestionListState extends State<SuggestionList> {
  final GlobalKey<RawKeyboardInputState> _inputKey =
      new GlobalKey<RawKeyboardInputState>();
  bool _asking = false;
  Suggestion _selectedSuggestion;

  String get text => _inputKey.currentState?.text;
  void append(String text) {
    _inputKey.currentState?.append(text);
    config.onAskTextChanged?.call(text);
    SuggestionModel.of(context).askText = this.text;
  }

  void backspace() {
    _inputKey.currentState?.backspace();
    config.onAskTextChanged?.call(text);
    SuggestionModel.of(context).askText = text;
  }

  void clear() {
    _inputKey.currentState?.clear();
    config.onAskTextChanged?.call(text);
    SuggestionModel.of(context).askText = null;
  }

  void resetSelection() {
    setState(() {
      _selectedSuggestion = null;
    });
  }

  void onSuggestion(String suggestion) {
    if (suggestion == null || suggestion.isEmpty) {
      return;
    }
    final stringList = text.split(' ');
    if (stringList.isEmpty) {
      return;
    }

    // Remove last word.
    for (int i = 0; i < stringList[stringList.length - 1].length; i++) {
      backspace();
    }

    // Add the suggested word.
    append(suggestion + ' ');
  }

  void stopAsking() {
    setState(() {
      _asking = false;
      SuggestionModel.of(context).asking = _asking;
    });
  }

  void selectFirstSuggestions() {
    List<Suggestion> suggestions = SuggestionModel.of(context).suggestions;
    if (suggestions.isNotEmpty) {
      _onSuggestionSelected(suggestions[0]);
    }
  }

  @override
  Widget build(BuildContext context) => new Stack(
        children: [
          new Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            height: 84.0,
            child: new GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _asking = !_asking;
                SuggestionModel.of(context).asking = _asking;
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
              child: new Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Image.
                  new Padding(
                    padding: const EdgeInsets.only(
                      right: 16.0,
                      left: 32.0,
                      top: 32.0,
                      bottom: 32.0,
                    ),
                    child: new Image.asset(_kImage, fit: ImageFit.cover),
                  ),
                  // Ask Anything text field.
                  new Expanded(
                    child: new Align(
                      alignment: FractionalOffset.centerLeft,
                      child: new RawKeyboardInput(
                        key: _inputKey,
                        focused: _asking,
                        onTextChanged: (String text) {
                          SuggestionModel.of(context).askText = text;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          new Positioned(
            top: 84.0,
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: config.columnCount == 3
                ? _createThreeColumnBlock(context)
                : config.columnCount == 2
                    ? _createTwoColumnBlock(context)
                    : _createSingleColumnBlock(context),
          ),
        ],
      );

  Widget _createSingleColumnBlock(BuildContext context) => new Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: new Block(
          scrollableKey: config.scrollableKey,
          children: SuggestionModel
              .of(context, rebuildOnChange: true)
              .suggestions
              .map((Suggestion suggestion) => _createSuggestion(suggestion))
              .toList(),
        ),
      );

  Widget _createTwoColumnBlock(BuildContext context) {
    List<Suggestion> suggestions =
        SuggestionModel.of(context, rebuildOnChange: true).suggestions;

    int minSuggestionsPerColumn = (suggestions.length / 2).floor();
    int additionalLeftSuggestions = suggestions.length % 2;
    int additionalRightSuggestions =
        (suggestions.length + additionalLeftSuggestions) % 2;
    List<Suggestion> leftSuggestions = new List<Suggestion>.generate(
      minSuggestionsPerColumn + additionalLeftSuggestions,
      (int index) => suggestions[index * 2],
    );
    List<Suggestion> rightSuggestions = new List<Suggestion>.generate(
      minSuggestionsPerColumn + additionalRightSuggestions,
      (int index) => suggestions[index * 2 + 1],
    );
    return new Align(
      alignment: FractionalOffset.topCenter,
      child: new ConstrainedBox(
        constraints: new BoxConstraints(maxWidth: 960.0),
        child: new Block(
          scrollableKey: config.scrollableKey,
          children: new List<Widget>.generate(
            leftSuggestions.length,
            (int index) => new Row(
                  children: [
                    new Container(height: 0.0, width: 24.0),
                    new Expanded(
                        child: _createSuggestion(leftSuggestions[index])),
                    new Container(height: 0.0, width: 24.0),
                    new Expanded(
                      child: index < rightSuggestions.length
                          ? _createSuggestion(rightSuggestions[index])
                          : new Offstage(offstage: true),
                    ),
                    new Container(height: 0.0, width: 24.0),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  Widget _createThreeColumnBlock(BuildContext context) {
    List<Suggestion> suggestions =
        SuggestionModel.of(context, rebuildOnChange: true).suggestions;

    int minSuggestionsPerColumn = (suggestions.length / 3).floor();
    int additionalLeftSuggestions = suggestions.length % 3 > 0 ? 1 : 0;
    int additionalMiddleSuggestions = suggestions.length % 3 > 1 ? 1 : 0;
    List<Suggestion> leftSuggestions = new List<Suggestion>.generate(
      minSuggestionsPerColumn + additionalLeftSuggestions,
      (int index) => suggestions[index * 3],
    );
    List<Suggestion> middleSuggestions = new List<Suggestion>.generate(
      minSuggestionsPerColumn + additionalMiddleSuggestions,
      (int index) => suggestions[index * 3 + 1],
    );
    List<Suggestion> rightSuggestions = new List<Suggestion>.generate(
      minSuggestionsPerColumn,
      (int index) => suggestions[index * 3 + 2],
    );
    return new Align(
      alignment: FractionalOffset.topCenter,
      child: new ConstrainedBox(
        constraints: new BoxConstraints(maxWidth: 1440.0),
        child: new Block(
          scrollableKey: config.scrollableKey,
          children: new List<Widget>.generate(
            leftSuggestions.length,
            (int index) => new Row(
                  children: [
                    new Container(height: 0.0, width: 24.0),
                    new Expanded(
                      child: _createSuggestion(leftSuggestions[index]),
                    ),
                    new Container(height: 0.0, width: 24.0),
                    new Expanded(
                      child: index < middleSuggestions.length
                          ? _createSuggestion(middleSuggestions[index])
                          : new Offstage(offstage: true),
                    ),
                    new Container(height: 0.0, width: 24.0),
                    new Expanded(
                      child: index < rightSuggestions.length
                          ? _createSuggestion(rightSuggestions[index])
                          : new Offstage(offstage: true),
                    ),
                    new Container(height: 0.0, width: 24.0),
                  ],
                ),
          ),
        ),
      ),
    );
  }

  void _onSuggestionSelected(Suggestion suggestion) {
    switch (suggestion.selectionType) {
      case SelectionType.launchStory:
      case SelectionType.modifyStory:
      case SelectionType.closeSuggestions:
        setState(() {
          _selectedSuggestion = suggestion;
        });
        // We pass the bounds of the suggestion w.r.t.
        // global coordinates so it can be mapped back to
        // local coordinates when it's displayed in the
        // SelectedSuggestionOverlay.
        RenderBox box =
            new GlobalObjectKey(suggestion).currentContext.findRenderObject();
        config.onSuggestionSelected(
          suggestion,
          box.localToGlobal(Point.origin) & box.size,
        );
        break;
      case SelectionType.doNothing:
      default:
        break;
    }
  }

  Widget _createSuggestion(Suggestion suggestion) => new RepaintBoundary(
        child: new Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12.0,
          ),
          child: new SuggestionWidget(
            key: new GlobalObjectKey(suggestion),
            visible: _selectedSuggestion?.id != suggestion.id,
            suggestion: suggestion,
            onSelected: () => _onSuggestionSelected(suggestion),
          ),
        ),
      );
}
