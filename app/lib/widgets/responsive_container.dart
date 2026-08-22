import 'package:flutter/material.dart';

/// Limita a largura do conteúdo em telas grandes (tablets) e centraliza,
/// evitando que cards e listas se espalhem de ponta a ponta. Em celulares,
/// a largura da tela já é menor que [maxWidth], então não tem efeito visual.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({super.key, required this.child, this.maxWidth = 600});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
