import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AVSocket {
  Socket? _socket;

  final String host;
  final int port;

  StreamSubscription<List<int>>? _socketSubscription;

  final StreamController<String> _responses =
      StreamController<String>.broadcast();

  AVSocket({
    required this.host,
    required this.port,
  });

  bool get isConnected => _socket != null;

  Future<void> connect() async {
    if (isConnected) return;

    _socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );

    print('Connected to $host:$port');

    // One permanent listener for this socket.
    _socketSubscription = _socket!.listen(
      (data) {
        final response = utf8.decode(data);

        print('Received from server: $response');

        _responses.add(response);
      },
      onError: (error) {
        print('Socket error: $error');
      },
      onDone: () {
        print('Server disconnected');

        _socket = null;
      },
    );
  }

  Future<String> _send(String message) async {
    if (_socket == null) {
      throw StateError('Socket is not connected');
    }

    final completer = Completer<String>();

    late StreamSubscription<String> responseSubscription;

    responseSubscription = _responses.stream.listen(
      (response) {
        if (!completer.isCompleted) {
          completer.complete(response);
          responseSubscription.cancel();
        }
      },
    );

    print('Sending to server: $message');

    // IMPORTANT:
    // No \n because your JUCE server uses raw TCP messages.
    _socket!.write(message);

    try {
      return await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            'Timed out waiting for server response',
          );
        },
      );
    } finally {
      await responseSubscription.cancel();
    }
  }

  Future<String> authenticate(String password) async {
    // Your Python/JUCE server currently uses:
    //
    // COMMAND_AUTH = 0
    //
    // Therefore:
    //
    // 0:password

    final response = await _send(
      '0:$password',
    );

    if (response.trim() != '0') {
      throw Exception('Authentication failed: $response');
    }

    print('Successfully authenticated');

    return response;
  }

  Future<String> messageAV(String message) async {
    if (_socket == null) {
      throw StateError('Socket is not connected');
    }

    // Your GlobalSocketHandler expects:
    //
    // commandID:body
    //
    // e.g.
    //
    // 42:hello

    return await _send(message);
  }

  Future<void> disconnect() async {
    await _socketSubscription?.cancel();
    await _responses.close();

    await _socket?.close();

    _socketSubscription = null;
    _socket = null;
  }
}