// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'suggestion.dart';

const String _kMicImageGrey600 =
    'packages/armadillo/res/ic_mic_grey600_1x_web_24dp.png';

/// Size of the suggestion text.
const double _kFontSize = 16.0;

/// Extra spacing between the characters in the suggestion text in ems.
const double _kFontSpacingEm = _kFontSize * 0.12;

/// Spacing between lines of text and between the text and icon bar.
const double _kVerticalSpacing = 8.0;

/// A fudgefactor to add to the bottom of the icon bar to make the text with
/// icon bar appear centered.  This compensates for the ascender height of the
/// suggestion text font.
const double _kIconBarBottomMargin = 4.0;

/// Height of the icon bar and the size of its square icons.
const double _kIconSize = 16.0;

/// Spacing between icons in the icon bar.
const double _kIconSpacing = 8.0;

/// The suggestion text and icons are horizontally inset by this amount.
const double _kHorizontalMargin = 24.0;

/// Gives each suggestion a slight rounded edge.
/// TODO(apwilson): We may want to animate this to zero when expanding the card
/// to fill the screen.
const double _kSuggestionCornerRadius = 4.0;

/// The height of the suggestion.
const double _kSuggestionHeight = 120.0;

/// The diameter of the person image.
const double _kPersonImageDiameter = 80.0;

/// The margin around the person image such that it sits in the center of the
/// space allocated for the suggestion image.
const double _kPersonImageInset =
    (_kSuggestionHeight - _kPersonImageDiameter) / 2.0;

class SuggestionWidget extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onSelected;
  final bool visible;

  SuggestionWidget(
      {Key key, this.suggestion, this.onSelected, this.visible: true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: _kSuggestionHeight,
      child: new Offstage(
        offstage: !visible,
        child: new ClipRRect(
          borderRadius: new BorderRadius.circular(_kSuggestionCornerRadius),
          child: new Container(
            decoration: new BoxDecoration(
              backgroundColor: Colors.white,
            ),
            child: new GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelected,
              child: new Row(
                children: <Widget>[
                  new Expanded(
                    child: new Align(
                      alignment: FractionalOffset.centerLeft,
                      child: new Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: _kHorizontalMargin,
                        ),
                        child: new Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new Text(
                              suggestion.title,
                              textAlign: TextAlign.left,
                              style: new TextStyle(
                                fontSize: _kFontSize,
                                height: (_kFontSize + _kVerticalSpacing) /
                                    _kFontSize,
                                letterSpacing: _kFontSpacingEm,
                                color: Colors.black,
                              ),
                            ),
                            new Offstage(
                              offstage: suggestion.icons.length == 0,
                              child: new Container(
                                margin: const EdgeInsets.only(
                                  top: _kVerticalSpacing,
                                  bottom: _kIconBarBottomMargin,
                                ),
                                height: _kIconSize,
                                child: new Row(
                                  children: suggestion.icons
                                      .map(
                                        (WidgetBuilder builder) =>
                                            new Container(
                                              margin: const EdgeInsets.only(
                                                  right: _kIconSpacing),
                                              width: _kIconSize,
                                              child: builder(context),
                                            ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  new Container(
                    width: _kSuggestionHeight,
                    child: suggestion.imageType == ImageType.person
                        ? new Padding(
                            padding: const EdgeInsets.all(_kPersonImageInset),
                            child: new ClipOval(
                              child: new Container(
                                decoration: new BoxDecoration(
                                  backgroundColor: suggestion.themeColor,
                                ),
                                child: suggestion.image?.call(context),
                              ),
                            ),
                          )
                        : new Container(
                            decoration: new BoxDecoration(
                              backgroundColor: suggestion.themeColor,
                            ),
                            constraints: new BoxConstraints.expand(),
                            child: suggestion.image?.call(context),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
