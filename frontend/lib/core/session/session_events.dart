import 'dart:async';

class SessionEvents {
  static final SessionEvents _instance = SessionEvents._internal();
  factory SessionEvents() => _instance;
  SessionEvents._internal();

  final _controller = StreamController<void>.broadcast();
  final _workspaceController = StreamController<void>.broadcast();

  Stream<void> get onSessionExpired => _controller.stream;
  Stream<void> get onWorkspaceAccessRevoked => _workspaceController.stream;

  void emitSessionExpired() {
    _controller.add(null);
  }

  void emitWorkspaceAccessRevoked() {
    _workspaceController.add(null);
  }

  void dispose() {
    _controller.close();
    _workspaceController.close();
  }
}
