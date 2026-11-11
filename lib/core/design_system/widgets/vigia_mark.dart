import 'package:flutter/widgets.dart';

class VigiaMark extends StatelessWidget {
  const VigiaMark({super.key, required this.size, required this.ink});

  static const asset = 'assets/brand/vigia_symbol.png';

  final double size;
  final Color ink;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    color: ink,
    excludeFromSemantics: true,
  );
}
