import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api';
  static String get googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
}

/// Shared form-related constants to avoid duplication across screens.
class FormConstants {
  FormConstants._(); // prevent instantiation

  /// All 28 Indian states + 8 union territories, sorted alphabetically.
  static const List<String> indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    // Union Territories
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  /// Country calling codes with labels for phone input.
  static const List<({String code, String label})> countryCodes = [
    (code: '+91', label: 'IN +91'),
    (code: '+1', label: 'US +1'),
    (code: '+44', label: 'UK +44'),
    (code: '+61', label: 'AU +61'),
    (code: '+971', label: 'UAE +971'),
    (code: '+65', label: 'SG +65'),
  ];

  /// All country code strings for parsing phone numbers.
  static List<String> get countryCodeValues =>
      countryCodes.map((c) => c.code).toList();

  /// Gender dropdown options used across forms.
  static const List<DropdownOption> genderOptions = [
    DropdownOption(value: 'male', label: 'Male'),
    DropdownOption(value: 'female', label: 'Female'),
    DropdownOption(value: 'other', label: 'Other'),
  ];

  /// Marital status dropdown options used across forms.
  static const List<DropdownOption> maritalStatusOptions = [
    DropdownOption(value: 'single', label: 'Single'),
    DropdownOption(value: 'married', label: 'Married'),
    DropdownOption(value: 'divorced', label: 'Divorced'),
    DropdownOption(value: 'widowed', label: 'Widowed'),
  ];

  /// Relationship type options for adding family members.
  static const List<DropdownOption> relationshipOptions = [
    DropdownOption(value: 'FATHER_OF', label: 'Father'),
    DropdownOption(value: 'MOTHER_OF', label: 'Mother'),
    DropdownOption(value: 'SPOUSE_OF', label: 'Spouse'),
    DropdownOption(value: 'SIBLING_OF', label: 'Sibling'),
    DropdownOption(value: 'CHILD_OF', label: 'Child'),
  ];
}

/// A simple value-label pair for dropdown menu items.
class DropdownOption {
  const DropdownOption({required this.value, required this.label});
  final String value;
  final String label;

  DropdownMenuItem<String> toMenuItem() =>
      DropdownMenuItem(value: value, child: Text(label));
}
