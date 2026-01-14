import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tabs/home_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/control_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/profile_tab.dart';
import 'package:provider/provider.dart';
import '../providers/robot_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const MapTab(),
    const ControlTab(),
    const LogsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final robotProvider = Provider.of<RobotProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.6),
            radius: 1.2,
            colors: [Color(0xFF1E293B), Color(0xFF020617)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(robotProvider),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _tabs),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAppBar(RobotProvider robot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'HUMO',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                TextSpan(
                  text: 'SAFE',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w300,
                    fontSize: 20,
                    color: const Color(0xFF06B6D4),
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: robot.isOnline
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    (robot.isOnline
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.3),
              ),
              boxShadow: [
                if (robot.isOnline)
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: robot.isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (robot.isOnline)
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  robot.isOnline ? 'LINK ACTIVE' : 'NO LINK',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: robot.isOnline
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF020617),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: const Color(0xFF475569),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        items: [
          _buildNavItem(FontAwesomeIcons.house, 'DASHBOARD'),
          _buildNavItem(FontAwesomeIcons.mapLocationDot, 'MAP'),
          _buildNavItem(FontAwesomeIcons.gamepad, 'CONTROL'),
          _buildNavItem(FontAwesomeIcons.listCheck, 'LOGS'),
          _buildNavItem(FontAwesomeIcons.userGear, 'PROFILE'),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label) {
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: FaIcon(icon, size: 18),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 2),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: FaIcon(icon, size: 18, color: const Color(0xFF3B82F6)),
        ),
      ),
      label: label,
    );
  }
}
