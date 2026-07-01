import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/avatar_options.dart';

class AvatarCustomizerDialog extends StatefulWidget {
  final String? initialUrl;
  final Map<String, dynamic>? initialDetails;
  final Future<void> Function(String url, Map<String, dynamic> details) onSave;

  const AvatarCustomizerDialog({
    super.key,
    required this.initialUrl,
    required this.initialDetails,
    required this.onSave,
  });

  @override
  State<AvatarCustomizerDialog> createState() => _AvatarCustomizerDialogState();
}

class _AvatarCustomizerDialogState extends State<AvatarCustomizerDialog> {
  late Map<String, String> _values;
  bool _isSaving = false;

  String get _avatarUrl => AvatarOptions.buildUrl(_values);

  @override
  void initState() {
    super.initState();
    _values = AvatarOptions.initialValues(widget.initialDetails);
  }

  void _randomize() {
    setState(() {
      _values = AvatarOptions.randomize();
    });
  }

  void _update(String key, String? value) {
    if (value == null) return;
    setState(() => _values[key] = value);
  }

  Widget _buildDropdown(AvatarCategory category) {
    final currentValue = _values[category.key] ?? category.options.first.value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: currentValue,
            items: category.options.map((opt) {
              return DropdownMenuItem(value: opt.value, child: Text(opt.label));
            }).toList(),
            onChanged: (val) => _update(category.key, val),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 24.0,
      ),
      title: const Text(
        'Customize Avatar',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Preview
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE6EAF2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SvgPicture.network(
                    _avatarUrl,
                    fit: BoxFit.cover,
                    placeholderBuilder: (context) => const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF141053),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _randomize,
                    icon: const Icon(Icons.casino_rounded, size: 16),
                    label: const Text('Randomize'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category dropdowns
              for (final cat in AvatarOptions.categories)
                if (!cat.optional || (_values['clothing'] ?? 'none') != 'none')
                  _buildDropdown(cat),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  setState(() => _isSaving = true);
                  // Reconstruct the details map to exclude internal keys like 'seed'
                  final Map<String, dynamic> details = {
                    for (final cat in AvatarOptions.categories)
                      cat.key: _values[cat.key],
                  };
                  details['seed'] = _values['seed'];
                  try {
                    await widget.onSave(_avatarUrl, details);
                    if (mounted) {
                      navigator.pop();
                    }
                  } catch (e) {
                    debugPrint('Error saving avatar: $e');
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF141053),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
