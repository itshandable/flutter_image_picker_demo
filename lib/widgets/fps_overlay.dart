import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class FpsOverlay extends StatefulWidget {
  const FpsOverlay({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<FpsOverlay> createState() => _FpsOverlayState();
}

class _FpsOverlayState extends State<FpsOverlay> {
  static const Duration _sampleWindow = Duration(seconds: 1);
  static const Duration _jankThreshold = Duration(milliseconds: 17);

  final Queue<DateTime> _frameTimes = Queue<DateTime>();

  int _fps = 0;
  int _jankyFrames = 0;
  double _lastBuildMs = 0;
  double _lastRasterMs = 0;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_handleTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_handleTimings);
    super.dispose();
  }

  void _handleTimings(List<FrameTiming> timings) {
    if (!mounted || !widget.enabled || timings.isEmpty) {
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime windowStart = now.subtract(_sampleWindow);
    for (int i = 0; i < timings.length; i++) {
      _frameTimes.addLast(now);
    }
    while (_frameTimes.isNotEmpty && _frameTimes.first.isBefore(windowStart)) {
      _frameTimes.removeFirst();
    }

    final FrameTiming latest = timings.last;
    setState(() {
      _fps = _frameTimes.length;
      _lastBuildMs = _toMilliseconds(latest.buildDuration);
      _lastRasterMs = _toMilliseconds(latest.rasterDuration);
      _jankyFrames += timings
          .where((FrameTiming timing) => timing.totalSpan > _jankThreshold)
          .length;
    });
  }

  double _toMilliseconds(Duration duration) {
    return duration.inMicroseconds / Duration.microsecondsPerMillisecond;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 8,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.25,
                    fontFeatures: [],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('FPS: $_fps'),
                      Text('UI: ${_lastBuildMs.toStringAsFixed(1)}ms'),
                      Text('Raster: ${_lastRasterMs.toStringAsFixed(1)}ms'),
                      Text('Jank: $_jankyFrames'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
