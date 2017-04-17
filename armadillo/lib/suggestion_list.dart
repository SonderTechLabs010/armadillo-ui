// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sysui_widgets/raw_keyboard_input.dart';

import 'suggestion.dart';
import 'suggestion_model.dart';
import 'suggestion_widget.dart';

const String _kImage = 'packages/armadillo/res/logo_googleg_24dpx4.png';

/// Called when a suggestion is selected.  [globalBounds] indicates the location
/// of the widget representing [suggestion] was on screen when it was selected.
typedef void OnSuggestionSelected(Suggestion suggestion, Rect globalBounds);

/// Displays a list of suggestions and provides a mechanism for asking for
/// new things to do.
class SuggestionList extends StatefulWidget {
  /// The controller to use for scrolling the list.
  final ScrollController scrollController;

  /// Called when the user begins asking.
  final VoidCallback onAskingStarted;

  /// Called when the user ends asking.
  final VoidCallback onAskingEnded;

  /// Called when a suggestion is selected.
  final OnSuggestionSelected onSuggestionSelected;

  /// Called when the text representation of what the user is asking changes.
  final ValueChanged<String> onAskTextChanged;

  /// The number of columns to use for displaying suggestions.
  final int columnCount;

  /// Constructor.
  SuggestionList({
    Key key,
    this.scrollController,
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

/// Manages the asking state for the [SuggestionList].
class SuggestionListState extends State<SuggestionList> {
  final GlobalKey<RawKeyboardInputState> _inputKey =
      new GlobalKey<RawKeyboardInputState>();
  bool _asking = false;
  Suggestion _selectedSuggestion;

  /// The current ask text.
  String get text => _inputKey.currentState?.text;

  /// Appends [text] to the ask text.
  void append(String text) {
    _inputKey.currentState?.append(text);
    widget.onAskTextChanged?.call(text);
    SuggestionModel.of(context).askText = this.text;
  }

  /// Removes the last character of the ask text.
  void backspace() {
    _inputKey.currentState?.backspace();
    widget.onAskTextChanged?.call(text);
    SuggestionModel.of(context).askText = text;
  }

  /// Clears the ask text.
  void clear() {
    _inputKey.currentState?.clear();
    widget.onAskTextChanged?.call(text);
    SuggestionModel.of(context).askText = null;
  }

  /// Clears the last selected suggestion.  The selected suggestion isn't drawn
  /// in favor of a splash transition drawing it.
  void resetSelection() {
    setState(() {
      _selectedSuggestion = null;
    });
  }

  /// Called when a suggestion is selected from an IME when asking.
  void onSuggestion(String suggestion) {
    if (suggestion == null || suggestion.isEmpty) {
      return;
    }
    final List<String> stringList = text.split(' ');
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

  /// Stops asking and clears the the ask text.
  void stopAsking() {
    if (!_asking) {
      return;
    }
    setState(() {
      _asking = false;
      SuggestionModel.of(context).asking = _asking;
      clear();
      widget.onAskingEnded?.call();
    });
  }

  /// Selects the first suggestion in the list as if it had been tapped.
  void selectFirstSuggestions() {
    List<Suggestion> suggestions = SuggestionModel.of(context).suggestions;
    if (suggestions.isNotEmpty) {
      _onSuggestionSelected(suggestions[0]);
    }
  }

  @override
  Widget build(BuildContext context) => new Stack(
        children: <Widget>[
          new Positioned(
            top: 0.0,
            left: 0.0,
            right: 0.0,
            height: 84.0,
            child: new GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_asking) {
                  return;
                }
                setState(() {
                  _asking = true;
                });
                SuggestionModel.of(context).asking = _asking;
                widget.onAskingStarted?.call();
              },
              child: new Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  // Image.
                  new Padding(
                    padding: const EdgeInsets.only(
                      right: 16.0,
                      left: 32.0,
                      top: 32.0,
                      bottom: 32.0,
                    ),
                    child: new Image.asset(_kImage, fit: BoxFit.cover),
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
                        onTextCommitted: (String text) {
                          // Select the first suggestion on text commit (ie.
                          // Pressing enter or tapping 'Go').
                          List<Suggestion> suggestions =
                              SuggestionModel.of(context).suggestions;
                          if (suggestions.isNotEmpty) {
                            _onSuggestionSelected(suggestions.first);
                          }
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
            child: new ScopedModelDescendant<SuggestionModel>(
              builder: (
                BuildContext context,
                Widget child,
                SuggestionModel suggestionModel,
              ) =>
                  widget.columnCount == 3
                      ? _createThreeColumnBlock(suggestionModel.suggestions)
                      : widget.columnCount == 2
                          ? _createTwoColumnBlock(suggestionModel.suggestions)
                          : _createSingleColumnBlock(
                              suggestionModel.suggestions),
            ),
          ),
        ],
      );

  Widget _createSingleColumnBlock(List<Suggestion> suggestions) => new Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: new ListView(
          controller: widget.scrollController,
          children: suggestions
              .map((Suggestion suggestion) => _createSuggestion(suggestion))
              .toList(),
        ),
      );

  Widget _createTwoColumnBlock(List<Suggestion> suggestions) {
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
        child: new ListView.builder(
          controller: widget.scrollController,
          itemCount: leftSuggestions.length,
          itemBuilder: (BuildContext context, int index) => new Row(
                children: <Widget>[
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
    );
  }

  Widget _createThreeColumnBlock(List<Suggestion> suggestions) {
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
        child: new ListView.builder(
          controller: widget.scrollController,
          itemCount: leftSuggestions.length,
          itemBuilder: (BuildContext context, int index) => new Row(
                children: <Widget>[
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
        widget.onSuggestionSelected(
          suggestion,
          box.localToGlobal(Offset.zero) & box.size,
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
