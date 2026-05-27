import 'dart:async';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:smoking/pages/starting_pages/auth.dart';

class SplashScreen extends StatefulWidget {
  final Account account;
  const SplashScreen({
    super.key,
    required this.account,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _glowController;
  late AnimationController _placeholderController;
  late AnimationController _particleController;

  late Animation<double> _textOpacity;
  late Animation<double> _logoScale;
  late Animation<double> _fade;
  late Animation<double> _placeholderScale;
  late Animation<double> _glow;

  int _currentMessageIndex = 0;
  Timer? _cycleTimer;
  bool _ready = false;

  final List<String> messages = [
    "Welcome to X-hale",
    "Inhale change",
    "Exhale the past",
  ];

  late List<Particle> _particles;
  final int _particleCount = 20;

  @override
  void initState() {
    super.initState();

    _particles = List.generate(_particleCount, (_) => Particle());

    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _placeholderController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _placeholderScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _placeholderController,
        curve: Curves.easeOutBack,
      ),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glow = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await precacheImage(
        const AssetImage('assets/icons/X-hale_logo.png'),
        context,
      );

      if (!mounted) return;

      setState(() => _ready = true);
      _placeholderController.forward();

      await Future.delayed(Duration.zero);

      _logoController.repeat(reverse: true);
      _textController.forward();
      _startMessageCycle();

      Future.delayed(const Duration(milliseconds: 6500), () async {
        if (!mounted) return;
        await _fadeController.forward();
        if (!mounted) return;
        // Belt-and-braces: only replace ourselves if splash is still the
        // topmost route. Without `isCurrent`, any code that pushed another
        // route on top during the 6.5s wait would get popped off by the
        // `pushReplacement`.
        if (!(ModalRoute.of(context)?.isCurrent ?? false)) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AuthPage(account: widget.account),
          ),
        );
      });
    });
  }

  void _startMessageCycle() {
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) return;
      _textController.reverse().then((_) {
        if (!mounted) return;
        setState(() {
          _currentMessageIndex = (_currentMessageIndex + 1) % messages.length;
        });
        _textController.forward();
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    _glowController.dispose();
    _placeholderController.dispose();
    _particleController.dispose();
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 3),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF008080), Color(0xFF004D4D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    _particles,
                    _particleController.value,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child:
                    !_ready
                        ? ScaleTransition(
                          scale: _placeholderScale,
                          child: _buildLogo(glow: false),
                        )
                        : FadeTransition(
                          opacity: _fade,
                          child: _buildAnimatedContent(),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo({bool glow = true}) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFA6), Color(0xFF004D4D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.tealAccent.withAlpha(
                  ((glow ? _glow.value : 0.4) * 255).round(),
                ),
                blurRadius: 30,
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.asset(
              'assets/icons/X-hale_logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(scale: _logoScale, child: _buildLogo()),
        const SizedBox(height: 20),
        FadeTransition(
          opacity: _textOpacity,
          child: Text(
            messages[_currentMessageIndex],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.3,
              fontFamily: 'CalSans-Regular',
            ),
          ),
        ),
        const SizedBox(height: 25),
        const Text(
          "Breathe. Relax. X-hale.",
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double direction;

  Particle() {
    final rand = Random();
    x = rand.nextDouble();
    y = rand.nextDouble();
    size = rand.nextDouble() * 3 + 1;
    speed = rand.nextDouble() * 0.0005 + 0.0002;
    direction = rand.nextDouble() * 2 * pi;
  }

  void tick() {
    x += cos(direction) * speed;
    y += sin(direction) * speed;

    if (x < 0) x = 1;
    if (x > 1) x = 0;
    if (y < 0) y = 1;
    if (y > 1) y = 0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withAlpha((0.15 * 255).round());

    for (var p in particles) {
      p.tick();
      final dx = p.x * size.width;
      final dy = p.y * size.height;
      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
