import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math' show Random;

import 'package:logging/logging.dart';
import 'package:stream_channel/stream_channel.dart';

String randomSseClientId() {
  return Random().nextInt(1 << 31 + 1).toString();
}

class SseClient extends StreamChannelMixin<String> {
  late final StreamController<String> _incomingController;
  final _outgoingController = StreamController<String>();
  // final _logger = Logger('SseClient');
  final _onConnected = Completer();
  // int _lastMessageId = -1;
  // late final EventSource _eventSource;
  late String _serverUrl;
  final _client = http.Client();

  SseClient(String serverUrl) {
    var clientId = randomSseClientId();
    _serverUrl = '$serverUrl?sseClientId=$clientId';

    _incomingController = StreamController<String>.broadcast(
      onListen: () {
        var request = http.Request('GET', Uri.parse(_serverUrl))
          ..headers['Cache-Control'] = 'no-cache'
          ..headers['Accept'] = 'text/event-stream';

        _client.send(request).then(
          (response) {
            if (response.statusCode == 200) {
              response.stream
                  .transform(utf8.decoder)
                  .transform(LineSplitter())
                  .listen((line) {
                print(line);
                _incomingController.sink.add(line);
              });
            } else {
              _incomingController
                  .addError(Exception('Failed to connect to $_serverUrl'));
            }
          },
        );
      },
      onCancel: () {
        _incomingController.close();
      },
    );
  }

  Future<void> get onConnected => _onConnected.future;

  /// Add messages to this [StreamSink] to send them to the server.
  ///
  /// The message added to the sink has to be JSON encodable. Messages that fail
  /// to encode will be logged through a [Logger].
  @override
  StreamSink<String> get sink => _outgoingController.sink;

  /// [Stream] of messages sent from the server to this client.
  ///
  /// A message is a decoded JSON object.
  @override
  Stream<String> get stream => _incomingController.stream;

  void close() {
    // If the initial connection was never established. Add a listener so close
    // adds a done event to [sink].
    // if (!_onConnected.isCompleted) _outgoingController.stream.drain();
    _incomingController.close();
    _outgoingController.close();
  }
}
