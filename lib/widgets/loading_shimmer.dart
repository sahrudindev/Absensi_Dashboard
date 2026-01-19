import 'package:flutter/material.dart';

/// Loading Shimmer Widget
/// 
/// Displays skeleton loading placeholders while data is being fetched.

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key});

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              _buildShimmerBox(height: 60, width: double.infinity),
              
              const SizedBox(height: 20),
              
              // Stats cards shimmer (2x2 grid)
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 120)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(height: 120)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildShimmerBox(height: 120)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildShimmerBox(height: 120)),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Rate card shimmer
              _buildShimmerBox(height: 100, width: double.infinity),
              
              const SizedBox(height: 20),
              
              // Chart shimmer
              _buildShimmerBox(height: 280, width: double.infinity),
              
              const SizedBox(height: 20),
              
              // List shimmer
              _buildShimmerBox(height: 60, width: double.infinity),
              const SizedBox(height: 8),
              _buildShimmerBox(height: 60, width: double.infinity),
              const SizedBox(height: 8),
              _buildShimmerBox(height: 60, width: double.infinity),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerBox({
    required double height,
    double? width,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withOpacity(_animation.value),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Shimmer effect wrapper for individual widgets
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  
  const ShimmerEffect({
    super.key,
    required this.child,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Colors.white24,
                Colors.white60,
                Colors.white24,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}
