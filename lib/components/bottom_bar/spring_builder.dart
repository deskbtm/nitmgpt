import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

abstract final class GlassSpring {
  static SpringDescription bouncy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.3 + extraBounce,
      );

  static SpringDescription snappy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.15 + extraBounce,
      );

  static SpringDescription smooth({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.0 + extraBounce,
      );

  static SpringDescription interactive({
    Duration duration = const Duration(milliseconds: 150),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.14 + extraBounce,
      );
}

class SingleSpringController extends ChangeNotifier {
  SingleSpringController({
    required TickerProvider vsync,
    required SpringDescription spring,
    double initialValue = 0.0,
    double? lowerBound,
    double? upperBound,
  })  : _spring = spring,
        _value = initialValue,
        _lowerBound = lowerBound,
        _upperBound = upperBound {
    _ticker = vsync.createTicker(_tick);
  }

  SpringDescription _spring;
  double _value;
  double _tickerElapsed = 0.0;
  double _simStartTime = 0.0;
  double _target = 0.0;
  SpringSimulation? _sim;
  late final Ticker _ticker;

  final double? _lowerBound;
  final double? _upperBound;

  double get value => _value;

  double get velocity {
    final sim = _sim;
    if (sim == null) return 0.0;
    final t = (_tickerElapsed - _simStartTime).clamp(0.0, double.infinity);
    return sim.dx(t);
  }

  SpringDescription get spring => _spring;
  set spring(SpringDescription value) {
    if (_spring == value) return;
    _spring = value;
    if (_ticker.isActive) _startSim(target: _target, fromVelocity: velocity);
  }

  void animateTo(double target, {double? fromVelocity}) {
    _target = _clamp(target);
    _startSim(target: _target, fromVelocity: fromVelocity ?? velocity);
  }

  void setValue(double value) {
    _ticker.stop();
    _sim = null;
    _value = _clamp(value);
    _tickerElapsed = 0.0;
    _simStartTime = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _clamp(double v) {
    if (_lowerBound != null && v < _lowerBound!) return _lowerBound!;
    if (_upperBound != null && v > _upperBound!) return _upperBound!;
    return v;
  }

  void _startSim({required double target, required double fromVelocity}) {
    _sim = SpringSimulation(
      _spring,
      _value,
      target,
      fromVelocity,
    );
    if (!_ticker.isActive) {
      _tickerElapsed = 0.0;
      _simStartTime = 0.0;
      _ticker.start();
    } else {
      _simStartTime = _tickerElapsed;
    }
  }

  void _tick(Duration elapsed) {
    _tickerElapsed = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final simElapsed =
        (_tickerElapsed - _simStartTime).clamp(0.0, double.infinity);
    final sim = _sim;
    if (sim == null) {
      _ticker.stop();
      return;
    }

    _value = _clamp(sim.x(simElapsed));

    if (sim.isDone(simElapsed)) {
      _value = _clamp(_target);
      _sim = null;
      _ticker.stop();
    }
    notifyListeners();
  }
}

typedef SpringWidgetBuilder = Widget Function(
  BuildContext context,
  double value,
  Widget? child,
);

class SpringBuilder extends StatefulWidget {
  const SpringBuilder({
    required this.value,
    required this.spring,
    required this.builder,
    this.child,
    super.key,
  });

  final double value;
  final SpringDescription spring;
  final SpringWidgetBuilder builder;
  final Widget? child;

  @override
  State<SpringBuilder> createState() => _SpringBuilderState();
}

class _SpringBuilderState extends State<SpringBuilder>
    with SingleTickerProviderStateMixin {
  late final SingleSpringController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SingleSpringController(
      vsync: this,
      spring: widget.spring,
      initialValue: widget.value,
    );
  }

  @override
  void didUpdateWidget(SpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spring != oldWidget.spring) {
      _ctrl.spring = widget.spring;
    }
    if (widget.value != oldWidget.value) {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _ctrl.setValue(widget.value);
      } else {
        _ctrl.animateTo(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, child) => widget.builder(context, _ctrl.value, child),
      child: widget.child,
    );
  }
}

typedef VelocitySpringWidgetBuilder = Widget Function(
  BuildContext context,
  double value,
  double velocity,
  Widget? child,
);

class VelocitySpringBuilder extends StatefulWidget {
  const VelocitySpringBuilder({
    required this.value,
    required this.springWhenActive,
    required this.springWhenReleased,
    required this.builder,
    this.active = true,
    this.child,
    super.key,
  });

  final double value;
  final SpringDescription springWhenActive;
  final SpringDescription springWhenReleased;
  final bool active;
  final VelocitySpringWidgetBuilder builder;
  final Widget? child;

  @override
  State<VelocitySpringBuilder> createState() => _VelocitySpringBuilderState();
}

class _VelocitySpringBuilderState extends State<VelocitySpringBuilder>
    with SingleTickerProviderStateMixin {
  late final SingleSpringController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SingleSpringController(
      vsync: this,
      spring: _currentSpring,
      initialValue: widget.value,
    );
  }

  SpringDescription get _currentSpring =>
      widget.active ? widget.springWhenActive : widget.springWhenReleased;

  @override
  void didUpdateWidget(VelocitySpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final springChanged = widget.active != oldWidget.active ||
        widget.springWhenActive != oldWidget.springWhenActive ||
        widget.springWhenReleased != oldWidget.springWhenReleased;
    if (springChanged) {
      _ctrl.spring = _currentSpring;
    }
    if (widget.value != oldWidget.value) {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _ctrl.setValue(widget.value);
      } else {
        _ctrl.animateTo(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, child) =>
          widget.builder(context, _ctrl.value, _ctrl.velocity, child),
      child: widget.child,
    );
  }
}
