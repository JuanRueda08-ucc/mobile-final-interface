import 'package:flutter/widgets.dart';

class VigiaMark extends StatelessWidget {
  const VigiaMark({super.key, required this.size});

  static const asset = 'assets/brand/vigia_mark.png';

  final double size;

  @override
  Widget build(BuildContext context) =>
      Image.asset(asset, width: size, height: size, excludeFromSemantics: true);
}
