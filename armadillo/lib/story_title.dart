// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// The title of a story.
class StoryTitle extends StatelessWidget {
  final String title;
  final double opacity;

  StoryTitle({this.title, this.opacity: 1.0});

  @override
  Widget build(BuildContext context) => new Opacity(
        opacity: opacity,
        child: new Text(
          title.toUpperCase(),
          style: new TextStyle(
            fontSize: 11.0,
            color: new Color.fromARGB(160, 255, 255, 255),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      );
}
