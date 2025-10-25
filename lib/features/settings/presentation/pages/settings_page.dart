import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../step_tracking/controllers/step_tracking_controller.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../profile/widgets/image_picker_widget.dart';
import '../../../../core/controllers/theme_controller.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../core/services/firebase_storage_test.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _targetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<StepTrackingController>();
      _targetController.text = controller.targetSteps.toString();
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizationService = context.watch<LocalizationService>();
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizationService.getText('settings'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: Consumer<StepTrackingController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Daily Goal Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Daily Goal',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Set your daily step target',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _targetController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Target Steps',
                                hintText: 'Enter daily step goal',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                prefixIcon: const Icon(Icons.directions_walk),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              final newTarget = int.tryParse(_targetController.text);
                              if (newTarget != null && newTarget > 0) {
                                controller.updateTargetSteps(newTarget);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Goal updated to ${_formatSteps(newTarget)} steps'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid number'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Theme Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.dark_mode,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<ThemeController>(
                        builder: (context, themeController, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              Switch(
                                value: themeController.isDarkMode,
                                onChanged: (value) {
                                  themeController.toggleTheme();
                                },
                                activeColor: colorScheme.primary,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<LocalizationService>(
                        builder: (context, localizationService, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Language',
                                style: TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    localizationService.locale.languageCode == 'en' ? 'English' : 'العربية',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: localizationService.locale.languageCode == 'ar',
                                    onChanged: (value) {
                                      localizationService.toggleLanguage();
                                    },
                                    activeColor: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Account Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_circle,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<AuthController>(
                        builder: (context, authController, child) {
                          return Column(
                            children: [
                              // Profile Image Section
                              if (authController.userProfile != null) ...[
                                Center(
                                  child: ImagePickerWidget(
                                    userProfile: authController.userProfile,
                                    size: 100,
                                    onImageUpdated: (updatedProfile) {
                                      if (updatedProfile != null) {
                                        // Update the auth controller with the new profile
                                        authController.updateUserProfile(updatedProfile);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoRow('Name', authController.userProfile!.name, context),
                                _buildInfoRow('Weight', '${authController.userProfile!.weight.toStringAsFixed(1)} kg', context),
                              ],
                              const SizedBox(height: 16),
                              // Storage Test Button (temporary for debugging)
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await FirebaseStorageTest.runStorageTest();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Storage test completed. Check debug console for results.'),
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.storage),
                                label: const Text('Test Storage'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showSignOutDialog(context),
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign Out'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App Info Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'App Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Version', '1.0.0', context),
                      _buildInfoRow('Build', '1', context),
                      _buildInfoRow('Developer', 'Steps Tracker Team', context),
                    ],
                  ),
                ),
                
                // const SizedBox(height: 24),
                
                // // Permissions Section
                // Container(
                //   padding: const EdgeInsets.all(20),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(16),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.grey.withOpacity(0.1),
                //         spreadRadius: 1,
                //         blurRadius: 10,
                //         offset: const Offset(0, 2),
                //       ),
                //     ],
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           Icon(
                //             Icons.security,
                //             color: const Color(0xFF2E7D32),
                //             size: 24,
                //           ),
                //           const SizedBox(width: 12),
                //           const Text(
                //             'Permissions',
                //             style: TextStyle(
                //               fontSize: 18,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ],
                //       ),
                //       const SizedBox(height: 16),
                //       Text(
                //         'This app requires activity recognition permission to track your steps accurately.',
                //         style: TextStyle(
                //           color: Colors.grey.shade600,
                //           fontSize: 14,
                //         ),
                //       ),
                //       const SizedBox(height: 12),
                //       ElevatedButton.icon(
                //         onPressed: () async {
                //           // This would open app settings in a real implementation
                //           ScaffoldMessenger.of(context).showSnackBar(
                //             const SnackBar(
                //               content: Text('Please enable activity recognition in your device settings'),
                //               backgroundColor: Colors.orange,
                //             ),
                //           );
                //         },
                //         icon: const Icon(Icons.settings),
                //         label: const Text('Open Settings'),
                //         style: ElevatedButton.styleFrom(
                //           backgroundColor: Colors.orange,
                //           foregroundColor: Colors.white,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSteps(int steps) {
    return steps.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authController = context.read<AuthController>();
              await authController.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth');
              }
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
