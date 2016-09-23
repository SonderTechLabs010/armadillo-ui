// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import '../lib/story.dart';
import '../lib/story_list_layout.dart';

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
  new Rect.fromLTWH(-532.0, -220.0, 280.0, 180.0),
  new Rect.fromLTWH(-224.0, -220.0, 392.0, 240.0),
  new Rect.fromLTWH(196.0, -220.0, 336.0, 200.0),
  new Rect.fromLTWH(-392.0, -520.0, 392.0, 240.0),
  new Rect.fromLTWH(28.0, -540.0, 364.0, 220.0),
  new Rect.fromLTWH(-364.0, -788.0, 280.0, 180.0),
  new Rect.fromLTWH(-56.0, -840.0, 392.0, 240.0),
  new Rect.fromLTWH(-336.0, -1080.0, 308.0, 180.0),
  new Rect.fromLTWH(0.0, -1100.0, 308.0, 180.0),
  new Rect.fromLTWH(-336.0, -1320.0, 308.0, 180.0),
  new Rect.fromLTWH(0.0, -1340.0, 308.0, 180.0),
  new Rect.fromLTWH(-308.0, -1560.0, 280.0, 180.0),
  new Rect.fromLTWH(0.0, -1580.0, 280.0, 180.0),
  new Rect.fromLTWH(-308.0, -1800.0, 280.0, 180.0),
  new Rect.fromLTWH(0.0, -1840.0, 280.0, 180.0),
  new Rect.fromLTWH(-308.0, -2040.0, 280.0, 180.0),
  new Rect.fromLTWH(0.0, -2080.0, 280.0, 180.0),
  new Rect.fromLTWH(-308.0, -2280.0, 280.0, 180.0),
  new Rect.fromLTWH(0.0, -2320.0, 280.0, 180.0),
  new Rect.fromLTWH(-308.0, -2520.0, 280.0, 180.0),
  new Rect.fromLTWH(0.0, -2560.0, 280.0, 180.0),
  new Rect.fromLTWH(-308.0, -2760.0, 280.0, 180.0),
  new Rect.fromLTWH(0.0, -2800.0, 280.0, 180.0),
  new Rect.fromLTWH(-364.0, -3040.0, 336.0, 220.0),
];

final Size _k360x640Size = new Size(360.0, 640.0);
final List<Rect> _kExpectedRectsFor360x640 = <Rect>[
  new Rect.fromLTWH(-164.0, -167.7116103318435, 328.0, 135.7116103318435),
  new Rect.fromLTWH(-164.0, -346.00057999160555, 328.0, 146.28896965976205),
  new Rect.fromLTWH(-164.0, -512.9052236900156, 328.0, 134.9046436984101),
  new Rect.fromLTWH(-164.0, -677.4289386487437, 328.0, 132.52371495872808),
  new Rect.fromLTWH(-164.0, -838.5283602852187, 328.0, 129.09942163647494),
  new Rect.fromLTWH(-164.0, -997.0927465154688, 328.0, 126.56438623025007),
  new Rect.fromLTWH(-164.0, -1153.9691722857604, 328.0, 124.87642577029148),
  new Rect.fromLTWH(-164.0, -1308.9691722857604, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1463.9691722857604, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1618.9691722857604, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1773.9691722857604, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -1928.9691722857604, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2083.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2238.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2393.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2548.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2703.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -2858.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3013.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3168.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3323.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3478.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3633.9691722857606, 328.0, 123.0),
  new Rect.fromLTWH(-164.0, -3788.9691722857606, 328.0, 123.0),
];

void main() {
  test('Single column, null stories in, no stories out.', () {
    Size size = new Size(100.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storiesToLayout: null,
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Multi column, null stories in, no stories out.', () {
    Size size = new Size(1000.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storiesToLayout: null,
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Single column, no stories in, no stories out.', () {
    Size size = new Size(100.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storiesToLayout: [],
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Multi column, no stories in, no stories out.', () {
    Size size = new Size(1000.0, 100.0);
    StoryListLayout layout = new StoryListLayout(size: size);
    List<StoryLayout> stories = layout.layout(
      storiesToLayout: [],
      currentTime: _kCurrentTime,
    );
    expect(stories.isEmpty, true);
  });

  test('Single column, some stories in, some stories out.', () {
    StoryListLayout layout = new StoryListLayout(size: _k360x640Size);
    List<StoryLayout> stories = layout.layout(
      storiesToLayout: _kDummyStories,
      currentTime: _kCurrentTime,
    );
    expect(stories.length, _kDummyStories.length);
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
      storiesToLayout: _kDummyStories,
      currentTime: _kCurrentTime,
    );
    expect(stories.length, _kDummyStories.length);
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
