import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An Apple SF Symbol, tinted with [color].
///
/// iOS draws the system glyph (`fork.knife` and the rest of the SF Symbols
/// set). Other platforms, and a missing symbol, show [fallback] so the card
/// still has an icon where SF Symbols are not installed.
class SfSymbolIcon extends StatefulWidget {
  final String symbol;
  final double size;
  final Color color;
  final Widget fallback;

  const SfSymbolIcon({
    super.key,
    required this.symbol,
    required this.size,
    required this.color,
    required this.fallback,
  });

  @override
  State<SfSymbolIcon> createState() => _SfSymbolIconState();
}

class _SfSymbolIconState extends State<SfSymbolIcon> {
  static const _channel = MethodChannel('com.opennutritracker/sf_symbol');
  static final _cache = <String, Uint8List>{};

  Uint8List? _bytes;
  String? _key;
  var _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Platform.isIOS) return;
    final pixels = (widget.size * MediaQuery.devicePixelRatioOf(context))
        .ceil()
        .clamp(1, 200);
    final key = '${widget.symbol}@$pixels';
    if (key == _key) return;
    _key = key;
    final cached = _cache[key];
    if (cached != null) {
      _bytes = cached;
      _failed = false;
      return;
    }
    _load(key, pixels);
  }

  Future<void> _load(String key, int pixels) async {
    try {
      final data = await _channel.invokeMethod<Uint8List>('png', {
        'name': widget.symbol,
        'pointSize': pixels.toDouble(),
      });
      if (!mounted || data == null || _key != key) return;
      _cache[key] = data;
      setState(() {
        _bytes = data;
        _failed = false;
      });
    } on MissingPluginException {
      if (mounted) setState(() => _failed = true);
    } on PlatformException {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (!Platform.isIOS || _failed || bytes == null) {
      if (!Platform.isIOS || _failed) return widget.fallback;
      return SizedBox(width: widget.size, height: widget.size);
    }
    return ColorFiltered(
      colorFilter: ColorFilter.mode(widget.color, BlendMode.srcIn),
      child: Image.memory(
        bytes,
        width: widget.size,
        height: widget.size,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
