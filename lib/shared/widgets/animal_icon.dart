import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../models/animal.dart';

/// Icône animal — cercle pastel avec icône Font Awesome blanche.
class AnimalIcon extends StatefulWidget {
  final AnimalType type;
  final double size;
  final VoidCallback? onTap;
  final bool animated;
  /// false = icône seule sans fond (usage inside gradient card)
  final bool showBackground;

  const AnimalIcon({
    super.key,
    required this.type,
    this.size = 48,
    this.onTap,
    this.animated = true,
    this.showBackground = true,
  });

  @override
  State<AnimalIcon> createState() => _AnimalIconState();
}

class _AnimalIconState extends State<AnimalIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wiggleCtrl;
  late final Animation<double> _wiggle;

  @override
  void initState() {
    super.initState();
    _wiggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _wiggle = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.10, end: -0.10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.05), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _wiggleCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _wiggleCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _wiggleCtrl.forward(from: 0);
    widget.onTap?.call();
  }

  // ── Couleur pastel par type ─────────────────────────────────────────────────
  Color get _pastelColor {
    switch (widget.type) {
      case AnimalType.chien:   return AppColors.animalChien;
      case AnimalType.chat:    return AppColors.animalChat;
      case AnimalType.lapin:   return AppColors.animalLapin;
      case AnimalType.oiseau:  return AppColors.animalOiseau;
      case AnimalType.rongeur: return AppColors.animalRongeur;
      case AnimalType.reptile: return AppColors.animalReptile;
      case AnimalType.autre:   return AppColors.animalAutre;
    }
  }

  // ── Icône Font Awesome par type ─────────────────────────────────────────────
  Widget _faIcon(double iconSize, Color color) {
    switch (widget.type) {
      case AnimalType.chien:
        return FaIcon(FontAwesomeIcons.dog,    color: color, size: iconSize);
      case AnimalType.chat:
        return FaIcon(FontAwesomeIcons.cat,    color: color, size: iconSize);
      case AnimalType.lapin:
        return FaIcon(FontAwesomeIcons.paw,    color: color, size: iconSize);
      case AnimalType.oiseau:
        return FaIcon(FontAwesomeIcons.dove,   color: color, size: iconSize);
      case AnimalType.rongeur:
        return FaIcon(FontAwesomeIcons.otter,  color: color, size: iconSize);
      case AnimalType.reptile:
        return FaIcon(FontAwesomeIcons.dragon, color: color, size: iconSize);
      case AnimalType.autre:
        return FaIcon(FontAwesomeIcons.paw,    color: color, size: iconSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget icon;

    if (!widget.showBackground) {
      // Icône blanche seule — pour l'intérieur d'un fond coloré
      icon = _faIcon(widget.size * 0.60, Colors.white.withValues(alpha: 0.92));
    } else {
      // Cercle pastel + icône blanche
      final circle = Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _pastelColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _pastelColor.withValues(alpha: 0.5),
              blurRadius: widget.size * 0.3,
              offset: Offset(0, widget.size * 0.08),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: _faIcon(widget.size * 0.48, Colors.white),
      );

      icon = AnimatedBuilder(
        animation: _wiggle,
        builder: (_, child) => Transform.rotate(
          angle: _wiggle.value * math.pi / 8,
          child: child,
        ),
        child: circle,
      );
    }

    final pulsing = widget.animated && widget.showBackground
        ? Pulse(
            infinite: true,
            duration: const Duration(milliseconds: 2600),
            child: icon,
          )
        : icon;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: pulsing,
    );
  }
}
