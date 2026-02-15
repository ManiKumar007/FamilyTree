# UI Components Usage Guide

## Quick Reference for Using the New UI Components

---

## 🎨 Theme Colors

### Import

```dart
import 'package:myfamilytree/config/theme.dart';
```

### Using Colors

```dart
// Gender colors
Container(color: getGenderColor('male'))  // Blue
Container(color: getGenderColor('female'))  // Pink
Container(color: getGenderColor('other'))  // Purple

// Relationship colors
Container(color: getRelationshipColor('FATHER_OF'))  // Purple
Container(color: kRelationshipSpouse)  // Deep Pink

// Status colors
Container(color: kSuccessColor)  // Green
Container(color: kErrorColor)  // Red
Container(color: kWarningColor)  // Orange

// Brand colors
Container(color: kPrimaryColor)  // Forest Green
Container(color: kSecondaryColor)  // Ocean Blue
Container(color: kAccentColor)  // Amber
```

### Using Spacing

```dart
Padding(
  padding: EdgeInsets.all(AppSpacing.md),  // 16dp
  child: Column(
    children: [
      Text('Title'),
      SizedBox(height: AppSpacing.sm),  // 8dp
      Text('Subtitle'),
    ],
  ),
)
```

---

## 🧩 Common Widgets

### Import

```dart
import 'package:myfamilytree/widgets/common_widgets.dart';
```

### AppAvatar

Display user profile pictures with gender-based placeholders.

```dart
// Basic usage
AppAvatar(
  imageUrl: person.photoUrl,
  gender: person.gender,
  size: AppSizing.avatarMd,
)

// With tap action
AppAvatar(
  imageUrl: person.photoUrl,
  gender: person.gender,
  name: person.name,
  size: AppSizing.avatarLg,
  onTap: () => print('Avatar tapped'),
  showEditIcon: true,
)
```

**Sizes:**

- `AppSizing.avatarSm` - 40dp
- `AppSizing.avatarMd` - 60dp
- `AppSizing.avatarLg` - 80dp
- `AppSizing.avatarXl` - 120dp

---

### InfoCard

Clickable information cards with icon, title, and subtitle.

```dart
InfoCard(
  icon: Icons.person_add,
  title: 'Add Family Member',
  subtitle: 'Add a new person to your family tree',
  iconColor: kSuccessColor,
  onTap: () => context.push('/add-member'),
)

// Without tap action (static display)
InfoCard(
  icon: Icons.info,
  title: 'Information',
  subtitle: 'This is some info',
)
```

---

### DetailRow

Display label-value pairs with optional icons.

```dart
Column(
  children: [
    DetailRow(
      icon: Icons.phone,
      label: 'Phone',
      value: '+91 1234567890',
      iconColor: kSuccessColor,
    ),
    DetailRow(
      icon: Icons.email,
      label: 'Email',
      value: 'user@example.com',
      iconColor: kInfoColor,
    ),
    DetailRow(
      label: 'Address',  // Without icon
      value: 'Mumbai, Maharashtra',
    ),
  ],
)
```

---

### SectionHeader

Section titles with optional actions.

```dart
// Simple header
SectionHeader(
  title: 'Personal Information',
  icon: Icons.person,
)

// With action button
SectionHeader(
  title: 'Family Members',
  icon: Icons.people,
  action: 'Add',
  onActionTap: () => showAddMemberDialog(),
)
```

---

### StatusBadge

Colored badges for status indicators.

```dart
// Verified badge
StatusBadge(
  label: 'Verified',
  icon: Icons.verified,
  color: kSuccessColor,
)

// Pending badge
StatusBadge(
  label: 'Pending',
  icon: Icons.pending,
  color: kWarningColor,
)

// Custom badge
StatusBadge(
  label: 'Premium',
  icon: Icons.star,
  color: Colors.amber,
)
```

---

### EmptyState

Beautiful empty states when no data exists.

```dart
// Basic empty state
EmptyState(
  icon: Icons.people_outline,
  title: 'No Family Members',
  subtitle: 'Add family members to get started',
)

// With action button
EmptyState(
  icon: Icons.search_off,
  title: 'No Results Found',
  subtitle: 'Try different search terms',
  actionLabel: 'Clear Search',
  onAction: () => clearSearch(),
)
```

---

### LoadingOverlay

Show loading indicator over content.

```dart
LoadingOverlay(
  isLoading: _isUploading,
  message: 'Uploading image...',
  child: YourContentWidget(),
)

// Without message
LoadingOverlay(
  isLoading: _isSaving,
  child: YourContentWidget(),
)
```

---

### RelationshipChip

Display relationship types as chips.

```dart
RelationshipChip(
  relationshipType: 'FATHER_OF',
  onTap: () => showRelationshipOptions(),
)

// Static chip (no tap action)
RelationshipChip(
  relationshipType: 'SPOUSE_OF',
)
```

---

## 📸 Image Upload Widget

### Import

```dart
import 'package:myfamilytree/widgets/image_upload_widget.dart';
import 'package:image_picker/image_picker.dart';
```

### ImageUploadWidget

Complete image upload solution with camera/gallery support.

```dart
class _MyScreenState extends State<MyScreen> {
  XFile? _selectedImage;
  bool _isUploading = false;

  Future<void> _handleImageSelected(XFile imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _isUploading = true;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final imageUrl = await api.uploadProfileImage(personId, imageFile);
      // Save imageUrl to database
      setState(() { _isUploading = false; });
    } catch (e) {
      setState(() { _isUploading = false; });
      // Show error
    }
  }

  @override
  Widget build(BuildContext context) {
    return ImageUploadWidget(
      currentImageUrl: person.photoUrl,
      gender: person.gender,
      onImageSelected: _handleImageSelected,
      onImageRemoved: () => setState(() { _selectedImage = null; }),
      size: AppSizing.avatarXl,
    );
  }
}
```

### ImagePreviewDialog

Full-screen image viewer with zoom.

```dart
// Show image preview
ImagePreviewDialog.show(
  context,
  person.photoUrl!,
  person.name,
);
```

---

## 🎨 Layout Patterns

### Responsive Form Layout

```dart
SingleChildScrollView(
  padding: EdgeInsets.all(AppSpacing.lg),
  child: Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AppSizing.maxFormWidth),
      child: Form(
        child: Column(
          children: [
            // Form fields here
          ],
        ),
      ),
    ),
  ),
)
```

### Card-Based Layout

```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(AppSpacing.md),
    child: Column(
      children: [
        // Card content
      ],
    ),
  ),
)
```

### Section with Header and Content

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SectionHeader(title: 'Section Title', icon: Icons.info),
    SizedBox(height: AppSpacing.md),
    Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // Section content
          ],
        ),
      ),
    ),
  ],
)
```

### Grid of Stat Cards

```dart
Row(
  children: [
    Expanded(
      child: _buildStatCard(
        icon: Icons.cake,
        label: 'Age',
        value: '25',
        color: kAccentColor,
      ),
    ),
    SizedBox(width: AppSpacing.sm),
    Expanded(
      child: _buildStatCard(
        icon: Icons.male,
        label: 'Gender',
        value: 'Male',
        color: kMaleColor,
      ),
    ),
    SizedBox(width: AppSpacing.sm),
    Expanded(
      child: _buildStatCard(
        icon: Icons.favorite,
        label: 'Status',
        value: 'Married',
        color: kRelationshipSpouse,
      ),
    ),
  ],
)

Widget _buildStatCard({required IconData icon, required String label, required String value, required Color color}) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: AppSpacing.xs),
          Text(label, style: TextStyle(fontSize: 11, color: kTextSecondary)),
        ],
      ),
    ),
  );
}
```

---

## 🎭 App Bar Patterns

### Standard App Bar

```dart
AppBar(
  title: Text('Screen Title'),
  actions: [
    IconButton(
      icon: Icon(Icons.edit),
      onPressed: () => editAction(),
    ),
    IconButton(
      icon: Icon(Icons.share),
      onPressed: () => shareAction(),
    ),
  ],
)
```

### Sliver App Bar with Gradient

```dart
SliverAppBar(
  expandedHeight: 280,
  pinned: true,
  backgroundColor: kPrimaryColor,
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header content
          ],
        ),
      ),
    ),
  ),
)
```

---

## 🔘 Button Styles

### Elevated Button (Primary Action)

```dart
ElevatedButton(
  onPressed: () => saveAction(),
  child: Text('Save'),
)

// With icon
ElevatedButton.icon(
  onPressed: () => addAction(),
  icon: Icon(Icons.add),
  label: Text('Add Member'),
)

// Loading state
ElevatedButton(
  onPressed: _isLoading ? null : () => action(),
  child: _isLoading
    ? SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      )
    : Text('Submit'),
)
```

### Outlined Button (Secondary Action)

```dart
OutlinedButton(
  onPressed: () => cancelAction(),
  child: Text('Cancel'),
)
```

### Text Button (Tertiary Action)

```dart
TextButton(
  onPressed: () => skipAction(),
  child: Text('Skip'),
)
```

---

## 📝 Form Field Patterns

### Text Field with Icon

```dart
TextFormField(
  controller: _nameController,
  decoration: InputDecoration(
    labelText: 'Full Name *',
    prefixIcon: Icon(Icons.person),
  ),
  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
)
```

### Dropdown

```dart
DropdownButtonFormField<String>(
  value: _selectedValue,
  decoration: InputDecoration(
    labelText: 'Gender',
    prefixIcon: Icon(Icons.wc),
  ),
  items: [
    DropdownMenuItem(value: 'male', child: Text('Male')),
    DropdownMenuItem(value: 'female', child: Text('Female')),
    DropdownMenuItem(value: 'other', child: Text('Other')),
  ],
  onChanged: (v) => setState(() { _selectedValue = v!; }),
)
```

### Date Picker

```dart
InkWell(
  onTap: () async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() { _selectedDate = date; });
  },
  child: InputDecorator(
    decoration: InputDecoration(
      labelText: 'Date of Birth',
      prefixIcon: Icon(Icons.cake),
      suffixIcon: Icon(Icons.calendar_today),
    ),
    child: Text(
      _selectedDate == null
        ? 'Select date'
        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
    ),
  ),
)
```

---

## 🎨 Common Patterns

### Success Message

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Profile updated successfully!')),
)
```

### Error Message

```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: kErrorColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
    border: Border.all(color: kErrorColor.withOpacity(0.3)),
  ),
  child: Row(
    children: [
      Icon(Icons.error_outline, color: kErrorColor),
      SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(_error!, style: TextStyle(color: kErrorColor)),
      ),
    ],
  ),
)
```

### Loading State

```dart
if (_isLoading)
  Center(child: CircularProgressIndicator())
else
  YourContentWidget()
```

---

## 🚀 Complete Example Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../widgets/common_widgets.dart';

class ExampleScreen extends ConsumerStatefulWidget {
  const ExampleScreen({super.key});

  @override
  ConsumerState<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends ConsumerState<ExampleScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example Screen'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => print('Edit'),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              SectionHeader(
                title: 'Profile Information',
                icon: Icons.person,
                action: 'Edit',
                onActionTap: () => print('Edit tapped'),
              ),
              SizedBox(height: AppSpacing.md),

              // Info Card
              InfoCard(
                icon: Icons.info,
                title: 'Important Information',
                subtitle: 'This is some important info',
                iconColor: kInfoColor,
                onTap: () => print('Card tapped'),
              ),

              SizedBox(height: AppSpacing.lg),

              // Details Section
              SectionHeader(title: 'Details', icon: Icons.list),
              SizedBox(height: AppSpacing.md),

              Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      DetailRow(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: '+91 1234567890',
                        iconColor: kSuccessColor,
                      ),
                      DetailRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: 'user@example.com',
                        iconColor: kInfoColor,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.lg),

              // Action Button
              ElevatedButton(
                onPressed: () => setState(() { _isLoading = true; }),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## 📚 Summary

All components are designed to work together seamlessly:

- **Consistent spacing** using `AppSpacing`
- **Consistent sizing** using `AppSizing`
- **Consistent colors** from theme
- **Reusable widgets** for common patterns
- **Responsive layouts** with max-width constraints
- **Loading states** everywhere
- **Error handling** built-in

Just import the components you need and start building beautiful screens! 🎨
