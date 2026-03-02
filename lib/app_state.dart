import 'server/chat_service.dart';
import 'server/excel_service.dart';
import 'server/platform/server_platform.dart';

PythonServer? pythonServer;
ExcelService? excelService;
ChatService? chatService;
Future<String?>? binaryPathFuture;

/// Non-null while a server startup sequence is running.
/// Any concurrent HomeContent mount should await this instead of starting
/// a second sequence.
Future<void>? serverStartupFuture;
