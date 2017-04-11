// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

const double kDefaultRowHeight = 54.0;
const int _kTurquoiseAccentColorValue = 0x8068EFAD;
const int _kUnselectedColorValue = 0xFF000000;

typedef void OnText(String text);

class TextKey extends StatefulWidget {
  static const double _kKeyTextSize = 22.0;
  static const TextStyle kDefaultTextStyle = const TextStyle(
      color: Colors.white, fontFamily: "Roboto-Light", fontSize: _kKeyTextSize);

  final String text;
  final TextStyle style;
  final double verticalAlign;
  final double horizontalAlign;
  final double height;
  final int flex;
  final VoidCallback onKeyPressed;
  final OnText onText;

  TextKey(this.text,
      {GlobalKey key,
      this.onKeyPressed,
      this.onText,
      this.style,
      this.verticalAlign: 0.5,
      this.horizontalAlign: 0.5,
      this.height,
      this.flex: 2})
      : super(key: key);

  @override
  TextKeyState createState() => new TextKeyState();
}

class TextKeyState extends State<TextKey> {
  String _text;
  bool _down;

  @override
  void initState() {
    super.initState();
    _text = widget.text;
    _down = false;
  }

  @override
  void didUpdateWidget(_) {
    setState(() {
      _text = widget.text;
      _down = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Expanded(
        flex: widget.flex,
        child: new Listener(
            onPointerDown: (_) {
              setState(() {
                _down = true;
              });
            },
            onPointerUp: (_) {
              setState(() {
                _down = false;
              });
              final VoidCallback onPressed = widget.onKeyPressed != null
                  ? widget.onKeyPressed
                  : widget.onText != null
                      ? () {
                          widget.onText(_text);
                        }
                      : () {};
              onPressed();
            },
            child: new Container(
                decoration: new BoxDecoration(
                    backgroundColor: new Color(_down
                        ? _kTurquoiseAccentColorValue
                        : _kUnselectedColorValue)),
                height: widget.height,
                child: new Align(
                    alignment: new FractionalOffset(
                        widget.horizontalAlign, widget.verticalAlign),
                    child: new Text(_text, style: widget.style)))));
  }

  set text(String text) {
    setState(() {
      _text = text;
    });
  }
}

class ImageKey extends StatefulWidget {
  static const Color kImageColor = const Color(0xFF909090);
  final String imageUrl;
  final int flex;
  final VoidCallback onKeyPressed;

  ImageKey(this.imageUrl, this.onKeyPressed, {this.flex: 2, Key key})
      : super(key: key);

  @override
  ImageKeyState createState() => new ImageKeyState();
}

class ImageKeyState extends State<ImageKey> {
  static final double kPadding = 20.0 / 3.0;

  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return new Expanded(
        flex: widget.flex,
        child: new Listener(
            onPointerDown: (_) {
              setState(() {
                _down = true;
              });
            },
            onPointerUp: (_) {
              setState(() {
                _down = false;
              });
              final VoidCallback onPressed =
                  widget.onKeyPressed != null ? widget.onKeyPressed : () {};
              onPressed();
            },
            child: new Container(
                decoration: new BoxDecoration(
                    backgroundColor: new Color(_down
                        ? _kTurquoiseAccentColorValue
                        : _kUnselectedColorValue)),
                padding: new EdgeInsets.all(kPadding),
                height: kDefaultRowHeight,
                child: new Container(
                    child: new Image(
                        image: new AssetImage(widget.imageUrl),
                        fit: BoxFit.contain,
                        color: ImageKey.kImageColor)))));
  }
}
