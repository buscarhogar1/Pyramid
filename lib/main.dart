import 'dart:convert';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockLandscape();
  runApp(const PyramidApp());
}

Future<void> _lockLandscape() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

Future<void> _lockPortrait() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class PyramidApp extends StatelessWidget {
  const PyramidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Pyramid',
      debugShowCheckedModeBanner: false,
      home: PyramidScreen(),
    );
  }
}

class PyramidScreen extends StatefulWidget {
  const PyramidScreen({super.key});

  @override
  State<PyramidScreen> createState() => _PyramidScreenState();
}

class _PyramidScreenState extends State<PyramidScreen>
    with WidgetsBindingObserver {
  static const _screenProtectionChannel =
      MethodChannel('com.pyramid.drinkinggame/screen_protection');

  late final WebViewController _controller;
  var _screenCaptureProtectionEnabled = false;
  var _portraitTextEntryActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0713))
      ..addJavaScriptChannel(
        'PyramidNative',
        onMessageReceived: _handleNativeMessage,
      )
      ..loadFlutterAsset('assets/web/index.html');
  }

  Future<void> _handleNativeMessage(JavaScriptMessage message) async {
    try {
      final payload = jsonDecode(message.message);
      if (payload is! Map) return;

      if (payload['action'] == 'setScreenCaptureProtection') {
        final enabled = payload['enabled'] == true;
        if (_screenCaptureProtectionEnabled == enabled) return;

        _screenCaptureProtectionEnabled = enabled;
        if (defaultTargetPlatform == TargetPlatform.android) {
          await _screenProtectionChannel.invokeMethod<void>(
            'setScreenCaptureProtection',
            {'enabled': enabled},
          );
        }
        return;
      }

      if (payload['action'] == 'setTextEntryOrientation') {
        final orientation = payload['orientation'];
        _portraitTextEntryActive = orientation == 'portrait';
        if (_portraitTextEntryActive) {
          await _lockPortrait();
        } else {
          await _lockLandscape();
        }
        return;
      }

      if (payload['action'] != 'shareRoom') return;

      final code = payload['code'];
      if (code is! String || code.isEmpty) return;
      await SharePlus.instance.share(
        ShareParams(
          title: 'La Pirámide',
          text: 'Únete a mi partida de La Pirámide con el código $code.',
        ),
      );
    } on FormatException {
      // Ignore malformed messages from the web game.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_portraitTextEntryActive) {
        _lockPortrait();
      } else {
        _lockLandscape();
      }
    }
  }

  @override
  void dispose() {
    if (_portraitTextEntryActive) {
      _lockLandscape();
    }
    if (_screenCaptureProtectionEnabled &&
        defaultTargetPlatform == TargetPlatform.android) {
      _screenProtectionChannel
          .invokeMethod<void>('setScreenCaptureProtection', {'enabled': false});
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0713),
      body: WebViewWidget(controller: _controller),
    );
  }
}
