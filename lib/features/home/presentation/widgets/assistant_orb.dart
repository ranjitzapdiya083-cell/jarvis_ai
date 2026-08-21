import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/assistant_state.dart';

/// Recreates the glowing gradient orb from the design: a soft rotating
/// conic gradient ring plus a pulsing glow while listening/speaking.
class AssistantOrb extends StatefulWidget {
  final AssistantState state;
  final VoidCallback onTap;
  final double size;

  const AssistantOrb({
    super.key,
    required this.state,
    required this.onTap,
    this.size = 220,
  });

  @override
  State<AssistantOrb> createState() => _AssistantOrbState();
}

class _AssistantOrbState extends State<AssistantOrb> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isActive =>
      widget.state == AssistantState.listening ||
      widget.state == AssistantState.processing ||
      widget.state == AssistantState.speaking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, _) {
          final pulse = _isActive ? (0.9 + _pulseController.value * 0.15) : 1.0;
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Transform.scale(
                  scale: pulse,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.electricBlue.withValues(alpha: _isActive ? 0.45 : 0.25),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: _isActive ? 0.35 : 0.18),
                          blurRadius: 80,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                // Rotating gradient ring
                Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: Container(
                    width: widget.size * 0.82,
                    height: widget.size * 0.82,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.electricBlue,
                          AppColors.purple,
                          AppColors.electricBlue,
                        ],
                      ),
                    ),
                  ),
                ),
                // Inner core
                Container(
                  width: widget.size * 0.7,
                  height: widget.size * 0.7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.darkBg,
                  ),
                  child: Icon(
                    _iconFor(widget.state),
                    color: Colors.white,
                    size: widget.size * 0.22,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(AssistantState state) {
    switch (state) {
      case AssistantState.listening:
        return Icons.mic;
      case AssistantState.processing:
        return Icons.hourglass_top;
      case AssistantState.speaking:
        return Icons.graphic_eq;
      case AssistantState.error:
      case AssistantState.permissionRequired:
        return Icons.mic_off;
      default:
        return Icons.mic_none;
    }
  }
}
