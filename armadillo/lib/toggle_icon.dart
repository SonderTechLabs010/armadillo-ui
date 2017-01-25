// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Represents an icon that has multiple states. When tapped, the state changes
// and a new image is displayed
class ToggleIcon extends StatefulWidget {
  // A list of image asset paths
  final List<String> imageList;
  final int initialImageIndex;
  final double width;
  final double height;

  const ToggleIcon(
      {Key key,
      this.imageList,
      this.initialImageIndex,
      this.width,
      this.height})
      : super(key: key);

  @override
  _ToggleIconState createState() => new _ToggleIconState();
}

class _ToggleIconState extends State<ToggleIcon> {
  int _currentImageIndex;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = config.initialImageIndex;
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _currentImageIndex =
              (_currentImageIndex + 1) % config.imageList.length;
        });
      },
      child: new Container(
        width: config.width,
        height: config.height,
        child: new Center(
          child: new Image.asset(config.imageList[_currentImageIndex],
              fit: ImageFit.cover),
        ),
      ),
    );
  }
}
