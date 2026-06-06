import 'dart:async';

class SessionEvents {
  static final SessionEvents _instance = SessionEvents._internal();
  factory SessionEvents() => _instance;
  SessionEvents._internal();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;

  void emitSessionExpired() {
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
