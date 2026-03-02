import 'dart:math' show min;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../app_settings.dart';
import '../app_state.dart';
import '../l10n/app_localizations.dart';
import '../server/chat_service.dart';

// ---------------------------------------------------------------------------
// Private data classes
// ---------------------------------------------------------------------------

enum _ChatRole { user, assistant }

class _ChatMessage {
  _ChatMessage({
    required this.role,
    required this.content,
    this.attachments = const [],
    this.isStreaming = false,
  });

  final _ChatRole role;
  String content;
  final List<_Attachment> attachments;
  bool isStreaming;
  bool hasError = false;
}

class _Attachment {
  const _Attachment({
    required this.bytes,
    required this.fileName,
    required this.mediaType,
  });

  final List<int> bytes;
  final String fileName;
  final String mediaType;
}

// ---------------------------------------------------------------------------
// ChatContent
// ---------------------------------------------------------------------------

class ChatContent extends StatefulWidget {
  const ChatContent({super.key});

  @override
  State<ChatContent> createState() => _ChatContentState();
}

class _ChatContentState extends State<ChatContent> {
  final List<_ChatMessage> _messages = [];
  final List<_Attachment> _pendingAttachments = [];
  bool _isStreaming = false;
  ProviderModels? _models;
  String? _selectedProvider;
  String? _selectedModel;
  String _systemPrompt = '';
  bool _systemPromptExpanded = false;
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  String? _modelsError;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadModels() async {
    try {
      final models = await chatService!.fetchModels();
      if (!mounted) return;
      setState(() {
        _models = models;
        _modelsError = null;
        if (models.providers.isNotEmpty) {
          _selectedProvider ??= models.providers.keys.first;
          final providerModels = models.providers[_selectedProvider]!;
          if (_selectedModel == null ||
              !providerModels.contains(_selectedModel)) {
            _selectedModel = providerModels.first;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _modelsError = e.toString());
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && _pendingAttachments.isEmpty) return;
    if (_isStreaming) return;
    if (_selectedProvider == null || _selectedModel == null) return;

    final attachments = List<_Attachment>.from(_pendingAttachments);
    _inputController.clear();

    final userMsg = _ChatMessage(
      role: _ChatRole.user,
      content: text,
      attachments: attachments,
    );

    final assistantMsg = _ChatMessage(
      role: _ChatRole.assistant,
      content: '',
      isStreaming: true,
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(assistantMsg);
      _pendingAttachments.clear();
      _isStreaming = true;
    });

    _scrollToBottom();

    try {
      final chatMessages = _messages
          .where((m) => m != assistantMsg)
          .map((m) => ChatMessageModel(
                role: m.role == _ChatRole.user ? 'user' : 'assistant',
                content: m.content,
                attachments: m.attachments
                    .map((a) => ChatAttachment.fromBytes(
                        a.mediaType, a.bytes as dynamic))
                    .toList(),
              ))
          .toList();

      final apiKeys = AppSettings.instance.apiKeys;

      await for (final token in chatService!.streamChat(
        provider: _selectedProvider!,
        model: _selectedModel!,
        messages: chatMessages,
        systemPrompt: _systemPrompt,
        apiKeys: apiKeys.isNotEmpty ? apiKeys : null,
      )) {
        if (!mounted) return;
        setState(() {
          assistantMsg.content += token;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        assistantMsg.hasError = true;
        if (assistantMsg.content.isEmpty) {
          assistantMsg.content = e.toString();
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          assistantMsg.isStreaming = false;
          _isStreaming = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.any,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    final mediaType = _guessMediaType(file.name);
    if (!mounted) return;
    setState(() {
      _pendingAttachments.add(_Attachment(
        bytes: file.bytes!,
        fileName: file.name,
        mediaType: mediaType,
      ));
    });
  }

  String _guessMediaType(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  void _clearConversation() {
    setState(() {
      _messages.clear();
      _pendingAttachments.clear();
      _isStreaming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Toolbar
        _buildToolbar(l10n),
        // System prompt
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                labelText: l10n.chatSystemPrompt,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              onChanged: (v) => _systemPrompt = v,
            ),
          ),
          crossFadeState: _systemPromptExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        const Divider(height: 1),
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _modelsError != null
                          ? l10n.chatNoProviders
                          : l10n.chatEmptyState,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg =
                        _messages[_messages.length - 1 - index];
                    return _MessageBubble(
                      message: msg,
                      maxBubbleWidth: min(700, screenWidth * 0.85),
                    );
                  },
                ),
        ),
        // Pending attachments
        if (_pendingAttachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < _pendingAttachments.length; i++)
                  Chip(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 150),
                      child: Text(
                        _pendingAttachments[i].fileName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    onDeleted: () {
                      final idx = i;
                      setState(() => _pendingAttachments.removeAt(idx));
                    },
                  ),
              ],
            ),
          ),
        // Input bar
        _buildInputBar(l10n),
      ],
    );
  }

  Widget _buildToolbar(AppLocalizations l10n) {
    final providers = _models?.providers.keys.toList() ?? [];
    final models = (_selectedProvider != null)
        ? (_models?.providers[_selectedProvider] ?? [])
        : <String>[];
    final isNarrow = MediaQuery.of(context).size.width < 600;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: chip + action buttons
          Row(
            children: [
              Chip(label: Text(l10n.chatTitle)),
              const Spacer(),
              IconButton(
                icon: Icon(_systemPromptExpanded
                    ? Icons.expand_less
                    : Icons.expand_more),
                tooltip: l10n.chatSystemPrompt,
                onPressed: () => setState(
                    () => _systemPromptExpanded = !_systemPromptExpanded),
              ),
              IconButton(
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: l10n.chatNewConversation,
                onPressed: _clearConversation,
              ),
            ],
          ),
          // Selector row: provider + model dropdowns
          if (providers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProviderDropdown(providers),
                        const SizedBox(height: 4),
                        _buildModelDropdown(models),
                      ],
                    )
                  : Row(
                      children: [
                        Flexible(child: _buildProviderDropdown(providers)),
                        const SizedBox(width: 12),
                        Flexible(child: _buildModelDropdown(models)),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildProviderDropdown(List<String> providers) {
    return DropdownButton<String>(
      value: _selectedProvider,
      isExpanded: true,
      items: providers
          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _selectedProvider = v;
          final pModels = _models!.providers[v]!;
          _selectedModel = pModels.first;
        });
      },
      underline: const SizedBox.shrink(),
    );
  }

  Widget _buildModelDropdown(List<String> models) {
    return DropdownButton<String>(
      value: _selectedModel,
      isExpanded: true,
      items: models
          .map((m) => DropdownMenuItem(
                value: m,
                child: Text(m, overflow: TextOverflow.ellipsis),
              ))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _selectedModel = v);
      },
      underline: const SizedBox.shrink(),
    );
  }

  Widget _buildInputBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: l10n.chatAttach,
            onPressed: _pickFile,
          ),
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: InputDecoration(
                hintText: l10n.chatInputHint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: l10n.chatSend,
            onPressed: _isStreaming ? null : _sendMessage,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Message bubble
// ---------------------------------------------------------------------------

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({
    required this.message,
    required this.maxBubbleWidth,
  });

  final _ChatMessage message;
  final double maxBubbleWidth;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _showMarkdown = true;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;
    final isUser = msg.role == _ChatRole.user;
    final theme = Theme.of(context);

    Widget content;
    if (isUser) {
      content = SelectableText(msg.content);
    } else if (msg.isStreaming && msg.content.isEmpty) {
      content = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_showMarkdown) {
      content = MarkdownBody(
        data: msg.content,
        selectable: true,
      );
    } else {
      content = SelectableText(msg.content);
    }

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: widget.maxBubbleWidth),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isUser
            ? null
            : Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 0.5,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          content,
          if (!isUser && !msg.isStreaming && msg.content.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(
                  _showMarkdown ? Icons.code : Icons.article,
                  size: 16,
                ),
                tooltip: AppLocalizations.of(context)!.chatToggleMarkdown,
                onPressed: () =>
                    setState(() => _showMarkdown = !_showMarkdown),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 28, minHeight: 28),
              ),
            ),
          if (msg.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Error',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble,
      ),
    );
  }
}
