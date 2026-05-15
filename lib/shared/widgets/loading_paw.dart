import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Loader avec une empreinte de patte qui pulse — identité Petlander.
class LoadingPaw extends StatefulWidget {
  final double size;
  final Color color;

  const LoadingPaw({
    super.key,
    this.size = 60,
    this.color = AppColors.primaryDark,
  });

  @override
  State<LoadingPaw> createState() => _LoadingPawState();
}

class _LoadingPawState extends State<LoadingPaw>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.7, end: 1.1).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
        ),
        child: Icon(Icons.pets, size: widget.size, color: widget.color),
      ),
    );
  }
}
