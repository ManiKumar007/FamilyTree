import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/models.dart';

/// A person card widget styled like Geni.com — colored border based on gender,
/// showing photo, name, birth year, and action buttons.
class PersonCard extends StatelessWidget {
  final Person person;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onInvite;

  const PersonCard({
    super.key,
    required this.person,
    this.isCurrentUser = false,
    this.onTap,
    this.onEdit,
    this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final isMale = person.gender == 'male';
    final borderColor = isMale ? kMaleColor : kFemaleColor;
    final bgColor = isMale ? kMaleColor.withOpacity(0.3) : kFemaleColor.withOpacity(0.3);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: isCurrentUser ? kAccentColor : borderColor,
            width: isCurrentUser ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo area
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
              child: person.photoUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      child: Image.network(
                        person.photoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _defaultAvatar(isMale),
                      ),
                    )
                  : _defaultAvatar(isMale),
            ),

            // Info area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                children: [
                  Text(
                    person.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  if (person.birthYear != null)
                    Text(
                      '(${person.birthYear} -)',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (onEdit != null)
                    _actionIcon(Icons.edit, onEdit!, 'Edit'),
                  if (!person.verified && onInvite != null)
                    _actionIcon(Icons.send, onInvite!, 'Invite'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(bool isMale) {
    return Center(
      child: Icon(
        isMale ? Icons.person : Icons.person_2,
        size: 36,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _actionIcon(IconData icon, VoidCallback onPressed, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 14, color: Colors.grey[700]),
        ),
      ),
    );
  }
}

/// Ghost button for adding a family member at an empty position in the tree.
class AddPersonButton extends StatelessWidget {
  final String label; // e.g., 'Add Father', 'Add Child'
  final VoidCallback onTap;

  const AddPersonButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[50],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, color: Colors.grey[400], size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: kPrimaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '+$count',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
