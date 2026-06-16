import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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
        title: 'Rednet',
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    final user = _userController.text.trim();
    final pass = _passController.text;
    if (user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Ingresa usuario y contraseña');
      return;
    }
    final apiUrl = dotenv.env['API'];
    if (apiUrl == null || apiUrl.isEmpty) {
      setState(() => _error = 'API no configurada');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await http
          .get(Uri.parse('$apiUrl?action=usuarios'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw Exception('bad status');
      final decoded = jsonDecode(response.body);
      if (decoded is! List) throw Exception('bad payload');
      final ok = decoded.any((row) {
        if (row is! Map) return false;
        final u = (row['user'] ?? '').toString().trim();
        final p = (row['password'] ?? '').toString();
        return u == user && p == pass;
      });
      if (!mounted) return;
      if (!ok) {
        setState(() => _error = 'Usuario o contraseña incorrectos');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyHomePage()),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo validar el login');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _Background(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: _themeNotifier,
              builder: (_, mode, __) {
                final isDark = mode == ThemeMode.dark;
                final fill = isDark ? Colors.black.withOpacity(0.55) : Colors.white.withOpacity(0.88);
                final text = isDark ? Colors.white : Colors.black87;
                final hint = isDark ? Colors.white.withOpacity(0.65) : Colors.black54;
                final border = isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2);
                final focus = isDark ? Colors.white : const Color(0xFF0D2B6B);
                final btnBg = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0D2B6B);
                final btnFg = isDark ? const Color(0xFF0D2B6B) : Colors.white;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Ingreso',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _userController,
                      style: TextStyle(color: text),
                      decoration: InputDecoration(
                        hintText: 'Usuario',
                        hintStyle: TextStyle(color: hint),
                        filled: true,
                        fillColor: fill,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focus, width: 1.5)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passController,
                      obscureText: _obscure,
                      style: TextStyle(color: text),
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        hintText: 'Contraseña',
                        hintStyle: TextStyle(color: hint),
                        filled: true,
                        fillColor: fill,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focus, width: 1.5)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: hint),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(_error!, style: const TextStyle(color: Color(0xFFFF8A80))),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(backgroundColor: btnBg, foregroundColor: btnFg),
                        child: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Ingresar'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Recuperar contraseña'),
                            content: const Text(
                              'Para recuperar su contraseña, por favor comuníquese con:\n\ndyleger@rednetchile.cl',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cerrar'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text(
                        '¿Olvidó su contraseña?',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
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
        title: const Text('Rednet'),
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

class FacturasPage extends StatelessWidget {
  const FacturasPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ModulePage(titulo: 'Facturas', action: 'facturas');
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
  final String? action;
  const _ModulePage({required this.titulo, this.action});

  @override
  State<_ModulePage> createState() => _ModulePageState();
}

class _ModulePageState extends State<_ModulePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;
  bool _sending = false;
  bool _loadingItems = false;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _selectedItem;

  static final RegExp _emailRx = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

  bool _validEmail(String v) => _emailRx.hasMatch(v.trim());

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (widget.action == null || widget.action!.isEmpty) return;
    final apiUrl = dotenv.env['API'];
    if (apiUrl == null || apiUrl.isEmpty) return;
    setState(() => _loadingItems = true);
    try {
      final response = await http
          .get(Uri.parse('$apiUrl?action=${widget.action}'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _items = decoded.whereType<Map<String, dynamic>>().toList();
          });
        }
      }
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

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
        title: const Text('Rednet'),
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
                if (widget.action != null) ...[
                  SizedBox(
                    height: 170,
                    child: Container(
                      decoration: BoxDecoration(
                        color: fieldFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: _loadingItems
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : _items.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Text('Sin datos disponibles', style: TextStyle(color: hintColor)),
                                )
                              : ListView.separated(
                                  itemCount: _items.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                                  itemBuilder: (_, index) {
                                    final item = _items[index];
                                    final primary = (item['codigo'] ??
                                            item['codigo_ticket'] ??
                                            item['codigo_envio'] ??
                                            item['valor'] ??
                                            item['tipo_venta'] ??
                                            item['tipo_soporte'] ??
                                            item['objeto'] ??
                                            '')
                                        .toString();
                                    final secondary = (item['monto'] ??
                                            item['tipo_soporte'] ??
                                            item['objeto'] ??
                                            item['tipo_venta'] ??
                                            item['estado'] ??
                                            '')
                                        .toString();
                                    final selected = identical(_selectedItem, item);
                                    return ListTile(
                                      selected: selected,
                                      selectedTileColor: focusBorder.withOpacity(0.15),
                                      title: Text(primary, style: TextStyle(color: selected ? focusBorder : fieldText)),
                                      subtitle: Text(secondary, style: TextStyle(color: hintColor)),
                                      onTap: () {
                                        final email = (item['correo'] ?? '').toString();
                                        setState(() {
                                          _selectedItem = item;
                                          _emailController.text = email;
                                          _controller.text = secondary.isNotEmpty ? secondary : primary;
                                          _emailError = null;
                                        });
                                      },
                                    );
                                  },
                                ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
                          final subject = _selectedItem == null
                              ? widget.titulo
                              : (_selectedItem!['codigo'] ??
                                      _selectedItem!['codigo_ticket'] ??
                                      _selectedItem!['codigo_envio'] ??
                                      _selectedItem!['valor'] ??
                                      widget.titulo)
                                  .toString();
                          final ok = await MailHandler.sendMessage(
                            recipientEmail: _emailController.text.trim(),
                            body: body,
                            module: widget.titulo,
                            subject: '$widget.titulo: $subject',
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

class _SoporteTicket {
  final String codigo;
  final String tipo;
  final String correo;
  final String estado;
  const _SoporteTicket({
    required this.codigo,
    required this.tipo,
    required this.correo,
    required this.estado,
  });

  factory _SoporteTicket.fromJson(Map<String, dynamic> json) => _SoporteTicket(
    codigo: json['codigo_ticket']?.toString() ?? '',
    tipo: json['tipo_soporte']?.toString() ?? '',
    correo: json['correo']?.toString() ?? '',
    estado: (json['estado']?.toString().trim().isNotEmpty == true)
        ? json['estado']?.toString() ?? 'Abierto'
        : 'Abierto',
  );
}

class SoportePage extends StatefulWidget {
  const SoportePage({super.key});
  @override
  State<SoportePage> createState() => _SoportePageState();
}

class _SoportePageState extends State<SoportePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();
  final TextEditingController _comentarioController = TextEditingController();
  final List<String> _estados = const ['Abierto', 'En Progreso', 'En Espera', 'Resuelto', 'Cerrado'];

  List<_SoporteTicket> _tickets = [];
  _SoporteTicket? _selected;
  String _estadoSeleccionado = 'Abierto';
  String? _emailError;
  bool _loadingTickets = false;
  bool _savingTracking = false;
  bool _sendingMail = false;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

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

  Future<void> _loadTickets() async {
    final apiUrl = dotenv.env['API'];
    if (apiUrl == null || apiUrl.isEmpty) return;
    setState(() => _loadingTickets = true);
    try {
      final response = await http.get(Uri.parse('$apiUrl?action=soportes')).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          setState(() {
            _tickets = decoded
                .whereType<Map<String, dynamic>>()
                .map(_SoporteTicket.fromJson)
                .toList();
          });
        }
      }
    } catch (_) {
      // no-op
    } finally {
      if (mounted) setState(() => _loadingTickets = false);
    }
  }

  Future<Map<String, dynamic>> _postTracking(Map<String, dynamic> payload) async {
    final apiUrl = dotenv.env['API'];
    if (apiUrl == null || apiUrl.isEmpty) {
      return {'ok': false, 'error': 'API no configurada en .env'};
    }
    Map<String, String> queryParams() {
      return payload.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }
    Future<Map<String, dynamic>> fallbackGet([String? reason]) async {
      try {
        final uri = Uri.parse(apiUrl).replace(queryParameters: queryParams());
        final resp = await http.get(uri).timeout(const Duration(seconds: 15));
        if (resp.statusCode != 200) {
          return {'ok': false, 'error': 'GET fallback HTTP ${resp.statusCode}'};
        }
        final decoded = jsonDecode(resp.body);
        if (decoded is Map<String, dynamic> && decoded['success'] == true) {
          return {'ok': true};
        }
        if (decoded is Map<String, dynamic>) {
          return {
            'ok': false,
            'error': (decoded['error'] ?? reason ?? 'Respuesta no exitosa').toString(),
          };
        }
        return {'ok': false, 'error': reason ?? 'Respuesta inválida del servidor'};
      } catch (e) {
        return {'ok': false, 'error': 'GET fallback: ${e.toString()}'};
      }
    }
    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        return fallbackGet('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['success'] == true) {
        return {'ok': true};
      }
      if (decoded is Map<String, dynamic>) {
        return {
          'ok': false,
          'error': (decoded['error'] ?? 'Respuesta no exitosa').toString(),
        };
      }
      return fallbackGet('Respuesta inválida del servidor');
    } catch (e) {
      return fallbackGet(e.toString());
    }
  }

  Future<void> _guardarTracking() async {
    if (_selected == null || _savingTracking) return;
    setState(() => _savingTracking = true);
    final codigo = _selected!.codigo;
    final comentario = _comentarioController.text.trim();
    final estadoResp = await _postTracking({
      'action': 'actualizar_estado_soporte',
      'codigo_ticket': codigo,
      'estado': _estadoSeleccionado,
      'usuario': 'app',
    });
    var comentarioResp = <String, dynamic>{'ok': true};
    if (comentario.isNotEmpty) {
      comentarioResp = await _postTracking({
        'action': 'agregar_comentario_soporte',
        'codigo_ticket': codigo,
        'comentario': comentario,
        'usuario': 'app',
      });
    }

    if (!mounted) return;
    setState(() => _savingTracking = false);
    final okEstado = estadoResp['ok'] == true;
    final okComentario = comentarioResp['ok'] == true;
    if (!okEstado || !okComentario) {
      final msgEstado = (estadoResp['error'] ?? '').toString();
      final msgComentario = (comentarioResp['error'] ?? '').toString();
      String short(String s) {
        final t = s.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        return t.length > 160 ? '${t.substring(0, 160)}…' : t;
      }
      final detalle = [
        if (!okEstado) 'Estado: ${short(msgEstado)}',
        if (!okComentario) 'Comentario: ${short(msgComentario)}',
      ].join(' | ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar seguimiento. $detalle'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }

    final correo = _emailController.text.trim();
    var envioTrackingOk = true;
    if (correo.isNotEmpty && _validEmail(correo)) {
      final resumen = StringBuffer()
        ..writeln('Ticket: ${_selected!.codigo}')
        ..writeln('Tipo: ${_selected!.tipo}')
        ..writeln('Estado: $_estadoSeleccionado');
      if (comentario.isNotEmpty) {
        resumen
          ..writeln()
          ..writeln('Comentario:')
          ..writeln(comentario);
      }
      envioTrackingOk = await MailHandler.sendMessage(
        recipientEmail: correo,
        body: resumen.toString().trim(),
        module: 'Soporte',
        subject: 'Seguimiento Ticket ${_selected!.codigo} ($_estadoSeleccionado)',
      );
    }
    await _loadTickets();
    if (!mounted) return;
    final updated = _tickets.where((t) => t.codigo == codigo).toList();
    setState(() {
      if (updated.isNotEmpty) {
        _selected = updated.first;
        _estadoSeleccionado = _selected!.estado;
      }
      _comentarioController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          envioTrackingOk
              ? 'Seguimiento actualizado'
              : 'Seguimiento actualizado, pero falló el correo',
        ),
        backgroundColor: envioTrackingOk ? Colors.green : Colors.orange,
      ),
    );
  }

  Future<void> _verHistorial() async {
    if (_selected == null) return;
    final apiUrl = dotenv.env['API'];
    if (apiUrl == null || apiUrl.isEmpty) return;
    final uri = Uri.parse(
      '$apiUrl?action=actividad&modulo=soportes&codigo=${Uri.encodeQueryComponent(_selected!.codigo)}',
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) throw Exception();
      final decoded = jsonDecode(response.body);
      final rows = decoded is List ? decoded : <dynamic>[];
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => SizedBox(
          height: 360,
          child: rows.isEmpty
              ? const Center(child: Text('Sin actividad registrada'))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final row = rows[index] as Map<String, dynamic>;
                    final tipo = row['tipo']?.toString() ?? 'evento';
                    final detalle = row['detalle']?.toString() ?? '';
                    final fecha = row['fecha']?.toString() ?? '';
                    return ListTile(
                      title: Text(detalle),
                      subtitle: Text('$tipo • $fecha'),
                    );
                  },
                ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar historial'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _mensajeController.dispose();
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rednet'),
        backgroundColor: const Color(0xFF616161).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: const [_ThemeToggle()],
      ),
      body: _Background(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ValueListenableBuilder<ThemeMode>(
            valueListenable: _themeNotifier,
            builder: (_, mode, __) {
              final isDark = mode == ThemeMode.dark;
              final fieldFill = isDark ? Colors.black.withOpacity(0.58) : Colors.white.withOpacity(0.90);
              final fieldText = isDark ? Colors.white : Colors.black87;
              final hintColor = isDark ? Colors.white.withOpacity(0.65) : Colors.black54;
              final borderColor = isDark ? Colors.white.withOpacity(0.25) : Colors.black.withOpacity(0.15);
              final focusBorder = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0D2B6B);
              final btnSendBg = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF0D2B6B);
              final btnSendFg = isDark ? const Color(0xFF0D2B6B) : Colors.white;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  const Text(
                    'Módulo de Soporte',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tickets abiertos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 150,
                    child: Container(
                      decoration: BoxDecoration(
                        color: fieldFill,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: _loadingTickets
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                          : ListView.separated(
                              itemCount: _tickets.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                              itemBuilder: (_, index) {
                                final t = _tickets[index];
                                final selected = _selected?.codigo == t.codigo;
                                return ListTile(
                                  selected: selected,
                                  selectedTileColor: focusBorder.withOpacity(0.15),
                                  title: Text('Ticket: ${t.codigo}', style: TextStyle(color: selected ? focusBorder : fieldText)),
                                  subtitle: Text('${t.tipo} • ${t.estado}', style: TextStyle(color: hintColor)),
                                  onTap: () {
                                    setState(() {
                                      _selected = t;
                                      _emailController.text = t.correo;
                                      _mensajeController.text = t.tipo;
                                      _estadoSeleccionado = t.estado;
                                      _comentarioController.clear();
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) { if (_emailError != null) _checkEmail(); },
                    style: TextStyle(color: fieldText),
                    decoration: InputDecoration(
                      hintText: 'Correo electrónico',
                      hintStyle: TextStyle(color: hintColor),
                      errorText: _emailError,
                      filled: true,
                      fillColor: fieldFill,
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusBorder, width: 1.5)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_selected != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: fieldFill,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seguimiento del ticket',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0D2B6B),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _estados.contains(_estadoSeleccionado) ? _estadoSeleccionado : _estados.first,
                            items: _estados.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _estadoSeleccionado = v);
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: fieldFill,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusBorder, width: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _comentarioController,
                            minLines: 2,
                            maxLines: 3,
                            style: TextStyle(color: fieldText),
                            decoration: InputDecoration(
                              hintText: 'Comentario de seguimiento',
                              hintStyle: TextStyle(color: hintColor),
                              filled: true,
                              fillColor: fieldFill,
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusBorder, width: 1.5)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _savingTracking ? null : _guardarTracking,
                                  style: ElevatedButton.styleFrom(backgroundColor: btnSendBg, foregroundColor: btnSendFg),
                                  child: _savingTracking
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Guardar seguimiento'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: _verHistorial,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isDark ? Colors.white : const Color(0xFF0D2B6B),
                                  side: BorderSide(color: isDark ? Colors.white.withOpacity(0.7) : const Color(0xFF0D2B6B)),
                                ),
                                child: const Text('Ver historial'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 170,
                    child: TextField(
                      controller: _mensajeController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TextStyle(color: fieldText),
                      decoration: InputDecoration(
                        hintText: 'Mensaje al cliente',
                        hintStyle: TextStyle(color: hintColor),
                        filled: true,
                        fillColor: fieldFill,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: focusBorder, width: 1.5)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _sendingMail ? null : () async {
                            _checkEmail();
                            if (_emailError != null) return;
                            setState(() => _sendingMail = true);
                            final subject = _selected != null
                                ? 'Ticket: ${_selected!.codigo} - ${_selected!.tipo}'
                                : 'Soporte';
                            final comentarioTracking = _comentarioController.text.trim();
                            final cuerpo = StringBuffer(_mensajeController.text.trim());
                            if (_selected != null) {
                              cuerpo
                                ..writeln()
                                ..writeln()
                                ..writeln('--- Datos de seguimiento ---')
                                ..writeln('Ticket: ${_selected!.codigo}')
                                ..writeln('Tipo: ${_selected!.tipo}')
                                ..writeln('Estado: $_estadoSeleccionado');
                              if (comentarioTracking.isNotEmpty) {
                                cuerpo
                                  ..writeln('Comentario: $comentarioTracking');
                              }
                            }
                            final ok = await MailHandler.sendMessage(
                              recipientEmail: _emailController.text.trim(),
                              body: cuerpo.toString().trim(),
                              module: 'Soporte',
                              subject: subject,
                            );
                            if (!mounted) return;
                            setState(() => _sendingMail = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok ? 'Mensaje enviado' : 'Error al enviar'),
                                backgroundColor: ok ? Colors.green : Colors.red,
                              ),
                            );
                            if (ok) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: btnSendBg, foregroundColor: btnSendFg),
                          child: _sendingMail
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Enviar'),
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class EnviosPage extends StatelessWidget {
  const EnviosPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ModulePage(titulo: 'Envios', action: 'envios');
}

class VentasPage extends StatelessWidget {
  const VentasPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const _ModulePage(titulo: 'Ventas', action: 'ventas');
}
