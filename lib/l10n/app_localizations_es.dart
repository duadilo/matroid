// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Matroid';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsTooltip => 'Configuración';

  @override
  String get navHome => 'Inicio';

  @override
  String get editorTitle => 'Editor';

  @override
  String get showcaseTitle => 'Galería';

  @override
  String get sectionAppearance => 'Apariencia';

  @override
  String get themeLabel => 'Tema';

  @override
  String get themeDescription => 'Elige la apariencia de la app';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get sectionLanguage => 'Idioma';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageDescription => 'Elige el idioma de la app';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get fallbackDialogTitle => 'Servidor local no disponible';

  @override
  String get fallbackDialogBody =>
      'El servidor Python local no pudo gestionar esta solicitud. ¿Deseas cambiar al servidor remoto?';

  @override
  String get buttonNo => 'No';

  @override
  String get buttonUseRemote => 'Usar remoto';

  @override
  String get buttonRetry => 'Reintentar';

  @override
  String get buttonRetryLocal => 'Reintentar local';

  @override
  String get statusStartingServer => 'Iniciando servidor local…';

  @override
  String statusRetrying(int attempt, int max) {
    return 'Reintentando… (intento $attempt de $max)';
  }

  @override
  String statusServerFailed(int max, String error) {
    return 'El servidor local falló después de $max intentos: $error';
  }

  @override
  String get featuresDisabledMessage =>
      'Funciones de Excel desactivadas — el servidor local falló y se rechazó el modo remoto.';

  @override
  String get buttonLoadFile => 'Cargar archivo';

  @override
  String get buttonProcess => 'Procesar';

  @override
  String get buttonExport => 'Exportar';

  @override
  String get buttonUnload => 'Liberar';

  @override
  String statusLoadingFile(String fileName) {
    return 'Cargando $fileName…';
  }

  @override
  String statusLoaded(String fileName) {
    return 'Cargado: $fileName';
  }

  @override
  String statusLoadError(String error) {
    return 'Error al cargar: $error';
  }

  @override
  String get statusProcessing => 'Procesando…';

  @override
  String statusProcessResult(String result) {
    return 'Resultado: $result';
  }

  @override
  String statusProcessError(String error) {
    return 'Error al procesar: $error';
  }

  @override
  String get statusExporting => 'Exportando…';

  @override
  String statusExported(int bytes) {
    return 'Exportado: $bytes bytes.';
  }

  @override
  String statusExportError(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get statusUnloadSent => 'Liberación enviada (sin esperar respuesta).';

  @override
  String modeLabel(String mode) {
    return 'Modo: $mode';
  }

  @override
  String get markdownTitle => 'Markdown';

  @override
  String get latexTitle => 'Matemáticas';

  @override
  String get buttonExportPdf => 'Exportar PDF';

  @override
  String get buttonExportHtml => 'Exportar HTML';

  @override
  String get chartsTitle => 'Gráficos';

  @override
  String get fontLabel => 'Fuente';

  @override
  String get fontDescription => 'Elige el tipo de letra';

  @override
  String get fontDefault => 'Predeterminada';

  @override
  String get fontOpenDyslexic => 'OpenDyslexic';

  @override
  String get fontLexend => 'Lexend';

  @override
  String get mediaTitle => 'Medios';

  @override
  String get buttonPickImage => 'Elegir imagen';

  @override
  String get buttonPickVideo => 'Elegir video';

  @override
  String get buttonTakePhoto => 'Tomar foto';

  @override
  String get buttonRecordVideo => 'Grabar video';

  @override
  String get mediaCameraUnavailable =>
      'Cámara no disponible en esta plataforma';

  @override
  String get mediaEmptyState =>
      'Sin medios seleccionados. Usa los botones para elegir o capturar medios.';

  @override
  String get chatTitle => 'Chat';

  @override
  String get chatEmptyState =>
      'Selecciona un proveedor y modelo, luego inicia una conversación.';

  @override
  String get chatInputHint => 'Mensaje…';

  @override
  String get chatNewConversation => 'Nueva conversación';

  @override
  String get chatSend => 'Enviar';

  @override
  String get chatAttach => 'Adjuntar archivo';

  @override
  String get chatToggleMarkdown => 'Alternar markdown';

  @override
  String chatErrorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get chatNoProviders =>
      'Sin proveedores configurados. Define las claves API en Configuración o como variables de entorno del servidor.';

  @override
  String get chatSystemPrompt => 'Indicación del sistema';

  @override
  String get sectionApiKeys => 'Claves API';

  @override
  String get apiKeyOpenai => 'Clave API de OpenAI';

  @override
  String get apiKeyAnthropic => 'Clave API de Anthropic';

  @override
  String get apiKeyGoogle => 'Clave API de Google AI';

  @override
  String get apiKeySaved => 'Guardada';

  @override
  String get apiKeyHint => 'Ingresa la clave API…';

  @override
  String get chatToolsEnabled => 'Búsqueda web activada';

  @override
  String get chatToolsDisabled => 'Búsqueda web desactivada';

  @override
  String chatSearching(String query) {
    return 'Buscando: $query';
  }

  @override
  String chatSearched(String query) {
    return 'Buscado: $query';
  }
}
