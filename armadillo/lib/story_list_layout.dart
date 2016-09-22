// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'focusable_story.dart';

/// If [StoryListLayout.size] is wider than this, the stories will be laid out
/// into multiple columns instead of a single column.
const double _kMultiColumnWidthThreshold = 500.0;

/// Stories that have been interacted with within this threshold from now are
/// considered to be juggled.  Juggled stories have their sizes increased.
const int _kJugglingThresholdMinutes = 120;

/// The [size] the story should be.
/// The [offset] of the story with respect to the bottom center of the list.
/// The [bounds] of the story as a [Rect].
abstract class StoryLayout {
  Size get size;
  Offset get offset;
  Rect get bounds => offset & size;

  @override
  String toString() => 'StoryLayout($size, $offset)';
}

class StoryListLayout {
  final Size size;

  /// In multicolumn mode, all stories are laid out into a grid.  The grid
  /// spacing is [_baseHorizontalGrid] in the horizontal direction and
  /// [_baseVerticalGrid] in the vertical direction.
  double _baseHorizontalGrid;
  double _baseVerticalGrid;

  /// The factor to scale stories within a row by based on their respective
  /// interaction minutes.
  double _intraStoryInteractionScaling;

  /// true if we should lay out in multicolumn mode.
  bool _multiColumn;

  /// [size] is the max size constraints of the list the stories will be laid
  /// out in.
  StoryListLayout({this.size}) {
    double screenSizeAdjustment = math.max(
        0.0,
        (size.width - _kMultiColumnWidthThreshold) /
            _kMultiColumnWidthThreshold);
    _baseHorizontalGrid = 16.0 + (screenSizeAdjustment * 2.0).floor() * 4.0;
    _baseVerticalGrid = 8.0 + (screenSizeAdjustment * 2.0).floor() * 4.0;
    _intraStoryInteractionScaling = 0.12 * screenSizeAdjustment;
    _multiColumn = _kMultiColumnWidthThreshold <= size.width;
  }

  /// [storiesToLayout] must be sorted by decreasing
  /// [Story.lastInteraction].
  /// [storiesToLayout] are expected to have non-overlapping interaction
  /// durations.  This algorithm may not work if they do.
  /// [currentTime] should typically be [DateTime.now] and will be used to
  /// compare against the [Story.lastInteraction] timestamps.
  /// Corrdinate system:
  /// y: the bottom of the list is y = 0.0 with decreasing y as you go up.
  /// x: the center of the list is x = 0.0 with decreasing x as you go left.
  List<StoryLayout> layout({
    List<Story> storiesToLayout,
    DateTime currentTime,
  }) {
    if (storiesToLayout?.isEmpty ?? true) {
      return const <_StoryMetadata>[];
    }

    // Convert the story list into [StoryMetadata]s determining juggling minutes
    // along the way.  See [_kJugglingThresholdMinutes].
    int jugglingStoryCount = 0; // The number of stories being juggled.
    List<_StoryMetadata> stories = new List<_StoryMetadata>.generate(
      storiesToLayout.length,
      (int index) {
        Story storyToLayout = storiesToLayout[index];

        int minutesSinceLastInteraction =
            currentTime.difference(storyToLayout.lastInteraction).inMinutes;

        int possibleJugglingMinutes = math.max(
            0, _kJugglingThresholdMinutes - minutesSinceLastInteraction);

        int storyJugglingMinutes = math.min(
            storyToLayout.cumulativeInteractionDuration.inMinutes,
            possibleJugglingMinutes);

        if (storyJugglingMinutes > 0) {
          jugglingStoryCount++;
        }

        return new _StoryMetadata(
          interactionMinutes:
              storyToLayout.cumulativeInteractionDuration.inMinutes,
          jugglingMinutes: storyJugglingMinutes,
        );
      },
    );

    // Calculate base size.
    double minW = _getMinWidth();
    int storyIndex = 0;
    stories.forEach((_StoryMetadata story) {
      double baseJugglingScaling = 0.1 +
          _smoothstep(
                0.0,
                _kJugglingThresholdMinutes.toDouble() * 0.7,
                story.jugglingMinutes.toDouble(),
              ) *
              0.5;
      double listIndexJugglingDecay = math.max(
        0.0,
        (jugglingStoryCount - storyIndex) / jugglingStoryCount,
      );
      double jugglingScaling =
          1.0 + baseJugglingScaling * listIndexJugglingDecay;
      double width = _multiColumn ? (minW - _baseHorizontalGrid) / 2.0 : minW;
      double height = width *
          math.min(0.75, size.height / size.width) *
          jugglingScaling *
          0.5 *
          (_multiColumn ? 2.0 : 1.0);

      // We only scale the width in multicolumn mode as we always stretch to fit
      // size.width in single column mode.
      story.size = new Size(
        width * (_multiColumn ? jugglingScaling : 1.0),
        height,
      );
      storyIndex++;
    });

    // Roughly layout stories.
    if (!_multiColumn) {
      _StoryMetadata previousStory;
      stories.forEach(
        (_StoryMetadata story) {
          story.offset = new Offset(
            -story.size.width / 2,
            ((previousStory == null) ? 0.0 : previousStory.offset.dy) -
                story.size.height -
                _baseHorizontalGrid * 2,
          );
          previousStory = story;
        },
      );
    } else {
      // Split stories into rows.
      double rowTop = -stories[0].size.height;
      List<List<_StoryMetadata>> rows = [];
      List<_StoryMetadata> row = [];
      double rowWidth = 0.0;

      for (int i = 0; i < stories.length; i++) {
        _StoryMetadata story = stories[i];
        _StoryMetadata previousStory = (i > 0) ? stories[i - 1] : null;
        _StoryMetadata nextStory =
            (i < stories.length - 1) ? stories[i + 1] : null;
        double maxWidth = _getMaxWidthForTop(-rowTop, jugglingStoryCount);
        story.offset = new Offset(
            (row.length == 0) ? 0.0 : previousStory.right + _baseHorizontalGrid,
            rowTop);
        rowWidth += story.size.width;
        row.add(story);
        if (nextStory == null ||
            (rowWidth + nextStory.size.width + _baseHorizontalGrid > maxWidth &&
                row.length >= 2)) {
          rows.add(row);
          row = <_StoryMetadata>[];
          rowWidth = 0.0;
          rowTop -= story.size.height + _baseHorizontalGrid * 2;
        }
      }

      // Exaggerate the time difference within a row.
      rows.where((List<_StoryMetadata> row) {
        bool isJuggling = false;
        row.forEach((_StoryMetadata story) {
          if (story.jugglingMinutes > 0) {
            isJuggling = true;
          }
        });
        return isJuggling;
      }).forEach((List<_StoryMetadata> row) {
        int storyInteractionMinutesForRow = 0;
        row.forEach((_StoryMetadata story) {
          storyInteractionMinutesForRow += story.interactionMinutes;
        });
        double averageStoryInteractionMinutes =
            storyInteractionMinutesForRow / row.length;
        row.forEach((_StoryMetadata story) {
          double scale = 1.0 +
              (story.interactionMinutes - averageStoryInteractionMinutes) /
                  averageStoryInteractionMinutes *
                  _intraStoryInteractionScaling;
          story.size *= scale;
        });
      });

      double previousRowLastStoryTop = 0.0;
      int storyIndex = 0;
      // For every row...
      List<_StoryMetadata> previousRow;
      rows.forEach((List<_StoryMetadata> row) {
        double originalRowWidth = 0.0;
        row.forEach((_StoryMetadata story) {
          originalRowWidth += story.size.width;
        });

        // For every story in the row, scale it so the row's total width
        // becomes or comes closer to our target width.
        {
          double maxRowWidth = _getMaxWidthForTop(
              -previousRowLastStoryTop + row[0].size.height,
              jugglingStoryCount);
          double targetRowWidth =
              originalRowWidth + (maxRowWidth - originalRowWidth) * 0.5;
          double scale = (targetRowWidth / originalRowWidth).clamp(0.8, 1.2);
          row.forEach((_StoryMetadata story) {
            story.size = _alignSizeToGrid(story.size * scale);
          });
        }

        // For every story in the row, assign its left relative to the row's
        // left.
        double rowWidth = 0.0;
        _StoryMetadata previousStory;
        row.forEach((_StoryMetadata story) {
          story.dx = (previousStory == null)
              ? 0.0
              : previousStory.right + _baseHorizontalGrid;
          rowWidth += story.size.width;
          previousStory = story;
        });

        // Shift all stories in the row to the left to account for horizontal
        // margins between the stories.
        double storyLeftShift = (row.length > 1)
            ? (rowWidth + (row.length - 1) * _baseHorizontalGrid) * 0.5
            : rowWidth + _baseHorizontalGrid * 0.5;

        previousStory = null;
        row.forEach((_StoryMetadata story) {
          story.offset = story.offset.translate(-storyLeftShift, 0.0);

          if (previousRow != null) {
            // TODO(apwilson): Should be vertical grid not horizontal.
            Rect expandedStoryRect = new Rect.fromLTWH(
              story.offset.dx,
              story.offset.dy - _baseHorizontalGrid * 0.5,
              story.size.width,
              story.size.height + _baseHorizontalGrid * 2.0,
            );

            // Set our y offset such that we're above the previous row.
            // TODO(apwilson): This doesn't take into account multiple
            // intersections correctly.
            previousRow
                .where(
              (_StoryMetadata storyBelow) => _intersect(
                    expandedStoryRect,
                    storyBelow.bounds,
                  ),
            )
                .forEach(
              (_StoryMetadata intersectingStory) {
                // TODO(apwilson): Should be vertical grid not horizontal.
                story.dy = intersectingStory.offset.dy -
                    story.size.height -
                    _baseHorizontalGrid * 2.0;
              },
            );

            // Stagger our y offset from the previous story.
            if (previousStory != null) {
              var staggerAmount = previousStory.size.height *
                  0.25 *
                  math.min(
                    1.0,
                    storyIndex / jugglingStoryCount * 0.25,
                  );
              if (story.offset.dy > previousStory.offset.dy - staggerAmount) {
                story.dy = previousStory.offset.dy - staggerAmount;
              }
            }
          }

          // Align the story to the grid.
          story.offset = _alignOffsetToGrid(story.offset);
          storyIndex++;
          previousStory = story;
        });

        // TODO(apwilson): Should probably be based on the highest story in this
        // row?
        previousRowLastStoryTop = row[row.length - 1].offset.dy;
        previousRow = row;
      });

      // For every row but the last one...
      for (int i = 0; i < rows.length - 1; i++) {
        List<_StoryMetadata> row = rows[i];

        // For every story in the row...
        row.forEach((_StoryMetadata story) {
          // Find the bottom Y of the stories above this one (with additional
          // grid margin).
          // Determine what stories are above us by expand the story's
          // dimensions vertically to ensure we intersect with whatever stories
          // are above it.
          Rect expandedStoryRect = new Rect.fromLTWH(
              story.offset.dx,
              story.offset.dy - 400.0,
              story.size.width,
              story.size.height + 400.0);

          Iterable<_StoryMetadata> intersectingStories = rows[i + 1].where(
              (_StoryMetadata storyAbove) =>
                  _intersect(expandedStoryRect, storyAbove.bounds));

          // If we've found a story above us...
          if (intersectingStories.isNotEmpty) {
            double maxTop = double.NEGATIVE_INFINITY;
            intersectingStories
                .forEach((_StoryMetadata intersectingStoryAbove) {
              // TODO(apwilson): Should be vertical grid not horizontal.
              maxTop = math.max(
                maxTop,
                intersectingStoryAbove.bottom + _baseHorizontalGrid * 4.0,
              );
            });

            // ...if we're too far away, get closer.
            if (story.offset.dy > maxTop) {
              story.dy = maxTop;
            }
          }
        });
      }
    }
    return stories;
  }

  double _smoothstep(double a, double b, double n) {
    var t = (n - a) / (b - a) * 12.0 - 6.0;
    return 1.0 / (1.0 + math.pow(math.E, -t));
  }

  bool _intersect(Rect r1, Rect r2) {
    Rect intersection = r1.intersect(r2);
    return intersection.width >= 0.0 && intersection.height >= 0.0;
  }

  double _getMinWidth() {
    double minW;
    if (_multiColumn) {
      double minWRatio = math.max(
        0.5,
        1 - (size.width - _kMultiColumnWidthThreshold) / 1600.0,
      );
      minW = size.width * minWRatio - _baseHorizontalGrid;
    } else {
      minW = size.width - _baseHorizontalGrid * 2;
    }
    return minW;
  }

  double _getMaxWidthForTop(double top, int jugglingStoryCount) {
    double minW = _getMinWidth();
    if (!_multiColumn) {
      return minW * 0.5;
    }

    double maxWRatio = math.max(
      0.9,
      1 - (size.width - _kMultiColumnWidthThreshold) / 4200.0,
    );
    double maxW = size.width * maxWRatio - _baseHorizontalGrid;
    double l = size.height * (jugglingStoryCount / 3.0 + 0.5);
    double t = (l - top) / l - 0.25;
    double r = _smoothstep(0.0, 1.0, t);
    return maxW * r + minW * (1.0 - r);
  }

  Offset _alignOffsetToGrid(Offset offset) => new Offset(
        (offset.dx / _baseHorizontalGrid).floor() * _baseHorizontalGrid,
        (offset.dy / _baseVerticalGrid).floor() * _baseVerticalGrid,
      );

  Size _alignSizeToGrid(Size size) => new Size(
        (size.width / _baseHorizontalGrid).floor() * _baseHorizontalGrid,
        (size.height / _baseVerticalGrid).floor() * _baseVerticalGrid,
      );
}

/// Stores positions and sizes of a story as it goes through the
/// [StoryLayout.layout] function.
class _StoryMetadata extends StoryLayout {
  final int interactionMinutes;
  final int jugglingMinutes;

  @override
  Offset offset = Offset.zero;

  @override
  Size size = Size.zero;

  _StoryMetadata({this.interactionMinutes, this.jugglingMinutes});

  double get right => offset.dx + size.width;
  double get bottom => offset.dy + size.height;

  set dy(double dy) {
    offset = new Offset(offset.dx, dy);
  }

  set dx(double dx) {
    offset = new Offset(dx, offset.dy);
  }
}
