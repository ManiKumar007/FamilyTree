# Color Theme Update - February 25, 2026

## 🎨 New Sophisticated Color Palette

Your app now uses a **premium indigo & rose gold** color scheme that complements the glassmorphic UI components.

---

## Color Transformation

### Before: Green & White
- **Primary**: Sage Green (#2D6A4F)
- **Secondary**: Slate Blue (#3D5A80) 
- **Accent**: Warm Coral (#E76F51)
- **Background**: Off-White (#F8F9FA)

### After: Indigo & Rose Gold
- **Primary**: Royal Indigo (#4A5899) - Premium, heritage feel
- **Secondary**: Dusty Rose (#B87E85) - Luxurious, warm
- **Accent**: Warm Amber (#FF8C42) - Energetic, modern
- **Background**: Creamy White (#FAF9F8) - Rich, sophisticated

---

## Complete Color Reference

### Primary Colors (Indigo Family)
```
kPrimaryColor      = #4A5899  // Royal Indigo
kPrimaryLight      = #7B86C8  // Soft Periwinkle
kPrimaryDark       = #2D3561  // Midnight Indigo
```

### Secondary Colors (Rose Gold)
```
kSecondaryColor    = #B87E85  // Dusty Rose
kSecondaryLight    = #E5B5BA  // Pale Blush
kSecondaryDark     = #8A5A5F  // Deep Mauve
```

### Accent Colors (Amber)
```
kAccentColor       = #FF8C42  // Warm Amber
kAccentLight       = #FFB976  // Golden Peach
kAccentDark        = #E66A1E  // Deep Orange
```

### Neutrals (Warm Sophisticated)
```
kBackgroundColor   = #FAF9F8  // Creamy White
kSurfaceColor      = #FFFFFF  // Pure White
kSurfaceSecondary  = #F5F3F2  // Warm Linen
kDividerColor      = #E6E3E1  // Soft Taupe
kTextPrimary       = #1C1917  // Rich Black
kTextSecondary     = #78716C  // Warm Stone
kTextDisabled      = #A8A29E  // Light Stone
```

### Sidebar Colors
```
kSidebarBg         = #2D3561  // Midnight Indigo
kSidebarBgLight    = #4A5899  // Royal Indigo
kSidebarText       = #E8E7F3  // Pale Lavender
kSidebarActive     = #7B86C8  // Active Periwinkle
```

### Gender Colors (Unchanged - Modern)
```
kMaleColor         = #5B9BD5  // Soft Blue
kFemaleColor       = #E8799A  // Soft Rose
kOtherColor        = #9575CD  // Soft Violet
```

### Status Colors (Unchanged - Universal)
```
kSuccessColor      = #40C057  // Fresh Green
kWarningColor      = #FFB020  // Warm Amber
kErrorColor        = #E03E3E  // Clean Red
kInfoColor         = #339AF0  // Clear Blue
```

---

## Updated Gradients

### Hero Gradient (Landing Pages)
- Deep indigo → Midnight → Royal Indigo → Periwinkle
- Creates depth and sophistication

### Primary Button
- Royal Indigo → Soft Periwinkle
- Subtle, elegant transition

### CTA Gradient
- Midnight Indigo → Royal Indigo → Warm Amber
- Combines brand colors with energy

### Features Background
- Lavender tint → Blush tint → Cream
- Soft, welcoming gradient

### Card Headers
- Pale lavender → White
- Subtle, professional

---

## Visual Impact

### What Changes You'll See:

✅ **Buttons & Primary Actions**
- Rich royal indigo instead of sage green
- Glassmorphic effect shows purple/blue hues

✅ **Sidebar/Navigation**
- Deep midnight indigo instead of forest green
- More premium, executive feel

✅ **Accents & CTAs**
- Warm amber instead of coral
- More energetic and attention-grabbing

✅ **Backgrounds**
- Creamy white with warm undertones
- More sophisticated than stark white

✅ **Text & Dividers**
- Warm stone tones instead of cool grays
- Better harmony with indigo/rose palette

✅ **Feature Cards**
- Lavender/blush tints in glassmorphic components
- Luxurious, premium appearance

---

## Color Psychology

### Why This Palette?

**Royal Indigo (Primary)**
- Conveys: Trust, wisdom, heritage, tradition
- Perfect for: Family history, genealogy, legacy
- Premium feel without being corporate

**Dusty Rose (Secondary)**
- Conveys: Warmth, connection, family bonds
- Perfect for: Humanizing the interface
- Luxurious, sophisticated

**Warm Amber (Accent)**
- Conveys: Energy, optimism, action
- Perfect for: CTAs, notifications, highlights
- Draws attention without aggression

**Warm Neutrals**
- Conveys: Elegance, quality, timelessness
- Perfect for: Readability, sophistication
- Creates premium app experience

---

## Testing the New Colors

### Hot Reload
```bash
cd app
flutter run
# Press 'r' to hot reload and see new colors
```

### Key Screens to Check
1. **Dashboard** - Button colors, feature cards
2. **Profile** - Header gradient, glassmorphic cards
3. **Family List** - List items, animated cards
4. **Sidebar** - Navigation background
5. **Landing Page** - Hero gradient, CTA buttons

---

## Customization

If you want to adjust any colors, edit [theme.dart](../app/lib/config/theme.dart):

```dart
// Change primary to different shade
const Color kPrimaryColor = Color(0xFF5A68A9); // Lighter indigo

// Change accent to different tone
const Color kAccentColor = Color(0xFFFF9F5A); // Lighter amber

// Adjust background warmer/cooler
const Color kBackgroundColor = Color(0xFFFCFBFA); // Warmer cream
```

---

## Color Harmony Guide

### Recommended Combinations

**Premium Hero Sections**
- Background: `AppGradients.heroRich`
- Text: White overlays
- Buttons: `AppGradients.warmAccent`

**Feature Showcases**
- Cards: `FeatureCard` with `iconColor: kPrimaryColor`
- Background: `AppGradients.featuresBg`
- CTAs: `kAccentColor`

**Data Displays**
- Stats cards: `kPrimaryColor`, `kSecondaryColor`, `kAccentColor`
- Text: `kTextPrimary` on light, white on gradients
- Icons: Match stats card color

**Forms & Inputs**
- Borders: `kDividerColor`
- Focus: `kPrimaryColor`
- Error: `kErrorColor`
- Background: `kSurfaceColor`

---

## Before & After Examples

### Button
```dart
// Now renders with royal indigo gradient
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: kPrimaryColor, // Royal Indigo!
  ),
  onPressed: () {},
  child: Text('Add Family Member'),
)
```

### Glassmorphic Card
```dart
// Beautiful indigo-tinted glass effect
FeatureCard(
  icon: Icons.family_restroom,
  title: 'Family Tree',
  iconColor: kPrimaryColor, // Royal Indigo glow!
)
```

### Stats Display
```dart
// Mix primary, secondary, accent
GlassStatsCard(
  label: 'Members',
  value: '24',
  color: kPrimaryColor, // Indigo
)

GlassStatsCard(
  label: 'Events',
  value: '12',
  color: kSecondaryColor, // Dusty Rose
)

GlassStatsCard(
  label: 'Photos',
  value: '156',
  color: kAccentColor, // Warm Amber
)
```

---

## Summary

**From**: Simple green & white
**To**: Sophisticated indigo, rose gold & amber

**Result**: Premium, heritage-focused, modern family tree app that looks as rich as it functions! 🎨✨
