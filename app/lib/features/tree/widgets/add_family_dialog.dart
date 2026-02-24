import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../models/models.dart';

/// A dialog that shows spatial UI for adding family members around a person.
/// Displays the person in the center with relationship buttons positioned around them.
class AddFamilyDialog extends StatelessWidget {
  final Person person;

  const AddFamilyDialog({
    super.key,
    required this.person,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 600,
          maxHeight: 700,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: kBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              child: Text(
                'Add Family Member',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
              ),
            ),

            // Main content area with spatial layout
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Center person card
                      Center(
                        child: _buildCenterPersonCard(context),
                      ),

                      // Top row: Father and Mother
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRelationButton(
                              context: context,
                              label: 'Add Father',
                              relationshipType: 'CHILD_OF',
                              gender: 'male',
                              isMale: true,
                            ),
                            const SizedBox(width: 16),
                            _buildRelationButton(
                              context: context,
                              label: 'Add Mother',
                              relationshipType: 'CHILD_OF',
                              gender: 'female',
                              isMale: false,
                            ),
                          ],
                        ),
                      ),

                      // Left column: Brother and Sister
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRelationButton(
                              context: context,
                              label: 'Add Brother',
                              relationshipType: 'SIBLING_OF',
                              gender: 'male',
                              isMale: true,
                            ),
                            const SizedBox(height: 12),
                            _buildRelationButton(
                              context: context,
                              label: 'Add Sister',
                              relationshipType: 'SIBLING_OF',
                              gender: 'female',
                              isMale: false,
                            ),
                          ],
                        ),
                      ),

                      // Right column: Husband and Wife
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRelationButton(
                              context: context,
                              label: 'Add Husband',
                              relationshipType: 'SPOUSE_OF',
                              gender: 'male',
                              isMale: true,
                            ),
                            const SizedBox(height: 12),
                            _buildRelationButton(
                              context: context,
                              label: 'Add Wife',
                              relationshipType: 'SPOUSE_OF',
                              gender: 'female',
                              isMale: false,
                            ),
                          ],
                        ),
                      ),

                      // Bottom row: Son and Daughter
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRelationButton(
                              context: context,
                              label: 'Add Son',
                              relationshipType: 'CHILD_OF',
                              gender: 'male',
                              isMale: true,
                            ),
                            const SizedBox(width: 16),
                            _buildRelationButton(
                              context: context,
                              label: 'Add Daughter',
                              relationshipType: 'CHILD_OF',
                              gender: 'female',
                              isMale: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Cancel button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: kTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPersonCard(BuildContext context) {
    final isMale = person.gender == 'male';
    final genderColor = getGenderColor(person.gender);

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kAccentColor,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo area with edit icon
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [genderColor, genderColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: person.photoUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          topRight: Radius.circular(14),
                        ),
                        child: Image.network(
                          person.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _defaultAvatar(isMale),
                        ),
                      )
                    : _defaultAvatar(isMale),
              ),
              
              // Edit icon (top right)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: kTextSecondary,
                  ),
                ),
              ),
            ],
          ),

          // Name
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              person.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(bool isMale) {
    return Center(
      child: Icon(
        isMale ? Icons.person_rounded : Icons.person_2_rounded,
        size: 80,
        color: Colors.white.withValues(alpha: 0.8),
      ),
    );
  }

  Widget _buildRelationButton({
    required BuildContext context,
    required String label,
    required String relationshipType,
    required String gender,
    required bool isMale,
  }) {
    final buttonColor = isMale 
        ? const Color(0xFF88C9E8) // Light blue for male
        : const Color(0xFFEEB4D7); // Pink for female

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          
          // Determine the correct relationship type
          String actualRelationType = relationshipType;
          
          // For children (son/daughter), always use CHILD_OF
          // The backend will create the proper parent relationship
          if (label == 'Add Son' || label == 'Add Daughter') {
            actualRelationType = 'CHILD_OF';
          }
          // For parents, use FATHER_OF or MOTHER_OF based on gender
          else if (label == 'Add Father' || label == 'Add Mother') {
            actualRelationType = isMale ? 'FATHER_OF' : 'MOTHER_OF';
          }
          // For siblings and spouses, use the passed relationship type

          // Use extra parameter to pass data to add member screen
          context.push(
            '/tree/add-member',
            extra: {
              'relativePersonId': person.id,
              'relationshipType': actualRelationType,
              'gender': gender,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 140,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C2C2C),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the add family dialog
void showAddFamilyDialog(BuildContext context, Person person) {
  showDialog(
    context: context,
    builder: (context) => AddFamilyDialog(person: person),
  );
}
