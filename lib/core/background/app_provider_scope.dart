import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Own application state outside Flutter's frame-driven provider scheduler.
/// The UI inherits that state through a child container. A service-only engine
/// has no rendering surface, but auth changes, retries and streams must still
/// refresh on the Dart event loop. Both hosts continue to share one session.
class AppProviderScope extends StatefulWidget {
  const AppProviderScope({super.key, required this.child});
  final Widget child;

  @override
  State<AppProviderScope> createState() => _AppProviderScopeState();
}

class _AppProviderScopeState extends State<AppProviderScope> {
  late final ProviderContainer _runtime = ProviderContainer();
  late final ProviderContainer _ui = ProviderContainer(parent: _runtime);

  @override
  Widget build(BuildContext context) =>
      UncontrolledProviderScope(container: _ui, child: widget.child);

  @override
  void dispose() {
    _ui.dispose();
    _runtime.dispose();
    super.dispose();
  }
}
