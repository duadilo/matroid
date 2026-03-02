import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:matroid/server/chat_service.dart';
import 'package:matroid/server/server_mode.dart';

void main() {
  const base = 'http://test-server';

  group('fetchModels', () {
    test('parses provider map correctly', () async {
      final client = MockClient((req) async => http.Response(
            jsonEncode({
              'providers': {
                'openai': ['gpt-4o', 'gpt-4o-mini'],
                'anthropic': ['claude-sonnet-4-20250514'],
              }
            }),
            200,
          ));

      final service = ChatService(
        mode: ServerMode.remote,
        server: null,
        httpClient: client,
        remoteBaseUrl: base,
      );

      final models = await service.fetchModels();
      expect(models.providers.keys, containsAll(['openai', 'anthropic']));
      expect(models.providers['openai'], ['gpt-4o', 'gpt-4o-mini']);
      expect(
          models.providers['anthropic'], ['claude-sonnet-4-20250514']);
    });

    test('throws on non-2xx', () async {
      final client =
          MockClient((req) async => http.Response('not found', 404));

      final service = ChatService(
        mode: ServerMode.remote,
        server: null,
        httpClient: client,
        remoteBaseUrl: base,
      );

      expect(() => service.fetchModels(), throwsException);
    });
  });

  group('streamChat', () {
    test('yields tokens from SSE data lines', () async {
      final client = _StreamMockClient([
        'data: Hello\n',
        '\n',
        'data:  world\n',
        '\n',
        'data: [DONE]\n',
        '\n',
      ]);

      final service = ChatService(
        mode: ServerMode.remote,
        server: null,
        httpClient: client,
        remoteBaseUrl: base,
      );

      final tokens = await service
          .streamChat(
            provider: 'openai',
            model: 'gpt-4o',
            messages: [
              const ChatMessageModel(role: 'user', content: 'Hi')
            ],
          )
          .toList();

      expect(tokens, ['Hello', ' world']);
    });

    test('terminates on [DONE]', () async {
      final client = _StreamMockClient([
        'data: token1\n',
        '\n',
        'data: [DONE]\n',
        '\n',
        'data: should-not-appear\n',
        '\n',
      ]);

      final service = ChatService(
        mode: ServerMode.remote,
        server: null,
        httpClient: client,
        remoteBaseUrl: base,
      );

      final tokens = await service
          .streamChat(
            provider: 'openai',
            model: 'gpt-4o',
            messages: [
              const ChatMessageModel(role: 'user', content: 'Hi')
            ],
          )
          .toList();

      expect(tokens, ['token1']);
    });

    test('unescapes \\n in tokens', () async {
      final client = _StreamMockClient([
        'data: line1\\nline2\n',
        '\n',
        'data: [DONE]\n',
        '\n',
      ]);

      final service = ChatService(
        mode: ServerMode.remote,
        server: null,
        httpClient: client,
        remoteBaseUrl: base,
      );

      final tokens = await service
          .streamChat(
            provider: 'openai',
            model: 'gpt-4o',
            messages: [
              const ChatMessageModel(role: 'user', content: 'Hi')
            ],
          )
          .toList();

      expect(tokens, ['line1\nline2']);
    });
  });
}

// ---------------------------------------------------------------------------
// Helper: mock HTTP client that returns a StreamedResponse
// ---------------------------------------------------------------------------

class _StreamMockClient extends http.BaseClient {
  _StreamMockClient(this._lines);

  final List<String> _lines;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final stream = Stream.fromIterable(
      _lines.map((l) => utf8.encode(l)),
    );
    return http.StreamedResponse(
      http.ByteStream(stream),
      200,
    );
  }
}
