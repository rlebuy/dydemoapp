import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailHandler {
  // ── Configuración SMTP desde .env ──────────────────────────────────────────
  static String get _smtpHost => dotenv.env['MAIL_HOST'] ?? '';
  static int get _smtpPort =>
      int.tryParse(dotenv.env['SMTP_PORT'] ?? '465') ?? 465;
  // SMTP_USER permite usar un usuario distinto al EMAIL (ej: solo "dyleger" sin dominio)
  static String get _username => dotenv.env['SMTP_USER'] ?? dotenv.env['EMAIL'] ?? '';
  static String get _password => dotenv.env['PASS'] ?? '';
  static String get _fromAddress => dotenv.env['EMAIL'] ?? '';
  static String get _fromName => dotenv.env['FROM_NAME'] ?? 'Dyleger Demo App';

  /// Puerto 465 → SSL siempre obligatorio.
  /// Para otros puertos, SMTP_SECURE del .env decide; sin él, false.
  static bool get _useSsl {
    if (_smtpPort == 465) return true;
    final val = dotenv.env['SMTP_SECURE'];
    if (val != null) return val.trim().toLowerCase() == 'true';
    return false;
  }

  /// Destinatarios: DESTINATION_EMAIL del .env.
  /// Si no está definido, cae en EMAIL (la cuenta SMTP).
  static List<String> get _destinationEmails {
    final dest = dotenv.env['DESTINATION_EMAIL'] ?? '';
    final list = dest
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (list.isNotEmpty) return list;
    // Fallback: enviar al mismo EMAIL configurado
    final self = _fromAddress;
    return self.isNotEmpty ? [self] : [];
  }

  // ── Servidor SMTP ──────────────────────────────────────────────────────────
  static SmtpServer get _smtpServer {
    final port = _smtpPort;
    final useSsl = _useSsl;
    final allowInsecure = !useSsl && port != 587;
    return SmtpServer(
      _smtpHost,
      port: port,
      ssl: useSsl,
      allowInsecure: allowInsecure,
      ignoreBadCertificate: true,
      username: _username,
      password: _password,
    );
  }

  // ── Método principal ───────────────────────────────────────────────────────
  /// Envía el contenido del formulario.
  /// - [recipientEmail] : correo ingresado por el usuario (va como destinatario).
  /// - [body]           : texto ingresado en el campo de mensaje.
  /// - [module]         : nombre del módulo (Facturas, Soporte, Envíos, Ventas).
  ///
  /// Retorna `true` si el envío fue exitoso, `false` si falló.
  static Future<bool> sendMessage({
    required String recipientEmail,
    required String body,
    required String module,
  }) async {
    // El correo tipado por el usuario ES el destinatario principal.
    // Si además hay DESTINATION_EMAIL en .env, se agrega como copia.
    final destinations = <String>[recipientEmail];
    final extra = _destinationEmails.where((e) => e != recipientEmail);
    destinations.addAll(extra);
    print('[MailHandler] host=$_smtpHost port=$_smtpPort ssl=$_useSsl user=$_username pass=$_password destinations=$destinations');
    if (destinations.isEmpty) {
      print('[MailHandler] Sin destinatarios configurados');
      return false;
    }

    final subject = 'Dyleger Demo App – $module';

    final htmlBody = '''
      <div style="font-family: Arial, sans-serif; padding: 20px;">
        <h2 style="color: #0D2B6B;">Dyleger Demo App – $module</h2>
        <hr>
        <p><strong>De:</strong> $recipientEmail</p>
        <hr>
        <h3 style="color: #333;">Mensaje</h3>
        <p style="white-space: pre-wrap;">$body</p>
        <hr>
        <p style="color: #999; font-size: 10px;">Desarrollado por Dyleger</p>
      </div>
    ''';

    final textBody = '''
Dyleger Demo App – $module
De: $recipientEmail

$body
''';

    final message = Message()
      ..from = Address(_fromAddress, _fromName)
      ..recipients.addAll(destinations)
      ..subject = subject
      ..text = textBody
      ..html = htmlBody;

    try {
      print('[MailHandler] Enviando...');
      await send(message, _smtpServer);
      print('[MailHandler] Enviado OK');
      return true;
    } on MailerException catch (e) {
      print('[MailHandler] MailerException: $e');
      for (final p in e.problems) {
        print('[MailHandler] Problema: ${p.code} - ${p.msg}');
      }
      return false;
    } catch (e, stack) {
      print('[MailHandler] Error inesperado: $e');
      print(stack);
      return false;
    }
  }
}
