// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:keyboard/keyboard.dart';
import 'package:sysui_widgets/device_extension_state.dart';

import 'armadillo_overlay.dart';
import 'device_extender.dart';
import 'expand_suggestion.dart';
import 'keyboard_device_extension.dart';
import 'quick_settings.dart';
import 'nothing.dart';
import 'now.dart';
import 'peeking_overlay.dart';
import 'scroll_locker.dart';
import 'selected_suggestion_overlay.dart';
import 'size_manager.dart';
import 'splash_suggestion.dart';
import 'story.dart';
import 'story_cluster.dart';
import 'story_list.dart';
import 'story_manager.dart';
import 'suggestion.dart';
import 'suggestion_list.dart';
import 'vertical_shifter.dart';

/// The height of [Now]'s bar when minimized.
const _kMinimizedNowHeight = 50.0;

/// The height of [Now] when maximized.
const _kMaximizedNowHeight = 440.0;

/// How far [Now] should raise when quick settings is activated inline.
const _kQuickSettingsHeightBump = 120.0;

/// How far above the bottom the suggestions overlay peeks.
const _kSuggestionOverlayPeekHeight = 116.0;

/// If the width of the [Conductor] exceeds this value we will switch to
/// multicolumn mode for the [StoryList].
const double _kStoryListMultiColumnWidthThreshold = 500.0;

/// If the width of the [Conductor] exceeds this value we will switch to
/// multicolumn mode for the [SuggestionList].
const double _kSuggestionListMultiColumnWidthThreshold = 800.0;

final GlobalKey<SuggestionListState> _suggestionListKey =
    new GlobalKey<SuggestionListState>();
final GlobalKey<ScrollableState> _suggestionListScrollableKey =
    new GlobalKey<ScrollableState>();
final GlobalKey<NowState> _nowKey = new GlobalKey<NowState>();
final GlobalKey<QuickSettingsOverlayState> _quickSettingsOverlayKey =
    new GlobalKey<QuickSettingsOverlayState>();
final GlobalKey<PeekingOverlayState> _suggestionOverlayKey =
    new GlobalKey<PeekingOverlayState>();
final GlobalKey<DeviceExtensionState> _keyboardDeviceExtensionKey =
    new GlobalKey<DeviceExtensionState>();
final GlobalKey<KeyboardState> _keyboardKey = new GlobalKey<KeyboardState>();

/// The [VerticalShifter] is used to shift the [StoryList] up when [Now]'s
/// inline quick settings are activated.
final GlobalKey<VerticalShifterState> _verticalShifterKey =
    new GlobalKey<VerticalShifterState>();

final GlobalKey<ScrollableState> _scrollableKey =
    new GlobalKey<ScrollableState>();
final GlobalKey<ScrollLockerState> _scrollLockerKey =
    new GlobalKey<ScrollLockerState>();

/// The key for adding [Suggestion]s to the [SelectedSuggestionOverlay].  This
/// is to allow us to animate from a [Suggestion] in an open [SuggestionList]
/// to a [Story] focused in the [StoryList].
final GlobalKey<SelectedSuggestionOverlayState> _selectedSuggestionOverlayKey =
    new GlobalKey<SelectedSuggestionOverlayState>();

final GlobalKey<ArmadilloOverlayState> _overlayKey =
    new GlobalKey<ArmadilloOverlayState>();

/// Manages the position, size, and state of the story list, user context,
/// suggestion overlay, device extensions. interruption overlay, and quick
/// settings overlay.
class Conductor extends StatelessWidget {
  /// Note in particular the magic we're employing here to make the user
  /// state appear to be a part of the story list:
  /// By giving the story list bottom padding and clipping its bottom to the
  /// size of the final user state bar we have the user state appear to be
  /// a part of the story list and yet prevent the story list from painting
  /// behind it.
  @override
  Widget build(BuildContext context) => new LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth == 0.0 || constraints.maxHeight == 0.0) {
            return new Offstage(offstage: true);
          }
          Size fullSize = new Size(
            constraints.maxWidth,
            constraints.maxHeight,
          );

          StoryManager storyManager = InheritedStoryManager.of(context);

          storyManager.updateLayouts(fullSize);

          return new DeviceExtender(
            deviceExtensions: [_getKeyboard()],
            child: new Stack(
              children: [
                new Positioned(
                  left: 0.0,
                  right: 0.0,
                  top: 0.0,
                  bottom: _kMinimizedNowHeight,
                  child: _getStoryList(
                    storyManager,
                    constraints.maxWidth,
                    new SizeManager(fullSize),
                  ),
                ),

                // Now.
                _getNow(storyManager, constraints.maxWidth),

                // Suggestions Overlay.
                _getSuggestionOverlay(storyManager, constraints.maxWidth),

                // Selected Suggestion Overlay.
                _getSelectedSuggestionOverlay(),

                // Quick Settings Overlay.
                new QuickSettingsOverlay(
                  key: _quickSettingsOverlayKey,
                  minimizedNowBarHeight: _kMinimizedNowHeight,
                ),

                // This layout builder tracks the size available for the
                // suggestion overlay and sets its maxHeight appropriately.
                // TODO(apwilson): refactor this to not be so weird.
                new LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  double targetMaxHeight = 0.8 * constraints.maxHeight;
                  if (_suggestionOverlayKey.currentState.maxHeight !=
                          targetMaxHeight &&
                      targetMaxHeight != 0.0) {
                    _suggestionOverlayKey.currentState.maxHeight =
                        targetMaxHeight;
                    if (!_suggestionOverlayKey.currentState.hiding) {
                      _suggestionOverlayKey.currentState.show();
                    }
                  }
                  return Nothing.widget;
                }),
              ],
            ),
          );
        },
      );

  Widget _getKeyboard() => new KeyboardDeviceExtension(
        key: _keyboardDeviceExtensionKey,
        keyboardKey: _keyboardKey,
        onText: (String text) => _suggestionListKey.currentState.append(text),
        onSuggestion: (String suggestion) =>
            _suggestionListKey.currentState.onSuggestion(suggestion),
        onDelete: () => _suggestionListKey.currentState.backspace(),
        onGo: () {
          _suggestionListKey.currentState.selectFirstSuggestions();
        },
      );

  Widget _getStoryList(
    StoryManager storyManager,
    double maxWidth,
    SizeManager sizeManager,
  ) =>
      new VerticalShifter(
        key: _verticalShifterKey,
        verticalShift: _kQuickSettingsHeightBump,
        child: new ScrollLocker(
          key: _scrollLockerKey,
          child: new StoryList(
            scrollableKey: _scrollableKey,
            overlayKey: _overlayKey,
            multiColumn: maxWidth > _kStoryListMultiColumnWidthThreshold,
            quickSettingsHeightBump: _kQuickSettingsHeightBump,
            bottomPadding: _kMaximizedNowHeight - _kMinimizedNowHeight,
            onScroll: (double scrollOffset) =>
                _nowKey.currentState.scrollOffset = scrollOffset,
            onStoryClusterFocusStarted: () {
              // Lock scrolling.
              _scrollLockerKey.currentState.lock();
              _minimizeNow();
            },
            onStoryClusterFocusCompleted: (StoryCluster storyCluster) {
              _focusStoryCluster(storyManager, storyCluster);
            },
            sizeManager: sizeManager,
          ),
        ),
      );

  // We place Now in a RepaintBoundary as its animations
  // don't require its parent and siblings to redraw.
  Widget _getNow(StoryManager storyManager, double parentWidth) =>
      new RepaintBoundary(
        child: new Now(
          key: _nowKey,
          parentWidth: parentWidth,
          minHeight: _kMinimizedNowHeight,
          maxHeight: _kMaximizedNowHeight,
          quickSettingsHeightBump: _kQuickSettingsHeightBump,
          onQuickSettingsProgressChange: (double quickSettingsProgress) =>
              _verticalShifterKey.currentState.shiftProgress =
                  quickSettingsProgress,
          onReturnToOriginButtonTap: () => _goToOrigin(storyManager),
          onShowQuickSettingsOverlay: () =>
              _quickSettingsOverlayKey.currentState.show(),
          onQuickSettingsMaximized: () {
            // When quick settings starts being shown, scroll to 0.0.
            _scrollableKey.currentState.scrollTo(
              0.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
            );
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
              _suggestionOverlayKey.currentState.onVerticalDragUpdate(details),
          onBarVerticalDragEnd: (DragEndDetails details) =>
              _suggestionOverlayKey.currentState.onVerticalDragEnd(details),
        ),
      );

  Widget _getSuggestionOverlay(StoryManager storyManager, double maxWidth) =>
      new PeekingOverlay(
        key: _suggestionOverlayKey,
        peekHeight: _kSuggestionOverlayPeekHeight,
        parentWidth: maxWidth,
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
          multiColumn: maxWidth > _kSuggestionListMultiColumnWidthThreshold,
          onAskingStarted: () {
            _suggestionOverlayKey.currentState.show();
            _keyboardDeviceExtensionKey.currentState.show();
          },
          onAskingEnded: () => _keyboardDeviceExtensionKey.currentState.hide(),
          onAskTextChanged: (String text) =>
              _keyboardKey.currentState.updateSuggestions(
                _suggestionListKey.currentState.text,
              ),
          onSuggestionSelected: (Suggestion suggestion, Rect globalBounds) {
            _selectedSuggestionOverlayKey.currentState.suggestionSelected(
              expansionBehavior:
                  suggestion.selectionType == SelectionType.launchStory
                      ? new ExpandSuggestion(
                          suggestion: suggestion,
                          suggestionInitialGlobalBounds: globalBounds,
                          onSuggestionExpanded: (Suggestion suggestion) =>
                              _onSuggestionExpanded(
                                suggestion,
                                storyManager,
                              ),
                          minimizedNowBarHeight: _kMinimizedNowHeight,
                        )
                      : new SplashSuggestion(
                          suggestion: suggestion,
                          suggestionInitialGlobalBounds: globalBounds,
                          onSuggestionExpanded: (Suggestion suggestion) =>
                              _onSuggestionExpanded(
                                suggestion,
                                storyManager,
                              ),
                        ),
            );
            _minimizeNow();
          },
        ),
      );

  // This is only visible in transitoning the user from a Suggestion
  // in an open SuggestionList to a focused Story in the StoryList.
  Widget _getSelectedSuggestionOverlay() => new SelectedSuggestionOverlay(
        key: _selectedSuggestionOverlayKey,
      );

  void _defocus(StoryManager storyManager) {
    // Unfocus all story clusters.
    storyManager.activeSortedStoryClusters.forEach(_unfocusStoryCluster);

    // Unlock scrolling.
    _scrollLockerKey.currentState.unlock();
    _scrollableKey.currentState.scrollTo(0.0);
  }

  void _focusStoryCluster(
    StoryManager storyManager,
    StoryCluster storyCluster,
  ) {
    // Tell the [StoryManager] the story is now in focus.  This will move the
    // [Story] to the front of the [StoryList].
    storyManager.interactionStarted(storyCluster);

    // Ensure the focused story is completely expanded.
    storyCluster.focusSimulationKey.currentState?.forward(jumpToFinish: true);

    // Ensure the focused story's story bar is full open.
    storyCluster.stories.forEach((Story story) {
      story.storyBarKey.currentState?.maximize(jumpToFinish: true);
    });

    _scrollLockerKey.currentState.lock();
  }

  void _unfocusStoryCluster(StoryCluster s) {
    s.focusSimulationKey.currentState?.reverse();
    s.stories.forEach((Story story) {
      story.storyBarKey.currentState?.minimize();
    });
  }

  void _minimizeNow() {
    _nowKey.currentState.minimize();
    _nowKey.currentState.hideQuickSettings();
    _suggestionOverlayKey.currentState.peek = false;
    _suggestionOverlayKey.currentState.hide();
  }

  void _goToOrigin(StoryManager storyManager) {
    _defocus(storyManager);
    _nowKey.currentState.maximize();
    storyManager.interactionStopped();
  }

  void _onSuggestionExpanded(Suggestion suggestion, StoryManager storyManager) {
    List<StoryCluster> targetStoryClusters =
        storyManager.storyClusters.where((StoryCluster storyCluster) {
      bool result = false;
      storyCluster.stories.forEach((Story story) {
        if (story.id == suggestion.selectionStoryId) {
          result = true;
        }
      });
      return result;
    }).toList();

    // There should be only one story cluster with a story with this id.  If
    // that's not true, bail out.
    if (targetStoryClusters.length != 1) {
      print(
          'WARNING: Found ${targetStoryClusters.length} story clusters with a story with id ${suggestion.selectionStoryId}. Returning to origin.');
      _goToOrigin(storyManager);
      _nowKey.currentState.maximize();
    } else {
      // Focus on the story cluster.
      _focusStoryCluster(storyManager, targetStoryClusters[0]);
    }

    // Unhide selected suggestion in suggestion list.
    _suggestionListKey.currentState.resetSelection();
  }
}
