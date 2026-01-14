import 'package:flutter/material.dart';
import '../../components/premium_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'edit_profile_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  AuthorizationStatus _notificationStatus = AuthorizationStatus.notDetermined;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  Future<void> _checkPermissionStatus() async {
    NotificationSettings settings = await FirebaseMessaging.instance
        .getNotificationSettings();
    if (mounted) {
      setState(() {
        _notificationStatus = settings.authorizationStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          _buildProfileHeader(
            context,
            authProvider,
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 30),
          _buildSettingsSection(
            context,
            authProvider,
          ).animate().slideY(begin: 0.1, delay: 100.ms).fadeIn(),
          const SizedBox(height: 30),
          _buildLogoutBtn(authProvider).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, AuthProvider auth) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 25,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: ClipOval(
                child: auth.avatarUrl != null && auth.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: auth.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: FaIcon(
                            FontAwesomeIcons.userShield,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      )
                    : const Center(
                        child: FaIcon(
                          FontAwesomeIcons.userShield,
                          color: Colors.white,
                          size: 44,
                        ),
                      ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () => _showEditProfile(context, auth),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.pen,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          auth.userName?.toUpperCase() ?? 'GUEST GUARDIAN',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
        if (auth.bio != null && auth.bio!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              auth.bio!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          auth.user?.email ?? 'disconnected@humosafe.loc',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'ROLE: ${auth.userRole?.toUpperCase() ?? "UNKNOWN"}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: const Color(0xFF06B6D4),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, AuthProvider auth) {
    String notifStatusText = 'UNKNOWN';
    Color notifStatusColor = const Color(0xFF64748B);

    if (_notificationStatus == AuthorizationStatus.authorized) {
      notifStatusText = 'ALLOWED';
      notifStatusColor = const Color(0xFF10B981);
    } else if (_notificationStatus == AuthorizationStatus.denied) {
      notifStatusText = 'NOT ALLOWED';
      notifStatusColor = const Color(0xFFEF4444);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5, bottom: 12),
          child: Text(
            'SYSTEM CONFIGURATION',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1,
            ),
          ),
        ),
        _buildSettingsItem(
          FontAwesomeIcons.idCardClip,
          'Customize Identity',
          'Edit name, bio and avatar',
          onTap: () => _showEditProfile(context, auth),
        ),
        _buildSettingsItem(
          FontAwesomeIcons.bell,
          'Intrusion Alerts',
          'Configurable response triggers',
          statusText: notifStatusText,
          statusColor: notifStatusColor,
          onTap: () => _requestNotificationPermission(context),
        ),
        _buildSettingsItem(
          FontAwesomeIcons.cloudArrowUp,
          'Cloud Synchronization',
          'Database connectivity is active',
          statusText: 'LINKED',
          statusColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle, {
    String? statusText,
    Color? statusColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: PremiumCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Center(
                  child: FaIcon(icon, color: const Color(0xFF3B82F6), size: 18),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (statusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (statusColor ?? const Color(0xFF64748B)).withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.jetBrainsMono(
                      color: statusColor ?? const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                const FaIcon(
                  FontAwesomeIcons.chevronRight,
                  color: Color(0xFF334155),
                  size: 14,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, AuthProvider auth) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileDialog(
        currentName: auth.userName ?? '',
        currentBio: auth.bio ?? '',
        currentAvatarUrl: auth.avatarUrl ?? '',
      ),
    );

    if (result != null) {
      await auth.updateProfile(
        name: result['name'],
        bio: result['bio'],
        avatarUrl: result['avatarUrl'],
      );
    }
  }

  Future<void> _requestNotificationPermission(BuildContext context) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    try {
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (mounted) {
        setState(() {
          _notificationStatus = settings.authorizationStatus;
        });
      }

      if (context.mounted) {
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Intrusion Alerts Activated',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification permission denied',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error requesting permissions: $e',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildLogoutBtn(AuthProvider auth) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
        ),
      ),
      child: ElevatedButton(
        onPressed: () => auth.logout(),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.05),
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.arrowRightFromBracket,
              size: 16,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(width: 12),
            Text(
              'TERMINATE SESSION',
              style: GoogleFonts.inter(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
