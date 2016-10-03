// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../lib/story.dart';
import '../lib/story_cluster.dart';
import '../lib/story_list_layout.dart';

/// Set this to true to see what the actual bounds will be in the case you need
/// to update the expected bounds.  The output should be copy-pastable into the
/// expected bounds array.
const bool _kPrintBounds = false;

final DateTime _kCurrentTime = new DateTime.now();
final List<Story> _kDummyStories = <Story>[
  new Story(
    lastInteraction: _kCurrentTime,
    cumulativeInteractionDuration: const Duration(minutes: 7),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 7)),
    cumulativeInteractionDuration: const Duration(minutes: 34),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 41)),
    cumulativeInteractionDuration: const Duration(minutes: 24),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 65)),
    cumulativeInteractionDuration: const Duration(minutes: 24),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 89)),
    cumulativeInteractionDuration: const Duration(minutes: 18),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 107)),
    cumulativeInteractionDuration: const Duration(minutes: 1),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 108)),
    cumulativeInteractionDuration: const Duration(minutes: 29),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 152)),
    cumulativeInteractionDuration: const Duration(minutes: 20),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 198)),
    cumulativeInteractionDuration: const Duration(minutes: 9),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 207)),
    cumulativeInteractionDuration: const Duration(minutes: 6),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 213)),
    cumulativeInteractionDuration: const Duration(minutes: 28),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 241)),
    cumulativeInteractionDuration: const Duration(minutes: 26),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 272)),
    cumulativeInteractionDuration: const Duration(minutes: 1),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 273)),
    cumulativeInteractionDuration: const Duration(minutes: 3),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 276)),
    cumulativeInteractionDuration: const Duration(minutes: 20),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 296)),
    cumulativeInteractionDuration: const Duration(minutes: 28),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 324)),
    cumulativeInteractionDuration: const Duration(minutes: 3),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 327)),
    cumulativeInteractionDuration: const Duration(minutes: 18),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 369)),
    cumulativeInteractionDuration: const Duration(minutes: 18),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 387)),
    cumulativeInteractionDuration: const Duration(minutes: 16),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 403)),
    cumulativeInteractionDuration: const Duration(minutes: 17),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 420)),
    cumulativeInteractionDuration: const Duration(minutes: 26),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 446)),
    cumulativeInteractionDuration: const Duration(minutes: 29),
  ),
  new Story(
    lastInteraction: _kCurrentTime.subtract(const Duration(minutes: 475)),
    cumulativeInteractionDuration: const Duration(minutes: 8),
  ),
];

final Size _k1280x900Size = new Size(1280.0, 800.0);
final List<Rect> _kExpectedRectsFor1280x800 = <Rect>[
  new Rect.fromLTWH(-532.0, -248.5, 280.0, 175.0),
  new Rect.fromLTWH(-224.0, -248.5, 392.0, 245.0),
  new Rect.fromLTWH(196.0, -294.0, 336.0, 210.0),
  new Rect.fromLTWH(-364.0, -553.0, 364.0, 227.5),
  new Rect.fromLTWH(28.0, -567.0, 336.0, 210.0),
  new Rect.fromLTWH(-364.0, -871.5, 280.0, 175.0),
  new Rect.fromLTWH(-56.0, -871.5, 392.0, 245.0),
  new Rect.fromLTWH(-336.0, -1141.0, 308.0, 192.5),
  new Rect.fromLTWH(0.0, -1197.0, 308.0, 192.5),
  new Rect.fromLTWH(-308.0, -1393.0, 280.0, 175.0),
  new Rect.fromLTWH(0.0, -1449.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -1645.0, 280.0, 175.0),
  new Rect.fromLTWH(0.0, -1701.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -1897.0, 280.0, 175.0),
  new Rect.fromLTWH(0.0, -1953.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2149.0, 280.0, 175.0),
  new Rect.fromLTWH(0.0, -2205.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2401.0, 280.0, 175.0),
  new Rect.fromLTWH(0.0, -2457.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2653.0, 280.0, 175.0),
  new Rect.fromLTWH(0.0, -2709.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2897.5, 280.0, 175.0),
  new Rect.fromLTWH(0.0, -2940.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -3136.0, 292.0, 182.5),
];

final Size _k360x640Size = new Size(360.0, 640.0);
final List<Rect> _kExpectedRectsFor360x640 = <Rect>[
  new Rect.fromLTWH(-164.0, -167.71160888671875, 328.0, 135.71160888671875),
  new Rect.fromLTWH(-164.0, -346.0005798339844, 328.0, 146.28897094726562),
  new Rect.fromLTWH(-164.0, -512.9052124023438, 328.0, 134.90463256835938),
  new Rect.fromLTWH(-164.0, -677.428955078125, 328.0, 132.52374267578125),
  new Rect.fromLTWH(-164.0, -838.5283813476562, 328.0, 129.09942626953125),
  new Rect.fromLTWH(-164.0, -997.0927734375, 328.0, 126.56439208984375),
  new Rect.fromLTWH(-164.0, -1153.9691162109375, 328.0, 124.8763427734375),
  new Rect.fromLTWH(-164.0, -1308.9691162109375, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1463.9691162109375, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1618.9691162109375, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1773.9691162109375, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1928.9691162109375, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2083.96923828125, 328.0, 123.0001220703125),
  new Rect.fromLTWH(-164.0, -2238.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2393.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2548.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2703.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2858.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3013.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3168.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3323.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3478.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3633.96923828125, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3788.96923828125, 328.0, 123.0),
];

void main() {
  test('Single column, null stories in, no stories out.', () {
    Size size = new Size(100.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: null,
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Multi column, null stories in, no stories out.', () {
    Size size = new Size(1000.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: null,
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Single column, no stories in, no stories out.', () {
    Size size = new Size(100.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: [],
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Multi column, no stories in, no stories out.', () {
    Size size = new Size(1000.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: [],
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Single column, some stories in, some stories out.', () {
    StoryListLayout layout = new StoryListLayout(size: _k360x640Size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: _kDummyStories
          .map((Story story) => new StoryCluster(stories: [story]))
          .toList(),
      currentTime: _kCurrentTime,
    );
    expect(stories.length, _kDummyStories.length);

    if (_kPrintBounds) {
      _printBounds(stories);
    }

    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.width,
        equals(_kExpectedRectsFor360x640[i].width),
        reason: "Story $i has incorrect width!",
      );
      expect(
        bounds.height,
        equals(_kExpectedRectsFor360x640[i].height),
        reason: "Story $i has incorrect height!",
      );
    }
    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.left,
        equals(_kExpectedRectsFor360x640[i].left),
        reason: "Story $i has incorrect left!",
      );
      expect(
        bounds.top,
        equals(_kExpectedRectsFor360x640[i].top),
        reason: "Story $i has incorrect top!",
      );
    }
  });

  test('Multi column, some stories in, some stories out.', () {
    StoryListLayout layout = new StoryListLayout(size: _k1280x900Size);
    List<StoryLayout> stories = layout.layout(
      storyClustersToLayout: _kDummyStories
          .map((Story story) => new StoryCluster(stories: [story]))
          .toList(),
      currentTime: _kCurrentTime,
    );
    expect(stories.length, _kDummyStories.length);

    if (_kPrintBounds) {
      _printBounds(stories);
    }

    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.width,
        equals(_kExpectedRectsFor1280x800[i].width),
        reason: "Story $i has incorrect width!",
      );
      expect(
        bounds.height,
        equals(_kExpectedRectsFor1280x800[i].height),
        reason: "Story $i has incorrect height!",
      );
    }
    for (int i = 0; i < stories.length; i++) {
      Rect bounds = stories[i].bounds;
      expect(
        bounds.left,
        equals(_kExpectedRectsFor1280x800[i].left),
        reason: "Story $i has incorrect left!",
      );
      expect(
        bounds.top,
        equals(_kExpectedRectsFor1280x800[i].top),
        reason: "Story $i has incorrect top!",
      );
    }
  });
}

/// Call this before checking bounds in tests to print out what the
/// actual bounds will be.  Use the output to update the expected bounds
/// array when you're sure it's what you want.
void _printBounds(List<StoryLayout> stories) {
  for (int i = 0; i < stories.length; i++) {
    Rect bounds = stories[i].bounds;
    print(
        'new Rect.fromLTWH(${bounds.left},${bounds.top},${bounds.width},${bounds.height}),');
  }
}
