import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/models.dart';

/// A person card widget styled with modern rounded corners, soft shadows,
/// and gender-colored accent strip.
class PersonCard extends StatefulWidget {
  final Person person;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onInvite;
  final VoidCallback? onFindConnection;
  final double? cardWidth;

  const PersonCard({
    super.key,
    required this.person,
    this.isCurrentUser = false,
    this.onTap,
    this.onEdit,
    this.onInvite,
    this.onFindConnection,
    this.cardWidth,
  });

  @override
  State<PersonCard> createState() => _PersonCardState();
}

class _PersonCardState extends State<PersonCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMale = widget.person.gender == 'male';
    final genderColor = getGenderColor(widget.person.gender);
    final effectiveWidth = widget.cardWidth ?? 148.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: effectiveWidth,
          decoration: BoxDecoration(
            color: kSurfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isCurrentUser
                  ? kAccentColor
                  : _isHovered
                      ? genderColor.withValues(alpha: 0.6)
                      : kDividerColor,
              width: widget.isCurrentUser ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered
                    ? genderColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isHovered ? 12 : 6,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gender accent strip + photo area
              Container(
                height: effectiveWidth * 0.4,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [genderColor, genderColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: widget.person.photoUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          widget.person.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultAvatar(isMale),
                        ),
                      )
                    : _defaultAvatar(isMale),
              ),

              // Info area
              Padding(
                padding: EdgeInsets.symmetric(horizontal: effectiveWidth * 0.05, vertical: effectiveWidth * 0.04),
                child: Column(
                  children: [
                    Text(
                      widget.person.name,
                      style: TextStyle(
                        fontSize: (effectiveWidth * 0.08).clamp(10.0, 14.0),
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.person.birthYear != null)
                      Text(
                        '(${widget.person.birthYear} -)',
                        style: TextStyle(fontSize: (effectiveWidth * 0.07).clamp(9.0, 12.0), color: kTextSecondary),
                      ),
                  ],
                ),
              ),

              // Action buttons
              if (widget.onEdit != null || (!widget.person.verified && widget.onInvite != null) || widget.onFindConnection != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 6, right: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.onEdit != null)
                        _actionIcon(Icons.edit_outlined, widget.onEdit!, 'Edit'),
                      if (!widget.person.verified && widget.onInvite != null)
                        _actionIcon(Icons.send_outlined, widget.onInvite!, 'Invite'),
                      if (widget.onFindConnection != null && !widget.isCurrentUser)
                        _actionIcon(Icons.link_rounded, widget.onFindConnection!, 'Find Connection'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(bool isMale) {
    return Center(
      child: Icon(
        isMale ? Icons.person_rounded : Icons.person_2_rounded,
        size: 32,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: kSurfaceSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: kTextSecondary),
        ),
      ),
    );
  }
}

/// Ghost button for adding a family member at an empty position in the tree.
class AddPersonButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double? buttonWidth;

  const AddPersonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.buttonWidth,
  });

  @override
  State<AddPersonButton> createState() => _AddPersonButtonState();
}

class _AddPersonButtonState extends State<AddPersonButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = widget.buttonWidth ?? 120.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: effectiveWidth,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isHovered ? kPrimaryColor.withValues(alpha: 0.5) : kDividerColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(14),
            color: _isHovered ? kPrimaryColor.withValues(alpha: 0.04) : kSurfaceColor,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? kPrimaryColor.withValues(alpha: 0.1)
                      : kSurfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: _isHovered ? kPrimaryColor : kTextDisabled,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  color: _isHovered ? kPrimaryColor : kTextSecondary,
                  fontWeight: _isHovered ? FontWeight.w500 : FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapse badge widget, e.g., "+15" showing hidden nodes count
class CollapseBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const CollapseBadge({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '+$count',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
