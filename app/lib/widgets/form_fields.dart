import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../config/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StateAutocompleteField
// ─────────────────────────────────────────────────────────────────────────────

/// A text field with autocomplete suggestions for Indian states.
///
/// Uses Flutter's built-in [Autocomplete] widget — no extra packages needed.
/// The user can still type a free-text value that is not in the list; the
/// suggestions are offered but not enforced.
///
/// This is a [StatefulWidget] so that the listener bridging the internal
/// [TextEditingController] to the external one is added/removed correctly,
/// avoiding memory leaks.
class StateAutocompleteField extends StatefulWidget {
  const StateAutocompleteField({
    super.key,
    required this.controller,
    this.decoration,
    this.onSelected,
  });

  /// Controller whose text is kept in sync with the autocomplete value.
  final TextEditingController controller;

  /// Optional decoration override.  When null a sensible default is used.
  final InputDecoration? decoration;

  /// Called when the user taps a suggestion from the overlay.
  final ValueChanged<String>? onSelected;

  @override
  State<StateAutocompleteField> createState() => _StateAutocompleteFieldState();
}

class _StateAutocompleteFieldState extends State<StateAutocompleteField> {
  TextEditingController? _internalController;

  void _syncToExternal() {
    if (_internalController != null &&
        widget.controller.text != _internalController!.text) {
      widget.controller.text = _internalController!.text;
    }
  }

  void _attachListener(TextEditingController internal) {
    if (_internalController == internal) return;
    _internalController?.removeListener(_syncToExternal);
    _internalController = internal;
    _internalController!.addListener(_syncToExternal);
  }

  @override
  void dispose() {
    _internalController?.removeListener(_syncToExternal);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: widget.controller.text),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return FormConstants.indianStates.where(
          (s) => s.toLowerCase().contains(query),
        );
      },
      onSelected: (selection) {
        widget.controller.text = selection;
        widget.onSelected?.call(selection);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        _attachListener(textController);

        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: widget.decoration ??
              const InputDecoration(
                labelText: 'State',
                prefixIcon: Icon(Icons.map),
                helperText: 'Optional',
              ),
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(10),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PhoneInputField
// ─────────────────────────────────────────────────────────────────────────────

/// A phone input field with a country-code dropdown prefix.
///
/// Extracts the duplicated phone-field pattern from all three form screens into
/// a single reusable widget.  The country codes are read from
/// [FormConstants.countryCodes].
class PhoneInputField extends StatelessWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
    this.helperText = 'Required — 10 digits',
    this.validator,
  });

  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;
  final String? helperText;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Phone Number *',
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: countryCode,
              isDense: true,
              items: FormConstants.countryCodes
                  .map((c) => DropdownMenuItem(
                        value: c.code,
                        child: Text(' ${c.code} '),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onCountryCodeChanged(v);
              },
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0),
        helperText: helperText,
        counterText: '',
      ),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      maxLength: 10,
      validator: validator ??
          (v) {
            if (v == null || v.trim().isEmpty) return 'Please enter phone number';
            if (v.trim().length != 10) return 'Must be exactly 10 digits';
            if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Only numbers allowed';
            return null;
          },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DatePickerField
// ─────────────────────────────────────────────────────────────────────────────

/// A consistent, reusable date-picker form field using [InputDecorator].
///
/// Uses [CalendarDatePicker] in a dialog that auto-confirms on selection —
/// the user taps a date and it's immediately applied, no OK button needed.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.icon = Icons.cake,
    this.helperText,
    this.required = false,
  });

  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialDate;
  final IconData icon;
  final String? helperText;
  final bool required;

  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final displayLabel = required ? '$label *' : label;
    final effectiveFirstDate = firstDate ?? DateTime(1920);
    final effectiveLastDate = lastDate ?? DateTime.now();
    final effectiveInitialDate = selectedDate ?? initialDate ?? DateTime(1990);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (ctx) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: kPrimaryColor),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          displayLabel,
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: CalendarDatePicker(
                      initialDate: effectiveInitialDate,
                      firstDate: effectiveFirstDate,
                      lastDate: effectiveLastDate,
                      onDateChanged: (date) {
                        onDateSelected(date);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: displayLabel,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.calendar_today),
          helperText: helperText,
        ),
        child: Text(
          selectedDate == null ? 'Select date' : _displayFormat.format(selectedDate!),
          style: TextStyle(
            color: selectedDate == null ? kTextDisabled : null,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ErrorBanner
// ─────────────────────────────────────────────────────────────────────────────

/// A consistent error message banner used across form screens.
///
/// Replaces the 3 different error-display patterns that were previously
/// copy-pasted with slight variations.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;

  /// If provided, shows a close button that calls this callback.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: kErrorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizing.borderRadiusSm),
        border: Border.all(color: kErrorColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: kErrorColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: kErrorColor, fontSize: 13),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, size: 16, color: kErrorColor),
            ),
        ],
      ),
    );
  }
}
