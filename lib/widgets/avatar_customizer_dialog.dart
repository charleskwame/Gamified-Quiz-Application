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

class _AvatarCustomizerDialogState extends State<AvatarCustomizerDialog>
    with SingleTickerProviderStateMixin {
  late Map<String, String> _values;
  bool _isSaving = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  String get _avatarUrl => AvatarOptions.buildUrl(_values);

  @override
  void initState() {
    super.initState();
    _values = AvatarOptions.initialValues(widget.initialDetails);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animController,
            curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
          ),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
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
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF003F91),
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: currentValue,
            items: category.options.map((opt) {
              return DropdownMenuItem(
                value: opt.value,
                child: Text(
                  opt.label,
                  style: const TextStyle(color: Color(0xFF003F91)),
                ),
              );
            }).toList(),
            onChanged: (val) => _update(category.key, val),
            dropdownColor: const Color(0xFFECF8F8),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: const Color(0xFFECF8F8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB0C4DE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB0C4DE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF003F91),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003F91).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Customize Avatar',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: Color(0xFF003F91),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF003F91).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF003F91),
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 34,
                          minHeight: 34,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Scrollable content ──
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Preview with glowing ring ──
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const SweepGradient(
                              colors: [
                                Color(0xFF003F91),
                                Color(0xFF0066CC),
                                Color(0xFF3399FF),
                                Color(0xFF003F91),
                              ],
                              stops: [0.0, 0.33, 0.66, 1.0],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: SvgPicture.network(
                                  _avatarUrl,
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF003F91),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Randomize button ──
                        SizedBox(
                          height: 38,
                          child: FilledButton.icon(
                            onPressed: _randomize,
                            icon: const Icon(Icons.casino_rounded, size: 16),
                            label: const Text('Randomize'),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF003F91),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Category dropdowns ──
                        for (final cat in AvatarOptions.categories)
                          if (!cat.optional ||
                              (_values['clothing'] ?? 'none') != 'none')
                            _buildDropdown(cat),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Action buttons ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(
                          0xFF003F91,
                        ).withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: FilledButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final navigator = Navigator.of(context);
                                setState(() => _isSaving = true);
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
                          backgroundColor: const Color(0xFF003F91),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
