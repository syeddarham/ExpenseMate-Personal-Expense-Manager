import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../components/app_bar.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/currency_service.dart';
import '../../services/expense_state.dart';
import '../../utils/constants.dart';
import '../../utils/currencies_data.dart';
import '../category/categories_page.dart';
import '../login/login_page.dart';

/// Screen 06: Profile & Account Settings
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _biometricEnabled = true;
  Uint8List? _cachedPfpBytes;
  bool _isLoadingPfp = false;

  @override
  void initState() {
    super.initState();
    _loadCachedPfp();
  }

  /// Load cached profile picture from SharedPreferences or user model for instant retrieval
  Future<void> _loadCachedPfp() async {
    try {
      final user = AuthService().currentUser;
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_pfp_${user?.id ?? "me"}';
      final cachedStr = prefs.getString(key);

      if (cachedStr != null && cachedStr.isNotEmpty) {
        final clean = cachedStr.contains(',') ? cachedStr.split(',').last : cachedStr;
        if (mounted) {
          setState(() {
            _cachedPfpBytes = base64Decode(clean);
          });
        }
      } else if (user?.avatarUrl != null && (user!.avatarUrl?.isNotEmpty ?? false)) {
        final av = user.avatarUrl!;
        if (av.startsWith('data:image') || av.length > 80) {
          final clean = av.contains(',') ? av.split(',').last : av;
          final bytes = base64Decode(clean);
          if (mounted) {
            setState(() {
              _cachedPfpBytes = bytes;
            });
          }
          await prefs.setString(key, av);
        }
      }
    } catch (_) {}
  }

  /// Pick image, cache locally, and store in MySQL database
  Future<void> _pickAndUploadPfp() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final List<PlatformFile> files = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (files.isEmpty) return;

      final file = files.first;
      final bytes = await file.xFile.readAsBytes();

      if (bytes.isEmpty) return;

      setState(() {
        _isLoadingPfp = true;
        _cachedPfpBytes = bytes;
      });

      final ext = file.extension?.toLowerCase() ?? 'png';
      final base64Str = 'data:image/$ext;base64,${base64Encode(bytes)}';

      // 1. Instant local cache in SharedPreferences
      final user = AuthService().currentUser;
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_pfp_${user?.id ?? "me"}';
      await prefs.setString(key, base64Str);

      // 2. Persist to MySQL database
      final updatedUser = await ApiService.updateMe(avatarUrl: base64Str);
      if (updatedUser != null) {
        AuthService().currentUser = updatedUser;
      }

      messenger.showSnackBar(
        SnackBar(
          content: const Text('Profile picture updated and saved!'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update picture: $e'),
          backgroundColor: AppColors.expense,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingPfp = false);
    }
  }

  /// Remove profile picture
  Future<void> _removePfp() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _cachedPfpBytes = null;
    });
    try {
      final user = AuthService().currentUser;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_pfp_${user?.id ?? "me"}');
      final updatedUser = await ApiService.updateMe(avatarUrl: '');
      if (updatedUser != null) {
        AuthService().currentUser = updatedUser;
      }
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Profile picture removed'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (_) {}
  }

  /// Modal to choose avatar action
  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Profile Picture',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20),
                  ),
                  title: const Text('Choose from Device / Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('JPG, PNG, or WEBP image', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPfp();
                  },
                ),
                if (_cachedPfpBytes != null || (AuthService().currentUser?.avatarUrl?.isNotEmpty ?? false))
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFEE2E2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_outline, color: AppColors.expense, size: 20),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.expense)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removePfp();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog to edit user's Name & Email
  void _showEditProfileDialog(BuildContext context, User? currentUser) {
    final nameCtrl = TextEditingController(text: currentUser?.name ?? '');
    final emailCtrl = TextEditingController(text: currentUser?.email ?? '');
    final messenger = ScaffoldMessenger.of(context);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(Icons.edit_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Your Full Name',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'your.email@example.com',
                      prefixIcon: const Icon(Icons.mail_outline, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final newName = nameCtrl.text.trim();
                          final newEmail = emailCtrl.text.trim();

                          if (newName.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Please enter your name'), backgroundColor: AppColors.expense),
                            );
                            return;
                          }
                          if (newEmail.isEmpty || !newEmail.contains('@') || !newEmail.contains('.')) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Please enter a valid email address'), backgroundColor: AppColors.expense),
                            );
                            return;
                          }

                          setDlgState(() => isSaving = true);
                          final updated = await ApiService.updateMe(fullName: newName, email: newEmail);
                          setDlgState(() => isSaving = false);

                          if (updated != null) {
                            AuthService().currentUser = updated;
                            Navigator.pop(dlgCtx);
                            if (mounted) {
                              setState(() {});
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: const Text('Profile details updated successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update profile. Email may already be in use.'),
                                backgroundColor: AppColors.expense,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog to Change Password
  void _showChangePasswordDialog(BuildContext context) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(Icons.lock_reset, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: currentPassCtrl,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        hintText: 'Enter current password',
                        prefixIcon: const Icon(Icons.lock_outline, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setDlgState(() => obscureCurrent = !obscureCurrent),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('New Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: newPassCtrl,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        hintText: 'At least 6 characters',
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setDlgState(() => obscureNew = !obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirmPassCtrl,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setDlgState(() => obscureConfirm = !obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final currentP = currentPassCtrl.text.trim();
                          final newP = newPassCtrl.text.trim();
                          final confirmP = confirmPassCtrl.text.trim();

                          if (currentP.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Please enter your current password'), backgroundColor: AppColors.expense),
                            );
                            return;
                          }
                          if (newP.length < 6) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('New password must be at least 6 characters'), backgroundColor: AppColors.expense),
                            );
                            return;
                          }
                          if (newP != confirmP) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('New passwords do not match'), backgroundColor: AppColors.expense),
                            );
                            return;
                          }

                          setDlgState(() => isSaving = true);
                          final res = await ApiService.changePassword(
                            currentPassword: currentP,
                            newPassword: newP,
                          );
                          setDlgState(() => isSaving = false);

                          if (res['success'] == true) {
                            Navigator.pop(dlgCtx);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['message'] as String? ?? 'Password updated successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['error'] as String? ?? 'Failed to update password'),
                                backgroundColor: AppColors.expense,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Bottom Sheet to Choose App Primary Color
  void _showColorPickerSheet(BuildContext context, ExpenseState expenseState) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Choose App Primary Color',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Select your preferred accent color for buttons, charts, and highlights across the entire app.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: AppColors.primaryPalette.length,
                  itemBuilder: (cCtx, idx) {
                    final item = AppColors.primaryPalette[idx];
                    final color = item['color'] as Color;
                    final name = item['name'] as String;
                    final isSelected = expenseState.primaryColor.toARGB32() == color.toARGB32();

                    return InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await expenseState.setPrimaryColor(color);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Primary color updated to $name!'),
                              backgroundColor: color,
                            ),
                          );
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? color.withAlpha(25) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(
                            color: isSelected ? color : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withAlpha(70),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white, size: 22)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? color : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Dialog to Export Transactions & Send to Email via SMTP
  void _showExportDialog(BuildContext context, ExpenseState expenseState) {
    String format = 'pdf';
    bool sendEmail = true;
    bool isExporting = false;
    final userEmail = AuthService().currentUser?.email ?? 'your email';
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text('Export Transactions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select export format:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setDlgState(() => format = 'pdf'),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: format == 'pdf' ? AppColors.primaryLight : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: format == 'pdf' ? AppColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.picture_as_pdf, color: format == 'pdf' ? AppColors.primary : AppColors.textSecondary, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'PDF Report',
                                  style: TextStyle(
                                    fontWeight: format == 'pdf' ? FontWeight.w700 : FontWeight.w500,
                                    color: format == 'pdf' ? AppColors.primary : AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setDlgState(() => format = 'csv'),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: format == 'csv' ? AppColors.primaryLight : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                              border: Border.all(
                                color: format == 'csv' ? AppColors.primary : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.table_chart_outlined, color: format == 'csv' ? AppColors.primary : AppColors.textSecondary, size: 28),
                                const SizedBox(height: 4),
                                Text(
                                  'CSV Spreadsheet',
                                  style: TextStyle(
                                    fontWeight: format == 'csv' ? FontWeight.w700 : FontWeight.w500,
                                    color: format == 'csv' ? AppColors.primary : AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Send copy to my email via SMTP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text(
                        'Will send ${format.toUpperCase()} directly to $userEmail',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      value: sendEmail,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setDlgState(() => sendEmail = val),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isExporting ? null : () => Navigator.pop(dlgCtx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                  ),
                  onPressed: isExporting
                      ? null
                      : () async {
                          setDlgState(() => isExporting = true);
                          final res = await ApiService.exportTransactions(
                            format: format,
                            sendEmail: sendEmail,
                          );
                          setDlgState(() => isExporting = false);

                          if (res['success'] == true) {
                            Navigator.pop(dlgCtx);
                            final emailSent = res['emailSent'] == true;
                            final count = res['recordCount'] ?? 0;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  emailSent
                                      ? 'Export created ($count transactions) and sent to $userEmail via SMTP!'
                                      : 'Export file created ($count transactions)!',
                                ),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 4),
                              ),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(res['error'] as String? ?? 'Export failed'),
                                backgroundColor: AppColors.expense,
                              ),
                            );
                          }
                        },
                  child: isExporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Export Now'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCurrencyDialog(BuildContext context, ExpenseState expenseState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final all = AppCurrencies.all;
            final q = searchQuery.toLowerCase().trim();
            final filtered = q.isEmpty
                ? all
                : all.where((c) {
                    final cCode = (c['code'] ?? '').toLowerCase();
                    final cName = (c['name'] ?? '').toLowerCase();
                    final cSymbol = (c['symbol'] ?? '').toLowerCase();
                    return cCode.contains(q) || cName.contains(q) || cSymbol.contains(q);
                  }).toList();

            final String activeCode = () {
              try {
                return expenseState.currencyCode.toUpperCase();
              } catch (_) {
                return 'USD';
              }
            }();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Select Currency',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Text(
                    'Choose a currency for your accounts, transactions, and budgets.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search currency or code...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (cContext, idx) {
                        final curr = filtered[idx];
                        final code = curr['code'] ?? 'USD';
                        final symbol = curr['symbol'] ?? '\$';
                        final name = curr['name'] ?? '';
                        final isSelected = activeCode == code.toUpperCase();

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight.withAlpha(50) : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withAlpha(25) : const Color(0xFFF3F4F6),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                curr['flag'] ?? '🌐',
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  code,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    symbol,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: AppColors.primary),
                                    ),
                                    child: Text(
                                      'Active',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            subtitle: Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: AppColors.primary, size: 22)
                                : null,
                            onTap: () {
                              Navigator.pop(ctx);
                              if (isSelected) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Your account is already set to $code ($symbol).'),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                                return;
                              }
                              _showConversionPromptDialog(context, expenseState, {
                                'code': code,
                                'symbol': symbol,
                                'name': name,
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showConversionPromptDialog(
    BuildContext context,
    ExpenseState expenseState,
    Map<String, String> targetCurrency,
  ) {
    String fromCode = 'USD';
    String fromSymbol = '\$';
    try {
      fromCode = expenseState.currencyCode;
    } catch (_) {}
    try {
      fromSymbol = expenseState.currencySymbol;
    } catch (_) {}
    final toCode = targetCurrency['code'] ?? 'USD';
    final toSymbol = targetCurrency['symbol'] ?? '\$';

    if (fromCode.toUpperCase() == toCode.toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your account is already set to $toCode ($toSymbol).'),
          backgroundColor: AppColors.primary,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) {
        double? exchangeRate;
        bool isLoadingRate = true;
        String? errorMessage;

        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            if (isLoadingRate && exchangeRate == null && errorMessage == null) {
              CurrencyService.getExchangeRate(fromCode, toCode).then((rate) {
                if (dlgCtx.mounted) {
                  setDlgState(() {
                    isLoadingRate = false;
                    exchangeRate = rate;
                    if (rate == null) {
                      errorMessage = 'Could not fetch live rate. You can still switch currency.';
                    }
                  });
                }
              }).catchError((_) {
                if (dlgCtx.mounted) {
                  setDlgState(() {
                    isLoadingRate = false;
                    errorMessage = 'Network error fetching rate.';
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(Icons.currency_exchange_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Change Currency',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switching from $fromCode ($fromSymbol) to $toCode ($toSymbol)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Live Exchange Rate Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: isLoadingRate
                          ? const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 12),
                                Text('Fetching live exchange rate...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            )
                          : (exchangeRate != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.trending_up, color: AppColors.primary, size: 16),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Live Rate: 1 $fromCode = ${exchangeRate!.toStringAsFixed(4)} $toCode',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Example: If you had $fromSymbol 1.00 in your account:\n'
                                      '• Converted: $toSymbol ${(1.0 * exchangeRate!).toStringAsFixed(2)}\n'
                                      '• Stay Same Amount: $toSymbol 1.00',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                                    ),
                                  ],
                                )
                              : Text(
                                  errorMessage ?? 'Live rate unavailable',
                                  style: const TextStyle(fontSize: 12, color: AppColors.expense),
                                )),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    const Text(
                      'How would you like to handle your existing balances, transactions, and budgets?',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              actions: [
                // 1. Convert Amounts
                if (exchangeRate != null)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                      minimumSize: const Size.fromHeight(42),
                    ),
                    onPressed: () async {
                      Navigator.pop(dlgCtx);
                      final success = await expenseState.changeCurrencyWithConversion(
                        newCode: toCode,
                        newSymbol: toSymbol,
                        convertAmounts: true,
                        rate: exchangeRate!,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Converted all amounts to $toCode ($toSymbol) at 1 $fromCode = ${exchangeRate!.toStringAsFixed(2)} $toCode'
                                  : 'Currency updated to $toCode',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    },
                    child: Text('Convert Amounts to $toCode (Live Rate)'),
                  ),
                const SizedBox(height: 6),

                // 2. Stay Same Amount
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
                    minimumSize: const Size.fromHeight(42),
                  ),
                  onPressed: () async {
                    Navigator.pop(dlgCtx);
                    await expenseState.changeCurrencyWithConversion(
                      newCode: toCode,
                      newSymbol: toSymbol,
                      convertAmounts: false,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Switched currency to $toCode ($toSymbol) without converting figures.'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  },
                  child: Text('Stay Same Amount in $toCode'),
                ),
                const SizedBox(height: 4),

                // 3. Cancel
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: const Center(
                    child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = Provider.of<ExpenseState>(context);
    final isDark = expenseState.isDarkMode;
    final currentUser = AuthService().currentUser;
    final userName = currentUser?.name.isNotEmpty == true ? currentUser!.name : 'ExpenseMate User';
    final userEmail = currentUser?.email.isNotEmpty == true ? currentUser!.email : 'user@expensemate.com';

    // Initials for avatar fallback
    final initials = userName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();

    // Check current primary palette item name
    final currentColorItem = AppColors.primaryPalette.firstWhere(
      (p) => (p['color'] as Color).toARGB32() == expenseState.primaryColor.toARGB32(),
      orElse: () => {'name': 'Custom Color', 'color': expenseState.primaryColor},
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: const CustomAppBar(title: 'Profile & Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            // User Avatar Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: Row(
                children: [
                  // Avatar with Camera Icon Overlay
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarOptions,
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: _cachedPfpBytes != null
                              ? MemoryImage(_cachedPfpBytes!)
                              : null,
                          child: _isLoadingPfp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : (_cachedPfpBytes == null
                                  ? Text(
                                      initials.isNotEmpty ? initials : 'EM',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryDark,
                                      ),
                                    )
                                  : null),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showAvatarOptions,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                    tooltip: 'Edit Name & Email',
                    onPressed: () => _showEditProfileDialog(context, currentUser),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Preferences Group
            _buildSectionHeader('Preferences'),
            _buildSettingsTile(
              icon: Icons.palette_outlined,
              title: 'Primary App Color',
              subtitle: '${currentColorItem['name']} • Tap to customize',
              trailingWidget: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: expenseState.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              isDark: isDark,
              onTap: () => _showColorPickerSheet(context, expenseState),
            ),
            _buildSwitchTile(
              icon: Icons.fingerprint,
              title: 'Biometric Lock',
              value: _biometricEnabled,
              isDark: isDark,
              onChanged: (val) => setState(() => _biometricEnabled = val),
            ),
            _buildSwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Dark Theme',
              value: isDark,
              isDark: isDark,
              onChanged: (val) => expenseState.toggleTheme(val),
            ),
            _buildSettingsTile(
              icon: Icons.monetization_on_outlined,
              title: 'Preferred Currency',
              subtitle: () {
                String c = 'USD';
                String s = '\$';
                try {
                  c = expenseState.currencyCode;
                } catch (_) {}
                try {
                  s = expenseState.currencySymbol;
                } catch (_) {}
                return '$c ($s) • Tap to change';
              }(),
              isDark: isDark,
              onTap: () => _showCurrencyDialog(context, expenseState),
            ),
            _buildSettingsTile(
              icon: Icons.category_outlined,
              title: 'Manage Categories',
              subtitle: '${expenseState.categories.length} categories • Add, edit, or delete',
              isDark: isDark,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoriesPage()),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Data & Security Group
            _buildSectionHeader('Data & Security'),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: 'Change Password',
              subtitle: 'Update your current account password',
              isDark: isDark,
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildSettingsTile(
              icon: Icons.file_download_outlined,
              title: 'Export Transactions (CSV / PDF)',
              subtitle: 'Send financial report to your email via SMTP',
              isDark: isDark,
              onTap: () => _showExportDialog(context, expenseState),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Log Out Button
            OutlinedButton.icon(
              onPressed: () {
                AuthService().logout();
                expenseState.clear();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout, color: AppColors.expense, size: 18),
              label: const Text('Log Out', style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.expense),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs, left: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailingWidget,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDark ? Colors.white : AppColors.textPrimary, size: 22),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
        trailing: trailingWidget ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: isDark ? Colors.white : AppColors.textPrimary, size: 22),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
