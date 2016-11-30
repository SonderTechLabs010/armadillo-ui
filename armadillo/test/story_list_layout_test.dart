// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:armadillo/story.dart';
import 'package:armadillo/story_cluster.dart';
import 'package:armadillo/story_list_layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

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
  new Rect.fromLTWH(-532.0, -220.5, 280.0, 175.0),
  new Rect.fromLTWH(-196.0, -220.5, 392.0, 245.0),
  new Rect.fromLTWH(252.0, -266.0, 336.0, 210.0),
  new Rect.fromLTWH(-504.0, -556.5, 364.0, 227.5),
  new Rect.fromLTWH(-84.0, -556.5, 336.0, 210.0),
  new Rect.fromLTWH(308.0, -630.0, 252.0, 157.5),
  new Rect.fromLTWH(-364.0, -843.5, 364.0, 227.5),
  new Rect.fromLTWH(56.0, -899.5, 336.0, 210.0),
  new Rect.fromLTWH(-336.0, -1113.0, 308.0, 192.5),
  new Rect.fromLTWH(28.0, -1169.0, 308.0, 192.5),
  new Rect.fromLTWH(-308.0, -1365.0, 280.0, 175.0),
  new Rect.fromLTWH(28.0, -1421.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -1617.0, 280.0, 175.0),
  new Rect.fromLTWH(28.0, -1673.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -1869.0, 280.0, 175.0),
  new Rect.fromLTWH(28.0, -1925.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2121.0, 280.0, 175.0),
  new Rect.fromLTWH(28.0, -2177.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2373.0, 280.0, 175.0),
  new Rect.fromLTWH(28.0, -2429.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2625.0, 280.0, 175.0),
  new Rect.fromLTWH(28.0, -2681.0, 280.0, 175.0),
  new Rect.fromLTWH(-308.0, -2856.0, 280.0, 175.0),
  new Rect.fromLTWH(28.0, -2912.0, 280.0, 175.0),
];

final Size _k360x640Size = new Size(360.0, 640.0);
final List<Rect> _kExpectedRectsFor360x640 = <Rect>[
  new Rect.fromLTWH(-172.0, -174.33169555664062, 344.0, 142.33169555664062),
  new Rect.fromLTWH(-172.0, -359.7567138671875, 344.0, 153.42501831054688),
  new Rect.fromLTWH(-172.0, -533.2420654296875, 344.0, 141.4853515625),
  new Rect.fromLTWH(-172.0, -704.2303466796875, 344.0, 138.98828125),
  new Rect.fromLTWH(-172.0, -871.6273193359375, 344.0, 135.39697265625),
  new Rect.fromLTWH(-172.0, -1036.3656005859375, 344.0, 132.73828125),
  new Rect.fromLTWH(-172.0, -1199.33349609375, 344.0, 130.9678955078125),
  new Rect.fromLTWH(-172.0, -1360.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -1521.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -1682.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -1843.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -2004.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -2165.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -2326.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -2487.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -2648.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -2809.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -2970.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -3131.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -3292.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -3453.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -3614.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -3775.33349609375, 344.0, 129.0),
  new Rect.fromLTWH(-172.0, -3936.33349609375, 344.0, 129.0),
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
