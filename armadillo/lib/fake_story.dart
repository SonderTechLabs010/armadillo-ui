// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A fake story [Widget] for testing purposes.
class FakeStory extends StatefulWidget {
  @override
  FakeStoryState createState() => new FakeStoryState();
}

class FakeStoryState extends State<FakeStory> {
  MaterialColor _swatch = Colors.blue;
  FlutterLogoStyle _style = FlutterLogoStyle.markOnly;
  FakeStoryState() {
    new Timer.periodic(new Duration(seconds: 5 + new math.Random().nextInt(30)),
        (_) => _next());
  }

  void _next() {
    setState(() {
      switch (_style) {
        case FlutterLogoStyle.horizontal:
          _style = FlutterLogoStyle.markOnly;
          break;
        case FlutterLogoStyle.markOnly:
          _style = FlutterLogoStyle.stacked;
          break;
        case FlutterLogoStyle.stacked:
          _style = FlutterLogoStyle.horizontal;
          break;
        default:
          break;
      }

      if (_swatch == Colors.blue) {
        _swatch = Colors.amber;
      } else if (_swatch == Colors.amber) {
        _swatch = Colors.red;
      } else if (_swatch == Colors.red) {
        _swatch = Colors.indigo;
      } else if (_swatch == Colors.indigo) {
        _swatch = Colors.pink;
      } else if (_swatch == Colors.pink) {
        _swatch = Colors.purple;
      } else if (_swatch == Colors.purple) {
        _swatch = Colors.cyan;
      } else if (_swatch == Colors.cyan) {
        _swatch = Colors.blue;
      }
    });
  }

  @override
  Widget build(BuildContext context) => new GestureDetector(
      onTap: _next,
      child: new Container(
          decoration: new BoxDecoration(backgroundColor: Colors.white),
          foregroundDecoration: new BoxDecoration(
              border: new Border.all(width: 16.0, color: Colors.grey[500])),
          child: new FlutterLogo(
              colors: _swatch,
              style: _style,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn)));
}
