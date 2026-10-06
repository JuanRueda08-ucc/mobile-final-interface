import 'dart:async';

import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// Aviso temporal de una pantalla (`toast` de B5.2): [notice] se pinta con
/// `VigiaScaffold(notice: ...)` y desaparece tras [VigiaMotion.toastDuration].
mixin NoticeHost<T extends StatefulWidget> on State<T> {
  String? notice;
  Timer? _noticeTimer;

  void showNotice(String text) {
    _noticeTimer?.cancel();
    setState(() => notice = text);
    _noticeTimer = Timer(VigiaMotion.toastDuration, () {
      if (mounted) setState(() => notice = null);
    });
  }

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }
}
