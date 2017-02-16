// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'panel.dart';

const double _kDragTargetSize = 32.0;

const Color _kGestureDetectorColor = const Color(0x00800080);

/// Adds gesture detectors between [panels] to allow them to be resized with a
/// horizontal or vertical drag.  These gesture detectors are overlayed on top
/// of [child].
/// Once a resizing has occurred [onPanelsChanged] will be called.
class PanelResizingOverlay extends StatelessWidget {
  final List<Panel> panels;
  final Widget child;
  final VoidCallback onPanelsChanged;

  PanelResizingOverlay({
    Key key,
    this.panels,
    this.child,
    this.onPanelsChanged,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For each panel, look at its right and bottom.  If not 1.0, find the
    // panels on the other side of that edge.  If 1:many or many:1
    Set<double> rights = new Set<double>();
    Set<double> bottoms = new Set<double>();
    panels.forEach((Panel panel) {
      if (panel.right != 1.0) {
        rights.add(panel.right);
      }

      if (panel.bottom != 1.0) {
        bottoms.add(panel.bottom);
      }
    });

    List<Widget> stackChildren = <Widget>[child];

    // Create draggables for each vertical seam.
    List<VerticalSeam> verticalSeams = _getVerticalSeams(rights);
    stackChildren.addAll(
      verticalSeams.map(
        (VerticalSeam verticalSeam) => new Positioned.fill(
              child: verticalSeam.build(context),
            ),
      ),
    );

    // Create draggables for each horizontal seam.
    List<HorizontalSeam> horizontalSeams = _getHorizontalSeams(bottoms);
    stackChildren.addAll(
      horizontalSeams.map(
        (HorizontalSeam horizontalSeam) => new Positioned.fill(
              child: horizontalSeam.build(context),
            ),
      ),
    );

    return new Stack(children: stackChildren);
  }

  /// For each element of [rights], find the set of panels that touch that
  /// element with their right or left and create a [VerticalSeam] from them.
  /// There can be multiple [VerticalSeam]s for a right if the panels on the
  /// left and right don't overlap contiguously.
  List<VerticalSeam> _getVerticalSeams(Set<double> rights) {
    List<VerticalSeam> verticalSeams = <VerticalSeam>[];
    rights.forEach((double right) {
      List<Panel> touchingPanels = panels
          .where((Panel panel) => panel.left == right || panel.right == right)
          .toList();
      touchingPanels.sort(
        (Panel a, Panel b) => a.top < b.top ? -1 : a.top > b.top ? 1 : 0,
      );
      // Start first span.
      double top = touchingPanels.first.top;
      double bottom = touchingPanels.first.bottom;
      List<Panel> panelsToLeft = <Panel>[];
      List<Panel> panelsToRight = <Panel>[];
      touchingPanels.forEach((Panel panel) {
        if (panel.top < bottom) {
          if (panel.bottom > bottom) {
            bottom = panel.bottom;
          }
        } else {
          // Store span, start new span.
          verticalSeams.add(
            new VerticalSeam(
              x: right,
              top: top,
              bottom: bottom,
              panelsToLeft: panelsToLeft,
              panelsToRight: panelsToRight,
              onPanelsChanged: onPanelsChanged,
            ),
          );

          top = panel.top;
          bottom = panel.bottom;
          panelsToLeft = <Panel>[];
          panelsToRight = <Panel>[];
        }
        if (panel.left == right) {
          panelsToRight.add(panel);
        } else {
          panelsToLeft.add(panel);
        }
      });
      // Store last span.
      verticalSeams.add(
        new VerticalSeam(
          x: right,
          top: top,
          bottom: bottom,
          panelsToLeft: panelsToLeft,
          panelsToRight: panelsToRight,
          onPanelsChanged: onPanelsChanged,
        ),
      );
    });
    return verticalSeams;
  }

  /// For each element of [bottoms], find the set of panels that touch that
  /// element with their top or bottom and create a [HorizontalSeam] from them.
  /// There can be multiple [HorizontalSeam]s for a bottom if the panels on the
  /// top and bottom don't overlap contiguously.
  List<HorizontalSeam> _getHorizontalSeams(Set<double> bottoms) {
    List<HorizontalSeam> horizontalSeams = <HorizontalSeam>[];
    bottoms.forEach((double bottom) {
      List<Panel> touchingPanels = panels
          .where((Panel panel) => panel.top == bottom || panel.bottom == bottom)
          .toList();
      touchingPanels.sort(
        (Panel a, Panel b) => a.left < b.left ? -1 : a.left > b.left ? 1 : 0,
      );
      // Start first span.
      double left = touchingPanels.first.left;
      double right = touchingPanels.first.right;
      List<Panel> panelsAbove = <Panel>[];
      List<Panel> panelsBelow = <Panel>[];
      touchingPanels.forEach((Panel panel) {
        if (panel.left < right) {
          if (panel.right > right) {
            right = panel.right;
          }
        } else {
          // Store span, start new span.
          horizontalSeams.add(
            new HorizontalSeam(
              y: bottom,
              left: left,
              right: right,
              panelsAbove: panelsAbove,
              panelsBelow: panelsBelow,
              onPanelsChanged: onPanelsChanged,
            ),
          );

          left = panel.left;
          right = panel.right;
          panelsAbove = <Panel>[];
          panelsBelow = <Panel>[];
        }
        if (panel.top == bottom) {
          panelsBelow.add(panel);
        } else {
          panelsAbove.add(panel);
        }
      });
      // Store last span.
      horizontalSeams.add(
        new HorizontalSeam(
          y: bottom,
          left: left,
          right: right,
          panelsAbove: panelsAbove,
          panelsBelow: panelsBelow,
          onPanelsChanged: onPanelsChanged,
        ),
      );
    });
    return horizontalSeams;
  }
}

/// Holds the information about a vertical seam between two sets of panels.
/// [x] is the horizontal position of the seam.
/// The seam spans from [top] to [bottom] on the vertical axis.
/// [panelsToLeft] are the [Panel]s to the lest of the seam.
/// [panelsToRight] are the [Panel]s to the right of the seam.
/// When a drag happens [panelsToLeft] and [panelsToRight] will be resized and
/// [onPanelsChanged] will be called.
/// [x], [top], and [bottom] are all specified in fractional values.
class VerticalSeam {
  final double x;
  final double top;
  final double bottom;
  final List<Panel> panelsToLeft;
  final List<Panel> panelsToRight;
  final VoidCallback onPanelsChanged;

  VerticalSeam({
    this.x,
    this.top,
    this.bottom,
    this.panelsToLeft,
    this.panelsToRight,
    this.onPanelsChanged,
  });

  /// Creates a [Widget] representing this seam which can be dragged.
  Widget build(BuildContext context) => new CustomSingleChildLayout(
        delegate: new _VerticalSeamLayoutDelegate(
          x: x,
          top: top,
          bottom: bottom,
        ),
        child: new Container(
          decoration: new BoxDecoration(
            backgroundColor: _kGestureDetectorColor,
          ),
          child: new GestureDetector(
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              RenderBox box = context.findRenderObject();
              double fractionalDelta =
                  toGridValue(details.primaryDelta / box.size.width);

              if (panelsToLeft.every(
                    (Panel panel) => panel.canAdjustRight(
                          fractionalDelta,
                          box.size.width,
                        ),
                  ) &&
                  panelsToRight.every(
                    (Panel panel) => panel.canAdjustLeft(
                          fractionalDelta,
                          box.size.width,
                        ),
                  )) {
                panelsToLeft.forEach((Panel panel) {
                  panel.adjustRight(fractionalDelta);
                });
                panelsToRight.forEach((Panel panel) {
                  panel.adjustLeft(fractionalDelta);
                });
                onPanelsChanged();
              }
            },
          ),
        ),
      );

  @override
  String toString() => 'VerticalSeam($x: $top => $bottom)\n'
      '\tpanelsToLeft: $panelsToLeft\n'
      '\tpanelsToRight: $panelsToRight';
}

/// Positions and sizes a vertical seam.
class _VerticalSeamLayoutDelegate extends SingleChildLayoutDelegate {
  final double x;
  final double top;
  final double bottom;

  _VerticalSeamLayoutDelegate({this.x, this.top, this.bottom});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      new BoxConstraints.tightFor(
        width: _kDragTargetSize,
        height: (bottom - top) * constraints.maxHeight,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => new Offset(
        x * size.width - _kDragTargetSize / 2.0,
        top * size.height,
      );

  @override
  bool shouldRelayout(_VerticalSeamLayoutDelegate oldDelegate) =>
      oldDelegate.top != top ||
      oldDelegate.bottom != bottom ||
      oldDelegate.x != x;
}

/// Holds the information about a horizontal seam between two sets of panels.
/// [y] is the vertical position of the seam.
/// The seam spans from [left] to [right] on the horizontal axis.
/// [panelsAbove] are the [Panel]s above the seam.
/// [panelsBelow] are the [Panel]s below the seam.
/// When a drag happens [panelsAbove] and [panelsBelow] will be resized and
/// [onPanelsChanged] will be called.
/// [y], [left], and [right] are all specified in fractional values.
class HorizontalSeam {
  final double y;
  final double left;
  final double right;
  final List<Panel> panelsAbove;
  final List<Panel> panelsBelow;
  final VoidCallback onPanelsChanged;

  HorizontalSeam({
    this.y,
    this.left,
    this.right,
    this.panelsAbove,
    this.panelsBelow,
    this.onPanelsChanged,
  });

  /// Creates a [Widget] representing this seam which can be dragged.
  Widget build(BuildContext context) => new CustomSingleChildLayout(
        delegate: new _HorizontalSeamLayoutDelegate(
          y: y,
          left: left,
          right: right,
        ),
        child: new Container(
          decoration: new BoxDecoration(
            backgroundColor: _kGestureDetectorColor,
          ),
          child: new GestureDetector(
            onVerticalDragUpdate: (DragUpdateDetails details) {
              RenderBox box = context.findRenderObject();

              double fractionalDelta =
                  toGridValue(details.primaryDelta / box.size.height);

              if (panelsAbove.every(
                    (Panel panel) => panel.canAdjustBottom(
                          fractionalDelta,
                          box.size.height,
                        ),
                  ) &&
                  panelsBelow.every(
                    (Panel panel) => panel.canAdjustTop(
                          fractionalDelta,
                          box.size.height,
                        ),
                  )) {
                panelsAbove.forEach((Panel panel) {
                  panel.adjustBottom(fractionalDelta);
                });
                panelsBelow.forEach((Panel panel) {
                  panel.adjustTop(fractionalDelta);
                });
                onPanelsChanged();
              }
            },
          ),
        ),
      );

  @override
  String toString() => 'HorizontalSeam($y: $left => $right)\n'
      '\tpanelsAbove: $panelsAbove\n'
      '\tpanelsBelow: $panelsBelow';
}

/// Positions and sizes a horizontal seam.
class _HorizontalSeamLayoutDelegate extends SingleChildLayoutDelegate {
  final double y;
  final double left;
  final double right;

  _HorizontalSeamLayoutDelegate({this.y, this.left, this.right});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      new BoxConstraints.tightFor(
        width: (right - left) * constraints.maxWidth,
        height: _kDragTargetSize,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => new Offset(
        left * size.width,
        y * size.height - _kDragTargetSize / 2.0,
      );

  @override
  bool shouldRelayout(_HorizontalSeamLayoutDelegate oldDelegate) =>
      oldDelegate.left != left ||
      oldDelegate.right != right ||
      oldDelegate.y != y;
}
