import 'package:flutter/material.dart';
import '../../components/premium_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:provider/provider.dart';
import '../../providers/robot_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ControlTab extends StatelessWidget {
  const ControlTab({super.key});

  @override
  Widget build(BuildContext context) {
    final robot = Provider.of<RobotProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildJoystickZone(
            robot,
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          _buildGestureGrid(
            robot,
          ).animate().slideY(begin: 0.1, delay: 100.ms).fadeIn(),
          const SizedBox(height: 15),
          _buildVoiceGrid(
            robot,
          ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
          const SizedBox(height: 15),
          _buildSystemToggles(
            robot,
          ).animate().slideY(begin: 0.1, delay: 300.ms).fadeIn(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UNIT CONTROL',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'MANUAL OVERRIDE: AUTHORIZED',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: const Color(0xFFF59E0B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildJoystickZone(RobotProvider robot) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      gradientColors: [
        const Color(0xFF1E293B).withValues(alpha: 0.4),
        const Color(0xFF0F172A).withValues(alpha: 0.6),
      ],
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF334155).withValues(alpha: 0.5),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 15,
              left: 20,
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.gamepad,
                    size: 12,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LOCOMOTION VECTOR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Joystick(
                mode: JoystickMode.all,
                listener: (details) {
                  robot.sendControl('move_x', details.x);
                  robot.sendControl('move_y', details.y);
                },
                base: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF334155),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E293B),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                stick: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                    border: Border.all(color: Colors.white24, width: 2),
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.arrowsUpDownLeftRight,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGestureGrid(RobotProvider robot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle('SOCIAL & INTERACTIVE'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildActionBtn(
              FontAwesomeIcons.hand,
              'HI',
              () => robot.triggerGesture('HI'),
            ),
            _buildActionBtn(
              FontAwesomeIcons.idBadge,
              'SCAN',
              () => robot.triggerGesture('SCAN'),
            ),
            _buildActionBtn(
              FontAwesomeIcons.ban,
              'STOP',
              () => robot.triggerGesture('STOP'),
              color: const Color(0xFFF59E0B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceGrid(RobotProvider robot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitle('AUDIO & ALERTS'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildActionBtn(
              FontAwesomeIcons.bullhorn,
              'WARNING',
              () => robot.triggerVoice('LEAVE_NOW'),
            ),
            _buildActionBtn(
              FontAwesomeIcons.userCheck,
              'AUTH',
              () => robot.triggerVoice('IDENTIFY'),
            ),
            _buildActionBtn(
              robot.isSirenOn
                  ? FontAwesomeIcons.bellSlash
                  : FontAwesomeIcons.bell,
              'SIREN',
              () => robot.toggleSiren(),
              color: const Color(0xFFEF4444),
              isActive: robot.isSirenOn,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemToggles(RobotProvider robot) {
    return PremiumCard(
      child: Column(
        children: [
          _buildToggleRow(
            icon: FontAwesomeIcons.lock,
            title: 'Motor Safety Lock',
            subtitle: 'Disable all locomotion servos',
            value: robot.isServoLocked,
            onChanged: (val) => robot.toggleServoLock(),
            color: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF64748B),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildActionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: PremiumCard(
          padding: EdgeInsets.zero,
          borderColor: isActive ? (color ?? const Color(0xFF3B82F6)) : null,
          gradientColors: isActive
              ? [
                  (color ?? const Color(0xFF3B82F6)).withValues(alpha: 0.2),
                  (color ?? const Color(0xFF3B82F6)).withValues(alpha: 0.05),
                ]
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                icon,
                color: isActive
                    ? (color ?? const Color(0xFF3B82F6))
                    : Colors.white70,
                size: 22,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: FaIcon(icon, color: color, size: 16)),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF3B82F6),
          activeTrackColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
          inactiveThumbColor: const Color(0xFF64748B),
          inactiveTrackColor: const Color(0xFF1E293B),
        ),
      ],
    );
  }
}
