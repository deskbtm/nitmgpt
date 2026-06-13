# Dart Signals State Management

> Reference for: Flutter Expert
> Load when: State management, Signals, reactivity, fine-grained updates

## Overview

Signals.dart is a fine-grained reactivity system for Dart (port of Preact Signals). **Pull-based**: computations run on access; unread signals never execute. Use for minimal rebuilds and derived state.

## Core API

```dart
import 'package:signals/signals.dart';

// Mutable state
final counter = signal(0);

// Read / write
print(counter.value);   // 0
counter.value = 1;

// Read without subscribing (no reaction)
final v = counter.peek();

// Derived state (lazy, memoized)
final doubled = computed(() => counter.value * 2);
print(doubled.value);   // 2

// Side effects (track dependencies, run when they change)
effect(() {
  print('Count: ${counter.value}');
});
counter.value = 2;   // logs: Count: 2

// Cleanup when effect is disposed
final dispose = effect(() {
  print(counter.value);
  return () => print('Effect destroyed');
});
dispose();
```

## Signal Options

```dart
// Force update (mark dependents dirty even if value equal)
counter.set(1, force: true);

// Auto-dispose when no listeners
final s = signal(0, autoDispose: true);
s.onDispose(() => print('Signal destroyed'));

// Manual dispose
s.dispose();
print(s.disposed);   // true
```

## Computed

```dart
final name = signal('Jane');
final surname = signal('Doe');
final fullName = computed(() => '${name.value} ${surname.value}');

print(fullName.value);   // "Jane Doe"
name.value = 'John';
print(fullName.value);   // "John Doe"

// Force re-evaluate
fullName.recompute();
```

- Only recomputes when **read** and dependencies changed.
- Use `computed` for derived values; avoid creating signals inside `computed`/`effect` or inside `build()`.

## Effect

```dart
effect(() {
  print(fullName.value);
});

// Return cleanup
final dispose = effect(() {
  subscribeToSomething();
  return () => unsubscribe();
});
dispose();
```

- Effects subscribe to every signal read inside the callback.
- Use `untracked(() => signal.value)` to read without subscribing.

## Flutter Usage

```dart
import 'package:signals/signals_flutter.dart';

// 1. Watch widget – rebuilds only when signal(s) used in builder change
final count = signal(0);

@override
Widget build(BuildContext context) {
  return Watch((context) => Text('${count.value}'));
}

// 2. Watch.builder (drop-in for Builder)
return Watch.builder(
  builder: (context) => Text('${count.value}'),
);

// 3. WatchBuilder with optional child
return WatchBuilder(
  builder: (context, child) => Row(
    children: [
      Text('${count.value}'),
      child!,
    ],
  ),
  child: const Icon(Icons.add),
);

// 4. Extension – watch in place (prefer Watch for dispose safety)
Text('Hello', style: TextStyle(fontSize: fontSize.watch(context)));

// 5. Stateful + SignalsMixin – auto-dispose signals when widget disposed
class _MyState extends State<MyWidget> with SignalsMixin {
  late final count = createSignal(0);
  late final isEven = createComputed(() => count.value.isEven);

  @override
  Widget build(BuildContext context) {
    return Text('$count');   // rebuilds when count changes
  }
}
```

## Selectors (fine-grained reactivity)

```dart
// Option A: computed from signal
final state = signal((a: 1, b: 2));
final a = computed(() => state.value.a);
return Watch((_) => Text('$a'));

// Option B: signal.select
final a = state.select((s) => s.value.a);
return Watch((_) => Text('$a'));
```

## Quick Reference

| API | Use case |
|-----|----------|
| `signal(initial)` | Mutable state |
| `computed(() => ...)` | Derived state, lazy + memoized |
| `effect(() => ...)` | Side effects, subscriptions |
| `signal.peek()` | Read without subscribing |
| `signal.set(v, force: true)` | Force dependents to update |
| `computed.recompute()` | Force recompute |
| `Watch((c) => widget)` | Rebuild widget when read signals change |
| `createSignal` / `createComputed` | In State with SignalsMixin, auto-dispose |
| `untracked(() => ...)` | Read signals without subscribing |

## Constraints

- **Do not** create signals inside `build()`, `effect`, or `computed` callbacks.
- Prefer `Watch` over `.watch(context)` so subscriptions are cleared on dispose.
- Use `computed` for derived data; use `effect` only for side effects (logging, sync, etc.).
- For widget-scoped state that must dispose with the widget, use `SignalsMixin` + `createSignal` / `createComputed`.
