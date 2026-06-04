import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'mail_handler.dart';
import 'splash_screen.dart';

// ── Notifier global de tema ──────────────────────────────────────────────────
final _themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

// ── Botón de cambio de tema ──────────────────────────────────────────────────
class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return IconButton(
          tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () {
            _themeNotifier.value =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
        );
      },
    );
  }
}

// ── Fondo reutilizable ──────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  final Widget child;
  const _Background({required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/wallpaper.png', fit: BoxFit.cover),
            Container(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.35),
            ),
            child,
          ],
        );
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Rednet Demo App',
        debugShowCheckedModeBanner: false,
        themeMode: mode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.dark,
          ),
          brightness: Brightness.dark,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rednet Demo App'),
        backgroundColor: const Color(0xFF616161).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: const [_ThemeToggle()],
      ),
      body: _Background(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MenuButton(
                label: 'Facturas',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FacturasPage()),
              ),
            ),
            const SizedBox(height: 24),
            _MenuButton(
              label: 'Soporte',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SoportePage()),
              ),
            ),
            const SizedBox(height: 24),
            _MenuButton(
              label: 'Envios',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EnviosPage()),
              ),
            ),
            const SizedBox(height: 24),
              _MenuButton(
                label: 'Ventas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VentasPage()),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class FacturasPage extends StatefulWidget {
  const FacturasPage({super.key});

  @override
  State<FacturasPage> createState() => _FacturasPageState();
}

class _FacturasPageState extends State<FacturasPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _sending = false;

  bool _validEmail(String v) {
    return RegExp(r'^[\w.+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim());
  }

  void _checkEmail() {
    final v = _emailController.text.trim();
    setState(() {
      if (v.isEmpty) {
        _emailError = 'Ingresa un correo electrónico';
      } else if (!_validEmail(v)) {
        _emailError = 'Formato de correo no válido';
      } else {
        _emailError = null;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redent Demo App'),
        backgroundColor: const Color(0xFF616161).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [_ThemeToggle()],
      ),
      body: _Background(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hPad = (constraints.maxWidth * 0.08).clamp(16.0, 40.0);
            final vPad = (constraints.maxHeight * 0.05).clamp(16.0, 48.0);
            final btnWidth = (constraints.maxWidth * 0.33).clamp(100.0, 160.0);
            final btnHeight = (constraints.maxHeight * 0.065).clamp(44.0, 56.0);
            final titleSize = (constraints.maxWidth * 0.05).clamp(15.0, 22.0);
            return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: _themeNotifier,
            builder: (_, mode, __) {
              final isDark = mode == ThemeMode.dark;
              final fieldFill = isDark ? Colors.black.withOpacity(0.40) : Colors.white.withOpacity(0.68);
              final fieldText = isDark ? Colors.white : Colors.black87;
              final hintColor = isDark ? Colors.white.withOpacity(0.4) : Colors.black45;
              final borderColor = isDark ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.15);
              final focusBorder = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0D2B6B);
              final iconColor = isDark ? Colors.white.withOpacity(0.7) : Colors.black54;
              final btnSendBg = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF0D2B6B);
              final btnSendFg = isDark ? const Color(0xFF0D2B6B) : Colors.white;
              final btnCancelBg = isDark ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.55);
              final btnCancelFg = isDark ? Colors.white : Colors.black87;
              final btnCancelSide = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.15);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modulo de Envio de Facturas',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.85),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ── Campo de correo ──────────────────────────────────
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    onChanged: (_) { if (_emailError != null) _checkEmail(); },
                    onEditingComplete: _checkEmail,
                    style: TextStyle(color: fieldText),
                    decoration: InputDecoration(
                      hintText: 'Correo electrónico',
                      hintStyle: TextStyle(color: hintColor),
                      errorText: _emailError,
                      errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
                      filled: true,
                      fillColor: fieldFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: focusBorder, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF8A80)),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(Icons.email_outlined, color: iconColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ── Campo de texto principal ─────────────────────────
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      spellCheckConfiguration: const SpellCheckConfiguration(),
                      style: TextStyle(color: fieldText),
                      decoration: InputDecoration(
                        hintText: 'Escribe aquí...',
                        hintStyle: TextStyle(color: hintColor),
                        filled: true,
                        fillColor: fieldFill,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: focusBorder, width: 1.5),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: btnWidth,
                        height: btnHeight,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnCancelBg,
                            foregroundColor: btnCancelFg,
                            elevation: 0,
                            side: BorderSide(color: btnCancelSide),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SizedBox(
                        width: btnWidth,
                        height: btnHeight,
                        child: ElevatedButton(
                          onPressed: _sending ? null : () async {
                            _checkEmail();
                            if (_emailError != null) return;
                            setState(() => _sending = true);
                            final body = _controller.text.trim();
                            final ok = await MailHandler.sendMessage(
                              recipientEmail: _emailController.text.trim(),
                              body: body,
                              module: 'Facturas',
                            );
                            if (!context.mounted) return;
                            setState(() => _sending = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Mensaje enviado' : 'Error al enviar'),
                                backgroundColor: ok ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            if (ok) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnSendBg,
                            foregroundColor: btnSendFg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _sending
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Enviar', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
          },
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _MenuButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final btnWidth = (size.width * 0.72).clamp(200.0, 340.0);
    final btnHeight = (size.height * 0.065).clamp(44.0, 64.0);
    final fontSize = (size.width * 0.038).clamp(13.0, 18.0);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, mode, __) {
        final isDark = mode == ThemeMode.dark;
        return SizedBox(
          width: btnWidth,
          height: btnHeight,
          child: ElevatedButton(
            onPressed: onTap ?? () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white : const Color(0xFF0D2B6B),
              foregroundColor: isDark ? const Color(0xFF0D2B6B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }
}

// ── Página reutilizable ──────────────────────────────────────────────────────
class _ModulePage extends StatefulWidget {
  final String titulo;
  const _ModulePage({required this.titulo});

  @override
  State<_ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends State<_ModulePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _sending = false;

  static final RegExp _emailRx = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  bool _validEmail(String v) => _emailRx.hasMatch(v.trim());

  void _checkEmail() {
    setState(() {
      final v = _emailController.text.trim();
      if (v.isEmpty) {
        _emailError = 'Ingresa tu correo';
      } else if (!_validEmail(v)) {
        _emailError = 'Correo no válido';
      } else {
        _emailError = null;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rednet Demo App'),
        backgroundColor: const Color(0xFF616161).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [_ThemeToggle()],
      ),
      body: _Background(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hPad = (constraints.maxWidth * 0.08).clamp(16.0, 40.0);
            final vPad = (constraints.maxHeight * 0.05).clamp(16.0, 48.0);
            final btnWidth = (constraints.maxWidth * 0.33).clamp(100.0, 160.0);
            final btnHeight = (constraints.maxHeight * 0.065).clamp(44.0, 56.0);
            final titleSize = (constraints.maxWidth * 0.05).clamp(15.0, 22.0);
            return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: _themeNotifier,
          builder: (_, mode, __) {
            final isDark = mode == ThemeMode.dark;
            final fieldFill = isDark ? Colors.black.withOpacity(0.40) : Colors.white.withOpacity(0.68);
            final fieldText = isDark ? Colors.white : Colors.black87;
            final hintColor = isDark ? Colors.white.withOpacity(0.4) : Colors.black45;
            final borderColor = isDark ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.15);
            final focusBorder = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0D2B6B);
            final btnSendBg = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF0D2B6B);
            final btnSendFg = isDark ? const Color(0xFF0D2B6B) : Colors.white;
            final btnCancelBg = isDark ? Colors.white.withOpacity(0.18) : Colors.white.withOpacity(0.55);
            final btnCancelFg = isDark ? Colors.white : Colors.black87;
            final btnCancelSide = isDark ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.15);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.titulo,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.85),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // ── Campo de correo ──────────────────────────────────
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onChanged: (_) { if (_emailError != null) _checkEmail(); },
                  onEditingComplete: _checkEmail,
                  style: TextStyle(color: fieldText),
                  decoration: InputDecoration(
                    hintText: 'Correo electrónico',
                    hintStyle: TextStyle(color: hintColor),
                    errorText: _emailError,
                    errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
                    filled: true,
                    fillColor: fieldFill,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: focusBorder, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF8A80)),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.5),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    prefixIcon: Icon(Icons.email_outlined, color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Campo de texto principal ─────────────────────────
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    spellCheckConfiguration: const SpellCheckConfiguration(),
                    style: TextStyle(color: fieldText),
                    decoration: InputDecoration(
                      hintText: 'Escribe aquí...',
                      hintStyle: TextStyle(color: hintColor),
                      filled: true,
                      fillColor: fieldFill,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: focusBorder, width: 1.5),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: btnWidth,
                      height: btnHeight,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnCancelBg,
                          foregroundColor: btnCancelFg,
                          elevation: 0,
                          side: BorderSide(color: btnCancelSide),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    SizedBox(
                      width: btnWidth,
                      height: btnHeight,
                      child: ElevatedButton(
                        onPressed: _sending ? null : () async {
                          _checkEmail();
                          if (_emailError != null) return;
                          setState(() => _sending = true);
                          final body = _controller.text.trim();
                          final ok = await MailHandler.sendMessage(
                            recipientEmail: _emailController.text.trim(),
                            body: body,
                            module: widget.titulo,
                          );
                          if (!context.mounted) return;
                          setState(() => _sending = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok ? 'Mensaje enviado' : 'Error al enviar'),
                              backgroundColor: ok ? Colors.green : Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          if (ok) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnSendBg,
                          foregroundColor: btnSendFg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _sending
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Enviar', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
          },
        ),
      ),
    );
  }
}

class SoportePage extends StatelessWidget {
  const SoportePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ModulePage(titulo: 'Modulo de Soporte');
}

class EnviosPage extends StatelessWidget {
  const EnviosPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ModulePage(titulo: 'Modulo de Envios');
}

class VentasPage extends StatelessWidget {
  const VentasPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ModulePage(titulo: 'Modulo de Ventas');
}
