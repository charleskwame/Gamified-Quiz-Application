import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  // DiceBear toon-head options lists (v10.x)
  final List<String> _skinColorOptions = [
    'ffeedd',
    'f5d0b1',
    'e6b88a',
    'd4a574',
    '8d5524',
  ];
  final List<String> _hairOptions = [
    'bald',
    'bob',
    'braids',
    'bun',
    'buzz',
    'curly',
    'dannyPhantom',
    'dougFunny',
    'flatTop',
    'fonze',
    'full',
    'long',
    'mrClean',
    'mrT',
    'pixie',
    'pompadour',
    'shortCurly',
    'shortFlat',
    'shortRound',
    'turban',
    'wave',
    'wide',
  ];
  final List<String> _hairColorOptions = [
    '1a1a1a',
    '4a3728',
    'a5753f',
    'c25a38',
    '707070',
    '305a96',
    'b83098',
    'e8b270',
  ];
  final List<String> _eyesOptions = [
    'eyes',
    'eyesShadow',
    'round',
    'smiling',
    'wide',
  ];
  final List<String> _eyebrowsOptions = [
    'down',
    'eyelashesDown',
    'eyelashesUp',
    'up',
  ];
  final List<String> _mouthOptions = [
    'frown',
    'laughing',
    'nervous',
    'pucker',
    'sad',
    'smile',
    'smirk',
    'surprised',
  ];
  final List<String> _facialHairOptions = [
    'none',
    'beard',
    'scruff',
    'goatee',
    'moustache',
  ];
  final List<String> _glassesOptions = ['none', 'round', 'square', 'wayfarers'];
  final List<String> _clothingOptions = [
    'none',
    'blazer',
    'blazerAndShirt',
    'graphicShirt',
    'hoodie',
    'overall',
    'shirt',
    'vneck',
  ];
  final List<String> _clothingColorOptions = [
    '1a1a1a',
    '4a3728',
    'a5753f',
    'c25a38',
    '707070',
    '305a96',
    'b83098',
    'e8b270',
    '3a7d44',
    '6c4f8c',
    'c4a35a',
  ];

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
          skinColorOptions: _skinColorOptions,
          hairOptions: _hairOptions,
          hairColorOptions: _hairColorOptions,
          eyesOptions: _eyesOptions,
          eyebrowsOptions: _eyebrowsOptions,
          mouthOptions: _mouthOptions,
          facialHairOptions: _facialHairOptions,
          glassesOptions: _glassesOptions,
          clothingOptions: _clothingOptions,
          clothingColorOptions: _clothingColorOptions,
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
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? ClipOval(
                                  child: SvgPicture.network(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    placeholderBuilder: (context) => const Icon(
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
                          onPressed: () =>
                              _openAvatarCustomizer(avatarUrl, avatarDetails),
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
                                        backgroundColor: const Color(
                                          0xFF931716,
                                        ),
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
  final List<String> skinColorOptions;
  final List<String> hairOptions;
  final List<String> hairColorOptions;
  final List<String> eyesOptions;
  final List<String> eyebrowsOptions;
  final List<String> mouthOptions;
  final List<String> facialHairOptions;
  final List<String> glassesOptions;
  final List<String> clothingOptions;
  final List<String> clothingColorOptions;
  final Function(String, Map<String, dynamic>) onSave;

  const _AvatarCustomizerDialog({
    required this.initialUrl,
    required this.initialDetails,
    required this.skinColorOptions,
    required this.hairOptions,
    required this.hairColorOptions,
    required this.eyesOptions,
    required this.eyebrowsOptions,
    required this.mouthOptions,
    required this.facialHairOptions,
    required this.glassesOptions,
    required this.clothingOptions,
    required this.clothingColorOptions,
    required this.onSave,
  });

  @override
  State<_AvatarCustomizerDialog> createState() =>
      _AvatarCustomizerDialogState();
}

class _AvatarCustomizerDialogState extends State<_AvatarCustomizerDialog> {
  late String _seed;
  late String _skinColor;
  late String _hair;
  late String _hairColor;
  late String _eyes;
  late String _eyebrows;
  late String _mouth;
  late String _facialHair;
  late String _glasses;
  late String _clothing;
  late String _clothingColor;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDetails;
    _seed = d?['seed'] ?? _generateRandomSeed();

    final skinColorVal = d?['skinColor'];
    _skinColor = widget.skinColorOptions.contains(skinColorVal)
        ? skinColorVal!
        : widget.skinColorOptions[0];

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

    final glassesVal = d?['glasses'];
    _glasses = widget.glassesOptions.contains(glassesVal)
        ? glassesVal!
        : widget.glassesOptions[0];

    final clothingVal = d?['clothing'];
    _clothing = widget.clothingOptions.contains(clothingVal)
        ? clothingVal!
        : widget.clothingOptions[0];

    final clothingColorVal = d?['clothingColor'];
    _clothingColor = widget.clothingColorOptions.contains(clothingColorVal)
        ? clothingColorVal!
        : widget.clothingColorOptions[0];
  }

  String _generateRandomSeed() {
    final random = Random();
    return List.generate(8, (_) => random.nextInt(10).toString()).join();
  }

  String _buildAvatarUrl() {
    final String facialHairParam = _facialHair == 'none'
        ? 'facialHairProbability=0'
        : 'facialHairProbability=100&facialHair=$_facialHair';

    final String glassesParam = _glasses == 'none'
        ? 'glassesProbability=0'
        : 'glassesProbability=100&glasses=$_glasses';

    final String clothingParam = _clothing == 'none'
        ? ''
        : 'clothing=$_clothing&clothingColor=$_clothingColor';

    return 'https://api.dicebear.com/10.x/toon-head/svg?'
        'seed=$_seed&'
        'skinColor=$_skinColor&'
        'mouth=$_mouth&'
        'eyebrows=$_eyebrows&'
        'eyes=$_eyes&'
        'hair=$_hair&'
        'hairColor=$_hairColor&'
        '$facialHairParam&'
        '$glassesParam&'
        '$clothingParam';
  }

  void _randomize() {
    final random = Random();
    setState(() {
      _seed = _generateRandomSeed();
      _skinColor = widget
          .skinColorOptions[random.nextInt(widget.skinColorOptions.length)];
      _hair = widget.hairOptions[random.nextInt(widget.hairOptions.length)];
      _hairColor = widget
          .hairColorOptions[random.nextInt(widget.hairColorOptions.length)];
      _eyes = widget.eyesOptions[random.nextInt(widget.eyesOptions.length)];
      _eyebrows =
          widget.eyebrowsOptions[random.nextInt(widget.eyebrowsOptions.length)];
      _mouth = widget.mouthOptions[random.nextInt(widget.mouthOptions.length)];
      _facialHair = widget
          .facialHairOptions[random.nextInt(widget.facialHairOptions.length)];
      _glasses =
          widget.glassesOptions[random.nextInt(widget.glassesOptions.length)];
      _clothing =
          widget.clothingOptions[random.nextInt(widget.clothingOptions.length)];
      _clothingColor =
          widget.clothingColorOptions[random.nextInt(
            widget.clothingColorOptions.length,
          )];
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
                if (opt == 'ffeedd') {
                  name = 'Porcelain (Very Light)';
                } else if (opt == 'f5d0b1') {
                  name = 'Peach (Light)';
                } else if (opt == 'e6b88a') {
                  name = 'Golden (Medium)';
                } else if (opt == 'd4a574') {
                  name = 'Tan (Medium Dark)';
                } else if (opt == '8d5524') {
                  name = 'Espresso (Dark)';
                }
              } else if (label == 'Hair Color') {
                if (opt == '1a1a1a') {
                  name = 'Black';
                } else if (opt == '4a3728') {
                  name = 'Brown';
                } else if (opt == 'a5753f') {
                  name = 'Blonde';
                } else if (opt == 'c25a38') {
                  name = 'Red / Auburn';
                } else if (opt == '707070') {
                  name = 'Gray';
                } else if (opt == '305a96') {
                  name = 'Blue';
                } else if (opt == 'b83098') {
                  name = 'Pink';
                } else if (opt == 'e8b270') {
                  name = 'Platinum';
                }
              } else if (label == 'Hair Style') {
                if (opt == 'bald') {
                  name = 'Bald';
                } else if (opt == 'bob') {
                  name = 'Bob';
                } else if (opt == 'braids') {
                  name = 'Braids';
                } else if (opt == 'bun') {
                  name = 'Bun';
                } else if (opt == 'buzz') {
                  name = 'Buzz Cut';
                } else if (opt == 'curly') {
                  name = 'Curly';
                } else if (opt == 'dannyPhantom') {
                  name = 'Danny Phantom (Tousled)';
                } else if (opt == 'dougFunny') {
                  name = 'Doug Funny (Short)';
                } else if (opt == 'flatTop') {
                  name = 'Flat Top';
                } else if (opt == 'fonze') {
                  name = 'Fonze (Greaser)';
                } else if (opt == 'full') {
                  name = 'Full (Afro / Volume)';
                } else if (opt == 'long') {
                  name = 'Long';
                } else if (opt == 'mrClean') {
                  name = 'Mr. Clean (Bald)';
                } else if (opt == 'mrT') {
                  name = 'Mr. T (Mohawk)';
                } else if (opt == 'pixie') {
                  name = 'Pixie';
                } else if (opt == 'pompadour') {
                  name = 'Pompadour';
                } else if (opt == 'shortCurly') {
                  name = 'Short Curly';
                } else if (opt == 'shortFlat') {
                  name = 'Short Flat';
                } else if (opt == 'shortRound') {
                  name = 'Short Round';
                } else if (opt == 'turban') {
                  name = 'Turban';
                } else if (opt == 'wave') {
                  name = 'Wave';
                } else if (opt == 'wide') {
                  name = 'Wide';
                }
              } else if (label == 'Eyes') {
                if (opt == 'eyesShadow') {
                  name = 'Eyes Shadow';
                } else if (opt == 'wide') {
                  name = 'Wide';
                }
              } else if (label == 'Eyebrows') {
                if (opt == 'eyelashesDown') {
                  name = 'Eyelashes Down';
                } else if (opt == 'eyelashesUp') {
                  name = 'Eyelashes Up';
                }
              } else if (label == 'Facial Hair') {
                if (opt == 'goatee') {
                  name = 'Goatee';
                } else if (opt == 'moustache') {
                  name = 'Moustache';
                }
              } else if (label == 'Glasses') {
                if (opt == 'wayfarers') {
                  name = 'Wayfarers';
                }
              } else if (label == 'Clothing') {
                if (opt == 'blazerAndShirt') {
                  name = 'Blazer & Shirt';
                } else if (opt == 'graphicShirt') {
                  name = 'Graphic Shirt';
                } else if (opt == 'vneck') {
                  name = 'V-Neck';
                }
              } else if (label == 'Clothing Color') {
                if (opt == '1a1a1a') {
                  name = 'Black';
                } else if (opt == '4a3728') {
                  name = 'Brown';
                } else if (opt == 'a5753f') {
                  name = 'Blonde / Tan';
                } else if (opt == 'c25a38') {
                  name = 'Red / Auburn';
                } else if (opt == '707070') {
                  name = 'Gray';
                } else if (opt == '305a96') {
                  name = 'Blue';
                } else if (opt == 'b83098') {
                  name = 'Pink';
                } else if (opt == 'e8b270') {
                  name = 'Platinum';
                } else if (opt == '3a7d44') {
                  name = 'Green';
                } else if (opt == '6c4f8c') {
                  name = 'Purple';
                } else if (opt == 'c4a35a') {
                  name = 'Gold';
                }
              }
              return DropdownMenuItem(value: opt, child: Text(name));
            }).toList(),
            onChanged: onChanged,
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
    final avatarUrl = _buildAvatarUrl();

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
              // Preview Box
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
                    avatarUrl,
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

              // Customize parameters
              _buildDropdown('Skin Tone', _skinColor, widget.skinColorOptions, (
                val,
              ) {
                if (val != null) setState(() => _skinColor = val);
              }),
              _buildDropdown('Hair Style', _hair, widget.hairOptions, (val) {
                if (val != null) setState(() => _hair = val);
              }),
              _buildDropdown(
                'Hair Color',
                _hairColor,
                widget.hairColorOptions,
                (val) {
                  if (val != null) setState(() => _hairColor = val);
                },
              ),
              _buildDropdown('Eyes', _eyes, widget.eyesOptions, (val) {
                if (val != null) setState(() => _eyes = val);
              }),
              _buildDropdown('Eyebrows', _eyebrows, widget.eyebrowsOptions, (
                val,
              ) {
                if (val != null) setState(() => _eyebrows = val);
              }),
              _buildDropdown('Mouth', _mouth, widget.mouthOptions, (val) {
                if (val != null) setState(() => _mouth = val);
              }),
              _buildDropdown(
                'Facial Hair',
                _facialHair,
                widget.facialHairOptions,
                (val) {
                  if (val != null) setState(() => _facialHair = val);
                },
              ),
              _buildDropdown('Glasses', _glasses, widget.glassesOptions, (val) {
                if (val != null) setState(() => _glasses = val);
              }),
              _buildDropdown('Clothing', _clothing, widget.clothingOptions, (
                val,
              ) {
                if (val != null) setState(() => _clothing = val);
              }),
              if (_clothing != 'none')
                _buildDropdown(
                  'Clothing Color',
                  _clothingColor,
                  widget.clothingColorOptions,
                  (val) {
                    if (val != null) setState(() => _clothingColor = val);
                  },
                ),
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
                    'skinColor': _skinColor,
                    'hair': _hair,
                    'hairColor': _hairColor,
                    'eyes': _eyes,
                    'eyebrows': _eyebrows,
                    'mouth': _mouth,
                    'facialHair': _facialHair,
                    'glasses': _glasses,
                    'clothing': _clothing,
                    'clothingColor': _clothingColor,
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
