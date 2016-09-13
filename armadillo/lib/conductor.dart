// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard/keyboard.dart';
import 'package:sysui_widgets/device_extension_state.dart';

import 'device_extender.dart';
import 'expand_suggestion.dart';
import 'keyboard_device_extension.dart';
import 'now.dart';
import 'peeking_overlay.dart';
import 'recent_list.dart';
import 'splash_suggestion.dart';
import 'story_manager.dart';
import 'suggestion_list.dart';
import 'suggestion_manager.dart';
import 'selected_suggestion_overlay.dart';

/// The height of [Now]'s bar when minimized.
const _kMinimizedNowHeight = 50.0;

/// The height of [Now] when maximized.
const _kMaximizedNowHeight = 440.0;

/// How far [Now] should raise when quick settings is activated inline.
const _kQuickSettingsHeightBump = 120.0;

/// How far above the bottom the suggestions overlay peeks.
const _kSuggestionOverlayPeekHeight = 116.0;

/// If the width of the [Conductor] exceeds this value we will switch to
/// multicolumn mode for the [RecentList].
const double _kRecentListMultiColumnWidthThreshold = 600.0;

/// If the width of the [Conductor] exceeds this value we will switch to
/// multicolumn mode for the [SuggestionList].
const double _kSuggestionListMultiColumnWidthThreshold = 800.0;

final GlobalKey<RecentListState> _recentListKey =
    new GlobalKey<RecentListState>();
final GlobalKey<ScrollableState> _recentListScrollableKey =
    new GlobalKey<ScrollableState>();
final GlobalKey<SuggestionListState> _suggestionListKey =
    new GlobalKey<SuggestionListState>();
final GlobalKey<ScrollableState> _suggestionListScrollableKey =
    new GlobalKey<ScrollableState>();
final GlobalKey<NowState> _nowKey = new GlobalKey<NowState>();
final GlobalKey<PeekingOverlayState> _suggestionOverlayKey =
    new GlobalKey<PeekingOverlayState>();
final GlobalKey<DeviceExtensionState> _keyboardDeviceExtensionKey =
    new GlobalKey<DeviceExtensionState>();
final GlobalKey<KeyboardState> _keyboardKey = new GlobalKey<KeyboardState>();

/// The key for adding [Suggestion]s to the [SelectedSuggestionOverlay].  This
/// is to allow us to animate from a [Suggestion] in an open [SuggestionList]
/// to a [Story] focused in the [RecentList].
final GlobalKey<SelectedSuggestionOverlayState> _selectedSuggestionOverlayKey =
    new GlobalKey<SelectedSuggestionOverlayState>();

/// Manages the position, size, and state of the recent list, user context,
/// suggestion overlay, device extensions. interruption overlay, and quick
/// settings overlay.
class Conductor extends StatelessWidget {
  /// Note in particular the magic we're employing here to make the user
  /// state appear to be a part of the recent list:
  /// By giving the recent list bottom padding and clipping its bottom to the
  /// size of the final user state bar we have the user state appear to be
  /// a part of the recent list and yet prevent the recent list from painting
  /// behind it.
  @override
  Widget build(BuildContext context) => new DeviceExtender(
        deviceExtensions: [
          new KeyboardDeviceExtension(
              key: _keyboardDeviceExtensionKey,
              keyboardKey: _keyboardKey,
              onText: (String text) =>
                  _suggestionListKey.currentState.append(text),
              onSuggestion: (String suggestion) =>
                  _suggestionListKey.currentState.onSuggestion(suggestion),
              onDelete: () => _suggestionListKey.currentState.backspace(),
              onGo: () {
                print('go');
                // TODO(apwilson): Select first suggestion?
              }),
        ],
        child: new LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            if (constraints.maxWidth == 0.0 || constraints.maxHeight == 0.0) {
              return new Offstage(offstage: true);
            }
            return new Stack(
              children: [
                // Recent List.
                new Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  bottom: _kMinimizedNowHeight,
                  child: new RecentList(
                    key: _recentListKey,
                    multiColumn: constraints.maxWidth >
                        _kRecentListMultiColumnWidthThreshold,
                    parentSize: new Size(
                      constraints.maxWidth,
                      constraints.maxHeight - _kMinimizedNowHeight,
                    ),
                    quickSettingsHeightBump: _kQuickSettingsHeightBump,
                    scrollableKey: _recentListScrollableKey,
                    padding: new EdgeInsets.only(
                      bottom: _kMaximizedNowHeight - _kMinimizedNowHeight,
                    ),
                    onScroll: (double scrollOffset) =>
                        _nowKey.currentState.scrollOffset = scrollOffset,
                    onStoryFocusStarted: _minimizeNow,
                  ),
                ),

                // Now.  We place Now in a RepaintBoundary as its animations
                // don't require its parent and siblings to redraw.
                new Positioned(
                  bottom: 0.0,
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  child: new RepaintBoundary(
                    child: new Now(
                      key: _nowKey,
                      minHeight: _kMinimizedNowHeight,
                      maxHeight: _kMaximizedNowHeight,
                      quickSettingsHeightBump: _kQuickSettingsHeightBump,
                      onQuickSettingsProgressChange:
                          (double quickSettingsProgress) => _recentListKey
                              .currentState
                              .quickSettingsProgress = quickSettingsProgress,
                      onReturnToOriginButtonTap: () {
                        _recentListScrollableKey.currentState.scrollTo(0.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.fastOutSlowIn);
                        _recentListKey.currentState.defocus();
                        InheritedStoryManager.of(context).interactionStopped();
                      },
                      onMinimize: () {
                        _suggestionOverlayKey.currentState.peek = false;
                        _suggestionOverlayKey.currentState.hide();
                      },
                      onMaximize: () {
                        _suggestionOverlayKey.currentState.peek = true;
                        _suggestionOverlayKey.currentState.hide();
                      },
                      onBarVerticalDragUpdate: (DragUpdateDetails details) =>
                          _suggestionOverlayKey.currentState
                              .onVerticalDragUpdate(details),
                      onBarVerticalDragEnd: (DragEndDetails details) =>
                          _suggestionOverlayKey.currentState
                              .onVerticalDragEnd(details),
                    ),
                  ),
                ),

                // Suggestions Overlay.
                new PeekingOverlay(
                  key: _suggestionOverlayKey,
                  peekHeight: _kSuggestionOverlayPeekHeight,
                  onHide: () {
                    _keyboardDeviceExtensionKey.currentState?.hide();
                    _suggestionListScrollableKey.currentState?.scrollTo(
                      0.0,
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.fastOutSlowIn,
                    );
                    _suggestionListKey.currentState?.clear();
                    _suggestionListKey.currentState?.stopAsking();
                  },
                  child: new SuggestionList(
                    key: _suggestionListKey,
                    scrollableKey: _suggestionListScrollableKey,
                    multiColumn: constraints.maxWidth >
                        _kSuggestionListMultiColumnWidthThreshold,
                    onAskingStarted: () {
                      _suggestionOverlayKey.currentState.show();
                      _keyboardDeviceExtensionKey.currentState.show();
                    },
                    onAskingEnded: () =>
                        _keyboardDeviceExtensionKey.currentState.hide(),
                    onAskTextChanged: (String text) =>
                        _keyboardKey.currentState.updateSuggestions(
                          _suggestionListKey.currentState.text,
                        ),
                    onSuggestionSelected:
                        (Suggestion suggestion, Rect globalBounds) {
                      _selectedSuggestionOverlayKey.currentState
                          .suggestionSelected(
                        expansionBehavior: suggestion.selectionType ==
                                SelectionType.launchStory
                            ? new ExpandSuggestion(
                                suggestion: suggestion,
                                suggestionInitialGlobalBounds: globalBounds,
                                onSuggestionExpanded: (Suggestion suggestion) =>
                                    _onSuggestionExpanded(
                                      suggestion,
                                      context,
                                    ),
                                minimizedNowBarHeight: _kMinimizedNowHeight,
                              )
                            : new SplashSuggestion(
                                suggestion: suggestion,
                                suggestionInitialGlobalBounds: globalBounds,
                                onSuggestionExpanded: (Suggestion suggestion) =>
                                    _onSuggestionExpanded(
                                      suggestion,
                                      context,
                                    ),
                              ),
                      );
                      _minimizeNow();
                    },
                  ),
                ),

                // Selected Suggestion Overlay.
                // This is only visible in transitoning the user from a Suggestion
                // in an open SuggestionList to a focused Story in the RecentList.
                new SelectedSuggestionOverlay(
                  key: _selectedSuggestionOverlayKey,
                ),
              ],
            );
          },
        ),
      );

  void _minimizeNow() {
    _nowKey.currentState.minimize();
    _nowKey.currentState.hideQuickSettings();
    _suggestionOverlayKey.currentState.peek = false;
    _suggestionOverlayKey.currentState.hide();
  }

  void _onSuggestionExpanded(Suggestion suggestion, BuildContext context) {
    Story story = InheritedStoryManager
        .of(context)
        .stories
        .where((Story story) => story.id == suggestion.selectionStoryId)
        .single;

    assert(story != null);

    // Focus on the story.
    _recentListKey.currentState.focusStory(story);

    // Unhide selected suggestion in suggestion list.
    _suggestionListKey.currentState.resetSelection();
  }
}
