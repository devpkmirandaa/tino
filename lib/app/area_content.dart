import 'package:flutter/material.dart';

/// Preserva os navegadores; anima somente o conteúdo da área ativa.
class AreaContent extends StatefulWidget {
  const AreaContent({super.key, required this.index, required this.children});
  final int index;
  final List<Widget> children;

  @override
  State<AreaContent> createState() => _AreaContentState();
}

class _AreaContentState extends State<AreaContent>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final _curve = CurvedAnimation(
    parent: _fade,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(covariant AreaContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _fade.value = 1;
      } else {
        _fade.forward(from: 0);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) _fade.value = 1;
  }

  @override
  void dispose() {
    _curve.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    key: const ValueKey('area-content-fade'),
    opacity: _curve,
    child: IndexedStack(
      index: widget.index,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          TickerMode(
            enabled: index == widget.index,
            child: widget.children[index],
          ),
      ],
    ),
  );
}
