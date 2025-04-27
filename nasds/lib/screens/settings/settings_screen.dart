import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_constants.dart';
import '../../extensions/string_extensions.dart';
import '../../models/language.dart';
import '../../providers/translation_provider.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  bool _autoSyncEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr()),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('appearance'.tr()),
          _buildThemeToggle(),
          _buildLanguageSelector(),
          const Divider(height: 32),
          _buildSectionHeader('notifications'.tr()),
          _buildNotificationToggle(),
          const Divider(height: 32),
          _buildSectionHeader('data_sync'.tr()),
          _buildAutoSyncToggle(),
          _buildClearCacheButton(),
          const Divider(height: 32),
          _buildSectionHeader('account'.tr()),
          _buildChangePasswordButton(),
          _buildLogoutButton(),
          const Divider(height: 32),
          _buildSectionHeader('about'.tr()),
          _buildAboutListTile(),
          _buildVersionInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return SwitchListTile(
      title: Text('dark_mode'.tr()),
      subtitle: Text('theme_switch_description'.tr()),
      secondary: const Icon(FontAwesomeIcons.moon),
      value: _isDarkMode,
      onChanged: (value) {
        setState(() {
          _isDarkMode = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isDarkMode
                ? 'dark_mode_enabled'.tr()
                : 'light_mode_enabled'.tr()),
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
    final translationProvider = Provider.of<TranslationProvider>(context);
    final currentLanguage = translationProvider.currentLanguage;

    return ListTile(
      leading: const Icon(FontAwesomeIcons.language),
      title: Text('language'.tr()),
      subtitle: Text(currentLanguage.localizedName),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        _showLanguageSelectionDialog();
      },
    );
  }

  void _showLanguageSelectionDialog() {
    final translationProvider =
        Provider.of<TranslationProvider>(context, listen: false);
    final currentLanguage = translationProvider.currentLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('select_language'.tr()),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: SupportedLanguages.supportedLanguages.length,
            itemBuilder: (context, index) {
              final language = SupportedLanguages.supportedLanguages[index];
              final isSelected = language.code == currentLanguage.code;

              return ListTile(
                leading: isSelected
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : const SizedBox(width: 24),
                title: Text(language.localizedName),
                subtitle: Text(language.name),
                onTap: () async {
                  // Store context references before any async operations
                  final currentContext = context;
                  final navigatorContext = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  // Close the language selection dialog
                  navigatorContext.pop();

                  // Show loading indicator
                  if (mounted) {
                    showDialog(
                      context: currentContext,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text('loading'.tr()),
                          ],
                        ),
                      ),
                    );
                  }

                  // Change language
                  await translationProvider.changeLanguage(language);

                  // Close loading dialog and show success message
                  if (mounted) {
                    navigatorContext.pop();

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('language_changed'.tr()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return SwitchListTile(
      title: Text('enable_notifications'.tr()),
      subtitle: Text('notifications_description'.tr()),
      secondary: const Icon(FontAwesomeIcons.bell),
      value: _notificationsEnabled,
      onChanged: (value) {
        setState(() {
          _notificationsEnabled = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? 'notifications_enabled'.tr()
                  : 'notifications_disabled'.tr(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAutoSyncToggle() {
    return SwitchListTile(
      title: Text('auto_sync'.tr()),
      subtitle: Text('auto_sync_description'.tr()),
      secondary: const Icon(FontAwesomeIcons.arrowsRotate),
      value: _autoSyncEnabled,
      onChanged: (value) {
        setState(() {
          _autoSyncEnabled = value;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'auto_sync_enabled'.tr() : 'auto_sync_disabled'.tr(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClearCacheButton() {
    return ListTile(
      leading: const Icon(FontAwesomeIcons.broom),
      title: Text('clear_cache'.tr()),
      subtitle: Text('clear_cache_description'.tr()),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('clear_cache'.tr()),
            content: Text('clear_cache_confirmation'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  // Store context references before any async operations
                  final currentContext = context;
                  final navigatorContext = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  // Close the confirmation dialog
                  navigatorContext.pop();

                  // Show loading indicator
                  showDialog(
                    context: currentContext,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      content: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Text('clearing_cache'.tr()),
                        ],
                      ),
                    ),
                  );

                  // Simulate clearing cache
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      navigatorContext.pop();

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('cache_cleared'.tr()),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  });
                },
                child: Text('clear'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangePasswordButton() {
    return ListTile(
      leading: const Icon(FontAwesomeIcons.key),
      title: Text('change_password'.tr()),
      subtitle: Text('change_password_description'.tr()),
      onTap: () {
        // Show change password dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('change_password'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'current_password'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'new_password'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'confirm_new_password'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('password_change_success'.tr()),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: Text('change_password'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(FontAwesomeIcons.rightFromBracket, color: Colors.red),
      title: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('logout'.tr()),
            content: Text('logout_confirmation'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _authService.logout();

                  // Navigate to login screen
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('logout'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutListTile() {
    return ListTile(
      leading: const Icon(FontAwesomeIcons.circleInfo),
      title: Text('about_app'.tr()),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('about_app'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/nasds_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'app_description'.tr(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'app_powered_by'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'copyright'.tr(args: {'year': AppConstants.currentYear}),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('close'.tr()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return ListTile(
      leading: const Icon(FontAwesomeIcons.code),
      title: Text('version'.tr()),
      subtitle: Text(
          '${AppConstants.appVersion} (${AppConstants.appPlatform} - ${AppConstants.appDeviceName})'),
    );
  }
}
