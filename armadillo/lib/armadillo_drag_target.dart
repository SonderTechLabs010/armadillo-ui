// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import 'armadillo_overlay.dart';

/// Much of this code is borrowed from the Flutter framework's inplementation
/// of [Draggable] and [DragTarget].  What is different about this
/// implementation is the addition of each piece of data having an associated
/// [Point] which indicates where it is when hovering
/// (passed in via [ArmadilloDragTargetWillAccept]) and when dropped (passed in
/// via [ArmadilloDragTargetAccept]).  We also use [ArmadilloOverlay] instead of
/// [Overlay] to display draggable drag feedback so the drag feedback can be
/// displayed in any part of the widget tree (and not just in an ancestor of the
/// draggable).
///
/// Other than keeping track of points for all candidates, the bulk of Flutter's
/// code remains intact.

/// Signature for building children of a [ArmadilloDragTarget].
///
/// The `candidateData` argument contains the list of drag data that is hovering
/// over this [DragTarget] and that has passed [ArmadilloDragTarget.onWillAccept]. The
/// `rejectedData` argument contains the list of drag data that is hovering over
/// this [ArmadilloDragTarget] and that will not be accepted by the [ArmadilloDragTarget].
typedef Widget ArmadilloDragTargetBuilder<T>(
  BuildContext context,
  Map<T, Point> candidateData,
  Map<dynamic, Point> rejectedData,
);

/// Signature for determining whether the given data will be accepted by a [ArmadilloDragTarget].
typedef bool ArmadilloDragTargetWillAccept<T>(T data, Point point);

/// Signature for causing a [ArmadilloDragTarget] to accept the given data.
typedef void ArmadilloDragTargetAccept<T>(T data, Point point);

/// A widget that can be dragged from to a [ArmadilloDragTarget] starting from long press.
///
/// When a draggable widget recognizes the start of a drag gesture, it displays
/// a [feedback] widget that tracks the user's finger across the screen. If the
/// user lifts their finger while on top of a [ArmadilloDragTarget], that target is given
/// the opportunity to accept the [data] carried by the draggble.
///
/// See also:
///
///  * [ArmadilloDragTarget]
class ArmadilloLongPressDraggable<T> extends StatefulWidget {
  /// Creates a widget that can be dragged starting from long press.
  ///
  /// The [child] and [feedback] arguments must not be null. If
  /// [maxSimultaneousDrags] is non-null, it must be positive.
  ArmadilloLongPressDraggable({
    Key key,
    this.overlayKey,
    this.child,
    this.feedback,
    this.data,
    this.childWhenDragging,
    this.onDragStarted,
  })
      : super(key: key) {
    assert(child != null);
    assert(feedback != null);
  }

  /// The data that will be dropped by this draggable.
  final T data;

  /// The widget below this widget in the tree.
  final Widget child;

  /// The widget to show instead of [child] when a drag is under way.
  ///
  /// If this is null, then [child] will be used instead (and so the
  /// drag source representation will change while a drag is under
  /// way).
  final Widget childWhenDragging;

  /// The widget to show under the pointer when a drag is under way.
  final Widget feedback;

  final VoidCallback onDragStarted;

  final GlobalKey<ArmadilloOverlayState> overlayKey;

  /// Creates a gesture recognizer that recognizes the start of the drag.
  ///
  /// Subclasses can override this function to customize when they start
  /// recognizing a drag.
  DelayedMultiDragGestureRecognizer createRecognizer(
          GestureMultiDragStartCallback onStart) =>
      new DelayedMultiDragGestureRecognizer()
        ..onStart = (Point position) {
          Drag result = onStart(position);
          if (result != null) {
            HapticFeedback.vibrate();
          }
          return result;
        };

  @override
  _DraggableState<T> createState() => new _DraggableState<T>();
}

class _DraggableState<T> extends State<ArmadilloLongPressDraggable<T>> {
  @override
  void initState() {
    super.initState();
    _recognizer = config.createRecognizer(_startDrag);
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  GestureRecognizer _recognizer;
  int _activeCount = 0;

  bool get _canDrag => _activeCount < 1;

  void _routePointer(PointerEvent event) {
    if (_canDrag) {
      _recognizer.addPointer(event);
    }
  }

  _DragAvatar<T> _startDrag(Point position) {
    if (!_canDrag) {
      return null;
    }
    config.onDragStarted?.call();
    setState(() {
      _activeCount += 1;
    });
    final RenderBox renderObject = context.findRenderObject();
    return new _DragAvatar<T>(
        overlayKey: config.overlayKey,
        data: config.data,
        initialPosition: position,
        dragStartPoint: renderObject.globalToLocal(position),
        feedback: config.feedback,
        onDragEnd: (Velocity velocity, Offset offset, bool wasAccepted) {
          setState(() {
            _activeCount -= 1;
            if (!wasAccepted) {
              // TODO(apwilson): Animate back to original position.
            }
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final bool showChild =
        _activeCount == 0 || config.childWhenDragging == null;
    return new Listener(
        onPointerDown: _canDrag ? _routePointer : null,
        child: showChild ? config.child : config.childWhenDragging);
  }
}

/// A widget that receives data when a [ArmadilloLongPressDraggable] widget is dropped.
///
/// When a draggable is dragged on top of a drag target, the drag target is
/// asked whether it will accept the data the draggable is carrying. If the user
/// does drop the draggable on top of the drag target (and the drag target has
/// indicated that it will accept the draggable's data), then the drag target is
/// asked to accept the draggable's data.
///
/// See also:
///
///  * [ArmadilloLongPressDraggable]
class ArmadilloDragTarget<T> extends StatefulWidget {
  /// Creates a widget that receives drags.
  ///
  /// The [builder] argument must not be null.
  ArmadilloDragTarget({
    Key key,
    this.builder,
    this.onWillAccept,
    this.onAccept,
    this.onCandidates,
    this.onNoCandidates,
  })
      : super(key: key) {
    assert(builder != null);
  }

  /// Called to build the contents of this widget.
  ///
  /// The builder can build different widgets depending on what is being dragged
  /// into this drag target.
  final ArmadilloDragTargetBuilder<T> builder;

  /// Called to determine whether this widget is interested in receiving a given
  /// piece of data being dragged over this drag target.
  final ArmadilloDragTargetWillAccept<T> onWillAccept;

  /// Called when an acceptable piece of data was dropped over this drag target.
  final ArmadilloDragTargetAccept<T> onAccept;

  final VoidCallback onCandidates;
  final VoidCallback onNoCandidates;

  @override
  _DragTargetState<T> createState() => new _DragTargetState<T>();
}

class _DragTargetState<T> extends State<ArmadilloDragTarget<T>> {
  final Map<T, Point> _candidateData = new Map<T, Point>();
  final Map<dynamic, Point> _rejectedData = new Map<dynamic, Point>();

  bool didEnter(dynamic data, Point globalPosition) {
    assert(_candidateData[data] == null);
    assert(_rejectedData[data] == null);
    if (data is T &&
        (config.onWillAccept == null ||
            config.onWillAccept(data, globalPosition))) {
      // If we're adding our first candidate call [config.onCandidates].
      if (_candidateData.isEmpty) {
        config.onCandidates?.call();
      }
      setState(() {
        _candidateData[data] = globalPosition;
      });
      return true;
    }
    setState(() {
      _rejectedData[data] = globalPosition;
    });
    return false;
  }

  void updatePosition(dynamic data, Point globalPosition) {
    setState(() {
      if (_candidateData[data] != null) {
        _candidateData[data] = globalPosition;
      }
      if (_rejectedData[data] != null) {
        _rejectedData[data] = globalPosition;
      }
    });
  }

  void didLeave(dynamic data) {
    assert(_candidateData[data] != null || _rejectedData[data] != null);
    if (!mounted) {
      return;
    }
    setState(() {
      // If we've removed the last candidate call [config.onNoCandidates].
      if (_candidateData.remove(data) != null && _candidateData.isEmpty) {
        config.onNoCandidates?.call();
      }
      _rejectedData.remove(data);
    });
  }

  void didDrop(dynamic data) {
    assert(_candidateData[data] != null);
    if (mounted) {
      Point point = _candidateData[data];
      setState(() {
        // If we've removed the last candidate call [config.onNoCandidates].
        if (_candidateData.remove(data) != null && _candidateData.isEmpty) {
          config.onNoCandidates?.call();
        }
      });
      config.onAccept?.call(data, point);
    }
  }

  @override
  Widget build(BuildContext context) => new MetaData(
        metaData: this,
        behavior: HitTestBehavior.translucent,
        child: config.builder(context, _candidateData, _rejectedData),
      );
}

enum _DragEndKind { dropped, canceled }
typedef void _OnDragEnd(Velocity velocity, Offset offset, bool wasAccepted);

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away, or maybe even if the Draggable that created goes away.
// This will probably need to be changed once we have more experience with using
// this widget.
class _DragAvatar<T> extends Drag {
  _DragAvatar(
      {this.overlayKey,
      this.data,
      Point initialPosition,
      this.dragStartPoint: Point.origin,
      this.feedback,
      this.onDragEnd}) {
    assert(overlayKey.currentState != null);
    assert(dragStartPoint != null);
    overlayKey.currentState.addBuilder(_build);
    _position = initialPosition;
    updateDrag(initialPosition);
  }

  final T data;
  final Point dragStartPoint;
  final Widget feedback;
  final _OnDragEnd onDragEnd;
  final GlobalKey<ArmadilloOverlayState> overlayKey;

  _DragTargetState<T> _activeTarget;
  List<_DragTargetState<T>> _enteredTargets = <_DragTargetState<T>>[];
  Point _position;
  Offset _lastOffset;

  // Drag API
  @override
  void update(DragUpdateDetails details) {
    _position += details.delta;
    updateDrag(_position);
  }

  @override
  void end(DragEndDetails details) {
    finishDrag(_DragEndKind.dropped, details.velocity);
  }

  @override
  void cancel() {
    finishDrag(_DragEndKind.canceled);
  }

  void updateDrag(Point globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    overlayKey.currentState.update();

    HitTestResult result = new HitTestResult();
    WidgetsBinding.instance.hitTest(result, globalPosition);

    List<_DragTargetState<T>> targets = _getDragTargets(result.path).toList();
    bool listsMatch = false;
    if (targets.length >= _enteredTargets.length &&
        _enteredTargets.isNotEmpty) {
      listsMatch = true;
      Iterator<_DragTargetState<T>> iterator = targets.iterator;
      for (int i = 0; i < _enteredTargets.length; i += 1) {
        iterator.moveNext();
        if (iterator.current != _enteredTargets[i]) {
          listsMatch = false;
          break;
        }
      }
    }

    // If everything's the same, bail early.
    if (!listsMatch) {
      // Leave old targets.
      _leaveAllEntered();

      // Enter new targets.
      _DragTargetState<T> newTarget =
          targets.firstWhere((_DragTargetState<T> target) {
        _enteredTargets.add(target);
        return target.didEnter(data, globalPosition);
      }, orElse: () => null);

      _activeTarget = newTarget;
    }

    // Update positions
    _enteredTargets.forEach((_DragTargetState<T> target) {
      target.updatePosition(
        data,
        globalPosition,
      );
    });
  }

  Iterable<_DragTargetState<T>> _getDragTargets(List<HitTestEntry> path) sync* {
    // Look for the RenderBoxes that corresponds to the hit target (the hit target
    // widgets build RenderMetaData boxes for us for this purpose).
    for (HitTestEntry entry in path) {
      if (entry.target is RenderMetaData) {
        RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is _DragTargetState<T>) {
          yield renderMetaData.metaData;
        }
      }
    }
  }

  void _leaveAllEntered() {
    for (int i = 0; i < _enteredTargets.length; i += 1) {
      _enteredTargets[i].didLeave(data);
    }
    _enteredTargets.clear();
  }

  void finishDrag(_DragEndKind endKind, [Velocity velocity]) {
    bool wasAccepted = false;
    if (endKind == _DragEndKind.dropped && _activeTarget != null) {
      _activeTarget.didDrop(data);
      wasAccepted = true;
      _enteredTargets.remove(_activeTarget);
    }
    _leaveAllEntered();
    _activeTarget = null;
    overlayKey.currentState.removeBuilder(_build);
    // TODO(ianh): consider passing _entry as well so the client can perform an animation.
    if (onDragEnd != null) {
      onDragEnd(velocity ?? Velocity.zero, _lastOffset, wasAccepted);
    }
  }

  Widget _build(BuildContext context) {
    RenderBox box = overlayKey.currentContext.findRenderObject();
    Point overlayTopLeft = box.localToGlobal(Point.origin);
    return new Positioned(
      left: _lastOffset.dx - overlayTopLeft.x,
      top: _lastOffset.dy - overlayTopLeft.y,
      child: new IgnorePointer(child: feedback),
    );
  }
}
