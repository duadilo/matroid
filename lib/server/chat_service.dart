import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'server_base.dart';
import 'server_mode.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class ChatAttachment {
  const ChatAttachment({required this.mediaType, required this.data});

  final String mediaType;
  final String data; // base64

  factory ChatAttachment.fromBytes(String mediaType, Uint8List bytes) =>
      ChatAttachment(mediaType: mediaType, data: base64Encode(bytes));

  Map<String, dynamic> toJson() => {'media_type': mediaType, 'data': data};
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.role,
    required this.content,
    this.attachments = const [],
  });

  final String role;
  final String content;
  final List<ChatAttachment> attachments;

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
        if (attachments.isNotEmpty)
          'attachments': attachments.map((a) => a.toJson()).toList(),
      };
}

class ProviderModels {
  const ProviderModels(this.providers);

  final Map<String, List<String>> providers;

  factory ProviderModels.fromJson(Map<String, dynamic> json) {
    final raw = json['providers'] as Map<String, dynamic>;
    final providers = raw.map(
      (k, v) => MapEntry(k, (v as List).cast<String>()),
    );
    return ProviderModels(providers);
  }
}

// ---------------------------------------------------------------------------
// Chat stream event types
// ---------------------------------------------------------------------------

sealed class ChatStreamEvent {}

class TextToken extends ChatStreamEvent {
  TextToken(this.text);
  final String text;
}

class ToolUseEvent extends ChatStreamEvent {
  ToolUseEvent({required this.name, required this.input});
  final String name;
  final Map<String, dynamic> input;
}

class ToolResultEvent extends ChatStreamEvent {
  ToolResultEvent({required this.name});
  final String name;
}

// ---------------------------------------------------------------------------
// ChatService
// ---------------------------------------------------------------------------

class ChatService {
  ChatService({
    required this.mode,
    required this.server,
    http.Client? httpClient,
    String? remoteBaseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _remoteBaseOverride = remoteBaseUrl;

  ServerMode mode;
  ServerBase? server;
  final http.Client _httpClient;
  final String? _remoteBaseOverride;

  String get _base {
    if (mode == ServerMode.local && server != null) {
      return 'http://127.0.0.1:${server!.port}';
    }
    return _remoteBaseOverride ?? AppConfig.baseUrl;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<ProviderModels> fetchModels() async {
    final response = await _httpClient.get(Uri.parse('$_base/chat/models'));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
    return ProviderModels.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Stream<ChatStreamEvent> streamChat({
    required String provider,
    required String model,
    required List<ChatMessageModel> messages,
    String? baseUrl,
    String? systemPrompt,
    Map<String, String>? apiKeys,
    bool toolsEnabled = false,
  }) async* {
    final body = jsonEncode({
      'provider': provider,
      'model': model,
      'messages': messages.map((m) => m.toJson()).toList(),
      'base_url': ?baseUrl,
      if (systemPrompt != null && systemPrompt.isNotEmpty)
        'system_prompt': systemPrompt,
      if (apiKeys != null && apiKeys.isNotEmpty) 'api_keys': apiKeys,
      'tools_enabled': toolsEnabled,
    });

    final request = http.Request('POST', Uri.parse('$_base/chat/stream'))
      ..headers['Content-Type'] = 'application/json'
      ..body = body;

    final streamed = await _httpClient.send(request);
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final responseBody = await streamed.stream.bytesToString();
      throw Exception('HTTP ${streamed.statusCode}: $responseBody');
    }

    String? pendingEvent;

    await for (final line
        in streamed.stream.transform(utf8.decoder).transform(const LineSplitter())) {
      if (line.startsWith('event: ')) {
        pendingEvent = line.substring(7);
        continue;
      }
      if (line.startsWith('data: ')) {
        final payload = line.substring(6);
        if (payload == '[DONE]') return;

        if (pendingEvent == 'tool_use') {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          yield ToolUseEvent(
            name: json['name'] as String,
            input: (json['input'] as Map<String, dynamic>?) ?? {},
          );
          pendingEvent = null;
        } else if (pendingEvent == 'tool_result') {
          final json = jsonDecode(payload) as Map<String, dynamic>;
          yield ToolResultEvent(name: json['name'] as String);
          pendingEvent = null;
        } else if (pendingEvent == 'error') {
          pendingEvent = null;
          throw Exception(payload);
        } else {
          yield TextToken(payload.replaceAll(r'\n', '\n'));
          pendingEvent = null;
        }
      }
    }
  }
}
