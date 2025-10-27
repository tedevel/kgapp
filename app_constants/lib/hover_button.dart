import 'package:flutter/material.dart';

class HoverButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color normalColor;
  final Color hoverColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final String? tooltip;

  const HoverButton({
    Key? key,
    required this.child,
    this.onTap,
    this.normalColor = Colors.white,
    this.hoverColor  = Colors.blueAccent,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
  }) : super(key: key);

  @override
  _HoverButtonState createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        color: _hovered ? widget.hoverColor : widget.normalColor,
        borderRadius: widget.borderRadius,
      ),
      child: widget.child,
    );

    if (widget.tooltip != null) {
      content = Tooltip(message: widget.tooltip!, child: content);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: widget.borderRadius,
        child: content,
      ),
    );
  }
}