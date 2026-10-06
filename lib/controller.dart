import 'package:flutter/material.dart';
import 'package:flutter_test_app/av_socket.dart';

class SocketController extends StatefulWidget {
  final String handle;

  const SocketController({
    super.key,
    required this.handle,
  });

  @override
  State<SocketController> createState() => _SocketControllerState();
}

class _SocketControllerState extends State<SocketController> {
  AVSocket? av;

  final TextEditingController _controller = TextEditingController();

  String _message = "";
  int _messageResponseCode = 1;
  bool _connected = false;
  bool _showError = false;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();

    final connectionArgs = widget.handle.split(":");

    // Invalid address
    if (connectionArgs.length != 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, widget.handle);
        }
      });
      return;
    }

    final host = connectionArgs[0];
    final port = int.tryParse(connectionArgs[1]);

    // Invalid host or port
    if (host.isEmpty || port == null || port < 1 || port > 65535) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, widget.handle);
        }
      });
      return;
    }

    av = AVSocket(
      host: host,
      port: port,
    );

    _connect();
  }

  Future<void> _connect() async {
    final socket = av;

    if (socket == null) {
      return;
    }

    try {
      await socket.connect();

      if (!mounted) return;

      setState(() {
        _connected = true;
        _showError = false;
      });

      print("Connected to ${widget.handle}");
    } catch (e) {
      print("Connection failed: $e");

      if (!mounted) return;

      setState(() {
        _connected = false;
        _showError = true;
      });
    }
  }

  Future<void> _sendAVCue() async {
    final socket = av;

    if (socket == null) {
      return;
    }

    final input = _controller.text;

    if (input.isEmpty) {
      return;
    }

    if (!_connected) {
      setState(() {
        _showError = true;
      });
      return;
    }

    final message = _authenticated
        ? input
        : "0:$input";

    try {
      final response = await socket.messageAV(message);

      if (!mounted) return;

      print("AV response: $response");

      setState(() {
        // Auth success
        if (!_authenticated && response.trim() == "1") {
          _authenticated = true;
          _message = "Authentication successful.";
          _controller.clear();
          return;
        }

        // Auth Failed
        if (!_authenticated && response.trim() == "0") {
          _message = "Unsuccessful attempt.";
          return;
        }

        if (response.startsWith("1 ")) {
          _message = response.replaceFirst('1 ', "");
          _messageResponseCode = 1;
        } else {
          _message = response.replaceFirst('0 ', "");
          _messageResponseCode = 0;
        }
      });
    } catch (e) {
      print("Failed to send message: $e");

      if (!mounted) return;

      setState(() {
        _connected = false;
        _showError = true;
        _message = "Connection lost.";
      });
    }
  }

  Future<void> _shortcut302() async {
    _shortcutCue("302", "");
  }

  Future<void> _shortcut303() async {
    _shortcutCue("303", "");
  }

  Future<void> _shortcut206() async {
    _shortcutCue("206", "");
  }

  Future<void> _shortcut207() async {
    _shortcutCue("207", "");
  }

  Future<void> _shortcut406() async {
    _shortcutCue("406", "");
  }

  Future<void> _shortcut407() async {
    _shortcutCue("407", "");
  }

  Future<void> _shortcut202() async {
    await _shortcutCue("202", "");
    _shortcutCue("205", _message);
  }

  Future<void> _shortcut203() async {
    await _shortcutCue("203", "");
    _shortcutCue("205", _message);
  }

  Future<void> _shortcutCue(String shortcut, String args) async {
    if (!_connected || !_authenticated) {
      return;
    }

    try {
      final response = await av!.messageAV('$shortcut:$args');

      if (!mounted) return;

      setState(() {
        if (response.startsWith("1 ")) {
          _message = response.replaceFirst('1 ', "");
          _messageResponseCode = 1;
        } else {
          _message = response.replaceFirst('0 ', "");
          _messageResponseCode = 0;
        }
      });

      print("Shortcut response: $response");
    } catch (e) {
      print("Shortcut response error: $e");

      if (!mounted) return;

      setState(() {
        _connected = false;
        _showError = true;
        _message = "Connection lost.";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    av?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text("AudioVisualiser"),
      ),

      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                Text(
                  _message,
                  style: TextStyle(
                    color: _messageResponseCode == 1 ? Colors.black : Colors.red,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                Icon(
                  _connected
                      ? Icons.favorite
                      : Icons.heart_broken,

                  color: _connected
                      ? (_authenticated
                          ? Colors.green
                          : Colors.orange)
                      : Colors.red,

                  size: 64,
                ),

                const SizedBox(height: 16),

                Text(
                  _connected
                      ? "Connected to: ${widget.handle}"
                      : "Connecting to: ${widget.handle}",

                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: _controller,

                  obscureText: !_authenticated,

                  onSubmitted: (_) => _sendAVCue(),

                  decoration: InputDecoration(
                    labelText: _authenticated
                        ? "Type a cue"
                        : "Enter the password.",

                    errorText: _showError
                        ? "Failed to connect to AudioVisualiser"
                        : null,

                    border: const OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _connected
                      ? _sendAVCue
                      : null,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: _authenticated
                        ? Colors.green
                        : Colors.orange,

                    foregroundColor: Colors.white,
                  ),

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),

                    child: Text(
                      _authenticated
                          ? "Submit Visual Cue"
                          : "Enter the password.",
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                // -------------------------
                // SHORTCUTS
                // -------------------------

                if (_connected && _authenticated) ...[
                  const Text(
                    "Shortcuts",

                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 12),

                  ElevatedButton( onPressed: _shortcut202,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Next Visualiser"),),
                  ),
                  ElevatedButton( onPressed: _shortcut203,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Previous Visualiser"),),
                  ),
                  ElevatedButton( onPressed: _shortcut302,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Stop All Effects"),),
                  ),
                  ElevatedButton( onPressed: _shortcut303,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Start All Effects"),),
                  ),
                  ElevatedButton( onPressed: _shortcut206,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Stop Visualiser"),),
                  ),
                  ElevatedButton( onPressed: _shortcut207,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Start Visualiser"),),
                  ),
                  ElevatedButton( onPressed: _shortcut406,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Stop Music"),),
                  ),
                  ElevatedButton( onPressed: _shortcut407,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white,),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 24,vertical: 12,),child: Text("Start Music"),),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}