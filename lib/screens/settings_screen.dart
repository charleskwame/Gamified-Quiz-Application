import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // DiceBear Micah options lists (v9)
  final List<String> _baseColorOptions = [
    'f3d1c1',
    'f7c3a0',
    'e28d75',
    'b86c52',
    '9c5b42'
  ];
  final List<String> _hairOptions = [
    'dannyPhantom',
    'dougFunny',
    'fonze',
    'full',
    'mrClean',
    'mrT',
    'pixie',
    'turban'
  ];
  final List<String> _hairColorOptions = [
    '4a3728',
    '1a1a1a',
    'a5753f',
    'c25a38',
    '707070',
    '305a96',
    'b83098'
  ];
  final List<String> _eyesOptions = [
    'eyes',
    'eyesShadow',
    'round',
    'smiling'
  ];
  final List<String> _eyebrowsOptions = [
    'down',
    'eyelashesDown',
    'eyelashesUp',
    'up'
  ];
  final List<String> _mouthOptions = [
    'frown',
    'laughing',
    'nervous',
    'pucker',
    'sad',
    'smile',
    'smirk',
    'surprised'
  ];
  final List<String> _facialHairOptions = ['none', 'beard', 'scruff'];

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateAccountInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.updateProfile(
        displayName: _displayNameController.text.trim(),
        email: null,
        password: null,
      );
      setState(() {
        _successMessage = 'Account information updated successfully!';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openAvatarCustomizer(
    String? currentUrl,
    Map<String, dynamic>? currentDetails,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _AvatarCustomizerDialog(
          initialUrl: currentUrl,
          initialDetails: currentDetails,
          baseColorOptions: _baseColorOptions,
          hairOptions: _hairOptions,
          hairColorOptions: _hairColorOptions,
          eyesOptions: _eyesOptions,
          eyebrowsOptions: _eyebrowsOptions,
          mouthOptions: _mouthOptions,
          facialHairOptions: _facialHairOptions,
          onSave: (url, details) async {
            final user = _authService.currentUser;
            if (user != null) {
              final messenger = ScaffoldMessenger.of(context);
              await _dbService.updateAvatar(user.uid, url, details);
              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Avatar saved successfully!'),
                    backgroundColor: Color(0xFF141053),
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to edit settings.')),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String? avatarUrl;
        Map<String, dynamic>? avatarDetails;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          avatarUrl = data['avatarUrl'];
          if (data['avatarDetails'] != null) {
            avatarDetails = Map<String, dynamic>.from(data['avatarDetails']);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF121826),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFE6EAF2),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.person_rounded,
                                              size: 60,
                                              color: Color(0xFF141053),
                                            ),
                                  ),
                                )
                              : const Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: Color(0xFF141053),
                                ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openAvatarCustomizer(
                            avatarUrl,
                            avatarDetails,
                          ),
                          icon: const Icon(
                            Icons.face_retouching_natural_rounded,
                            size: 18,
                            color: Color(0xFF141053),
                          ),
                          label: const Text(
                            'Customize Avatar',
                            style: TextStyle(
                              color: Color(0xFF141053),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF141053)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  Text(
                    'Update Account Info',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF121826),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_successMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        _successMessage!,
                        style: TextStyle(color: Colors.green.shade700),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _updateAccountInfo,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF141053),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF931716),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text(
                                    'Delete Account?',
                                    style: TextStyle(
                                      color: Color(0xFF931716),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'Warning: This action is irreversible. Your entire progress, achievements, points, earned badges, and offline saved questions will be permanently deleted from the system.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () async {
                                      final navigator = Navigator.of(context);
                                      navigator.pop();
                                      setState(() {
                                        _isLoading = true;
                                        _errorMessage = null;
                                        _successMessage = null;
                                      });
                                      try {
                                        final uid = user.uid;
                                        await DatabaseService()
                                            .deleteUserAccount(uid);
                                        await user.delete();
                                        await _authService.logOut();
                                        if (mounted) {
                                          navigator.pop(); // Exit settings
                                        }
                                      } catch (e) {
                                          setState(() {
                                            _errorMessage =
                                                'Failed to delete account: $e. For security, please log out, log back in, and try again.';
                                          });
                                        } finally {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFF931716),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Delete Permanently'),
                                    ),
                                  ],
                                ),
                              );
                            },
                      icon: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFF931716),
                      ),
                      label: const Text(
                        'Delete Account',
                        style: TextStyle(color: Color(0xFF931716)),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFF931716)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AvatarCustomizerDialog extends StatefulWidget {
  final String? initialUrl;
  final Map<String, dynamic>? initialDetails;
  final List<String> baseColorOptions;
  final List<String> hairOptions;
  final List<String> hairColorOptions;
  final List<String> eyesOptions;
  final List<String> eyebrowsOptions;
  final List<String> mouthOptions;
  final List<String> facialHairOptions;
  final Function(String, Map<String, dynamic>) onSave;

  const _AvatarCustomizerDialog({
    required this.initialUrl,
    required this.initialDetails,
    required this.baseColorOptions,
    required this.hairOptions,
    required this.hairColorOptions,
    required this.eyesOptions,
    required this.eyebrowsOptions,
    required this.mouthOptions,
    required this.facialHairOptions,
    required this.onSave,
  });

  @override
  State<_AvatarCustomizerDialog> createState() => _AvatarCustomizerDialogState();
}

class _AvatarCustomizerDialogState extends State<_AvatarCustomizerDialog> {
  late String _seed;
  late String _baseColor;
  late String _hair;
  late String _hairColor;
  late String _eyes;
  late String _eyebrows;
  late String _mouth;
  late String _facialHair;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDetails;
    _seed = d?['seed'] ?? _generateRandomSeed();

    final baseColorVal = d?['baseColor'];
    _baseColor = widget.baseColorOptions.contains(baseColorVal)
        ? baseColorVal!
        : widget.baseColorOptions[0];

    final hairVal = d?['hair'];
    _hair = widget.hairOptions.contains(hairVal)
        ? hairVal!
        : widget.hairOptions[0];

    final hairColorVal = d?['hairColor'];
    _hairColor = widget.hairColorOptions.contains(hairColorVal)
        ? hairColorVal!
        : widget.hairColorOptions[0];

    final eyesVal = d?['eyes'];
    _eyes = widget.eyesOptions.contains(eyesVal)
        ? eyesVal!
        : widget.eyesOptions[0];

    final eyebrowsVal = d?['eyebrows'];
    _eyebrows = widget.eyebrowsOptions.contains(eyebrowsVal)
        ? eyebrowsVal!
        : widget.eyebrowsOptions[0];

    final mouthVal = d?['mouth'];
    _mouth = widget.mouthOptions.contains(mouthVal)
        ? mouthVal!
        : widget.mouthOptions[0];

    final facialHairVal = d?['facialHair'];
    _facialHair = widget.facialHairOptions.contains(facialHairVal)
        ? facialHairVal!
        : widget.facialHairOptions[0];
  }

  String _generateRandomSeed() {
    final random = Random();
    return List.generate(8, (_) => random.nextInt(10).toString()).join();
  }

  String _buildAvatarUrl() {
    final String facialHairParam = _facialHair == 'none'
        ? 'facialHairProbability=0'
        : 'facialHairProbability=100&facialHair=$_facialHair';

    return 'https://api.dicebear.com/9.x/micah/png?'
        'seed=$_seed&'
        'baseColor=$_baseColor&'
        'mouth=$_mouth&'
        'eyebrows=$_eyebrows&'
        'eyes=$_eyes&'
        'hair=$_hair&'
        'hairColor=$_hairColor&'
        '$facialHairParam';
  }

  void _randomize() {
    final random = Random();
    setState(() {
      _seed = _generateRandomSeed();
      _baseColor = widget.baseColorOptions[random.nextInt(widget.baseColorOptions.length)];
      _hair = widget.hairOptions[random.nextInt(widget.hairOptions.length)];
      _hairColor = widget.hairColorOptions[random.nextInt(widget.hairColorOptions.length)];
      _eyes = widget.eyesOptions[random.nextInt(widget.eyesOptions.length)];
      _eyebrows = widget.eyebrowsOptions[random.nextInt(widget.eyebrowsOptions.length)];
      _mouth = widget.mouthOptions[random.nextInt(widget.mouthOptions.length)];
      _facialHair = widget.facialHairOptions[random.nextInt(widget.facialHairOptions.length)];
    });
  }

  Widget _buildDropdown(
    String label,
    String currentValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            initialValue: currentValue,
            items: options.map((opt) {
              String name = opt[0].toUpperCase() + opt.substring(1);
              if (label == 'Skin Tone') {
                if (opt == 'f3d1c1') { name = 'Peach (Very Light)'; }
                else if (opt == 'f7c3a0') { name = 'Apricot (Light)'; }
                else if (opt == 'e28d75') { name = 'Bronze (Medium)'; }
                else if (opt == 'b86c52') { name = 'Clay (Medium Dark)'; }
                else if (opt == '9c5b42') { name = 'Espresso (Dark)'; }
              } else if (label == 'Hair Color') {
                if (opt == '4a3728') { name = 'Brown'; }
                else if (opt == '1a1a1a') { name = 'Black'; }
                else if (opt == 'a5753f') { name = 'Blonde'; }
                else if (opt == 'c25a38') { name = 'Red / Auburn'; }
                else if (opt == '707070') { name = 'Gray'; }
                else if (opt == '305a96') { name = 'Blue'; }
                else if (opt == 'b83098') { name = 'Pink'; }
              } else if (label == 'Hair Style') {
                if (opt == 'dannyPhantom') { name = 'Danny Phantom (Tousled)'; }
                else if (opt == 'dougFunny') { name = 'Doug Funny (Short)'; }
                else if (opt == 'fonze') { name = 'Fonze (Greaser Wave)'; }
                else if (opt == 'full') { name = 'Full Hair (Afro / Volume)'; }
                else if (opt == 'mrClean') { name = 'Mr. Clean (Bald)'; }
                else if (opt == 'mrT') { name = 'Mr. T (Mohawk)'; }
                else if (opt == 'pixie') { name = 'Pixie (Short Curly)'; }
                else if (opt == 'turban') { name = 'Turban'; }
              } else if (label == 'Eyes') {
                if (opt == 'eyesShadow') { name = 'Eyes Shadow'; }
              } else if (label == 'Eyebrows') {
                if (opt == 'eyelashesDown') { name = 'Eyelashes Down'; }
                else if (opt == 'eyelashesUp') { name = 'Eyelashes Up'; }
              }
              return DropdownMenuItem(
                value: opt,
                child: Text(name),
              );
            }).toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    final avatarUrl = _buildAvatarUrl();

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
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
              // Preview Box
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6EAF2), width: 1.5),
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
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF141053)),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image_rounded, color: Color(0xFF141053), size: 40),
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

              // Customize parameters
              _buildDropdown('Skin Tone', _baseColor, widget.baseColorOptions, (val) {
                if (val != null) setState(() => _baseColor = val);
              }),
              _buildDropdown('Hair Style', _hair, widget.hairOptions, (val) {
                if (val != null) setState(() => _hair = val);
              }),
              _buildDropdown('Hair Color', _hairColor, widget.hairColorOptions, (val) {
                if (val != null) setState(() => _hairColor = val);
              }),
              _buildDropdown('Eyes', _eyes, widget.eyesOptions, (val) {
                if (val != null) setState(() => _eyes = val);
              }),
              _buildDropdown('Eyebrows', _eyebrows, widget.eyebrowsOptions, (val) {
                if (val != null) setState(() => _eyebrows = val);
              }),
              _buildDropdown('Mouth', _mouth, widget.mouthOptions, (val) {
                if (val != null) setState(() => _mouth = val);
              }),
              _buildDropdown('Facial Hair', _facialHair, widget.facialHairOptions, (val) {
                if (val != null) setState(() => _facialHair = val);
              }),
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
                      final Map<String, dynamic> details = {
                        'seed': _seed,
                        'baseColor': _baseColor,
                        'hair': _hair,
                        'hairColor': _hairColor,
                        'eyes': _eyes,
                        'eyebrows': _eyebrows,
                        'mouth': _mouth,
                        'facialHair': _facialHair,
                      };
                      try {
                        await widget.onSave(avatarUrl, details);
                        if (mounted) {
                          navigator.pop(); // Close customizer dialog
                        }
                      } catch (e) {
                    debugPrint('Error saving avatar: $e');
                  } finally {
                    if (mounted) {
                      setState(() => _isSaving = false);
                    }
                  }
                },
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF141053)),
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
