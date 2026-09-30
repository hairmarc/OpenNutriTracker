import 'package:flutter/material.dart';
import 'package:opennutritracker/core/styles/dimens.dart';

/// Compact add control for a meal or activity section header.
///
/// The painted square is 40px; the [IconButton] keeps a 48px hit target.
class SectionAddButton extends StatelessWidget {
  final String identifier;
  final String tooltip;
  final Color accent;
  final VoidCallback onPressed;

  const SectionAddButton({
    super.key,
    required this.identifier,
    required this.tooltip,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: identifier,
      // Tight bounds: the parent is a flex Row, and without this the node
      // inherits the row's full-width box so coordinate taps miss the button.
      container: true,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(48, 48),
          fixedSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.all(4),
          shape: const RoundedRectangleBorder(
            borderRadius: Dimens.borderRadiusS,
          ),
        ),
        icon: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: Dimens.borderRadiusS,
          ),
          child: Icon(Icons.add_rounded, size: 22, color: accent),
        ),
      ),
    );
  }
}
