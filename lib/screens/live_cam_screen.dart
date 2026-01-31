import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/robot_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Fullscreen Live Camera View with AI Classification Overlay
class LiveCamScreen extends StatefulWidget {
  const LiveCamScreen({super.key});

  @override
  State<LiveCamScreen> createState() => _LiveCamScreenState();
}

class _LiveCamScreenState extends State<LiveCamScreen> {
  final TextEditingController _ipController = TextEditingController();
  Key _streamKey = UniqueKey();
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    // Force landscape for better video viewing
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    
    final robot = Provider.of<RobotProvider>(context, listen: false);
    _ipController.text = robot.esp32Ip;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _ipController.dispose();
    super.dispose();
  }

  void _refreshStream() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final robot = Provider.of<RobotProvider>(context);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Live Stream
          Positioned.fill(
            child: _buildLiveStream(robot),
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(robot, context),
          ),

          // Bottom AI Results Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(robot, isLandscape),
          ),

          // Settings Panel (slide-in)
          if (_showSettings)
            Positioned(
              top: 80,
              right: 16,
              child: _buildSettingsPanel(robot),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStream(RobotProvider robot) {
    if (!robot.isOnline || robot.esp32StreamUrl.isEmpty) {
      return _buildOfflineState(robot);
    }

    return Image.network(
      robot.esp32StreamUrl,
      key: _streamKey,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                    : null,
                color: const Color(0xFF3B82F6),
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Connecting to stream...',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildStreamError();
      },
    );
  }

  Widget _buildOfflineState(RobotProvider robot) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 2,
                ),
              ),
              child: const FaIcon(
                FontAwesomeIcons.wifi,
                color: Color(0xFF475569),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ESP32-CAM Offline',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check connection and IP address',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _showSettings = true);
              },
              icon: const FaIcon(FontAwesomeIcons.gear, size: 14),
              label: const Text('Configure IP'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamError() {
    return Container(
      color: const Color(0xFF0F172A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.videoSlash,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Stream Unavailable',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load video stream',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _refreshStream,
              icon: const FaIcon(FontAwesomeIcons.rotate, size: 14),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(RobotProvider robot, BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const FaIcon(
                FontAwesomeIcons.chevronLeft,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LIVE CAMERA',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: robot.isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ).animate(onPlay: (c) => c.repeat())
                     .scale(duration: 800.ms, end: const Offset(1.2, 1.2))
                     .then()
                     .scale(duration: 800.ms, end: const Offset(1/1.2, 1/1.2)),
                    const SizedBox(width: 6),
                    Text(
                      robot.isOnline ? 'STREAMING' : 'OFFLINE',
                      style: GoogleFonts.jetBrainsMono(
                        color: robot.isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (robot.aiReady) ...[
                      const FaIcon(
                        FontAwesomeIcons.brain,
                        color: Color(0xFF06B6D4),
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI',
                        style: GoogleFonts.jetBrainsMono(
                          color: const Color(0xFF06B6D4),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              // Flash Toggle
              GestureDetector(
                onTap: () => robot.toggleFlash(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: robot.flashOn
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: robot.flashOn
                        ? Border.all(color: const Color(0xFFF59E0B), width: 1)
                        : null,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.bolt,
                    color: robot.flashOn ? const Color(0xFFF59E0B) : Colors.white70,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Refresh
              GestureDetector(
                onTap: _refreshStream,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.rotate,
                    color: Colors.white70,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Settings
              GestureDetector(
                onTap: () {
                  setState(() => _showSettings = !_showSettings);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _showSettings
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: _showSettings
                        ? Border.all(color: const Color(0xFF3B82F6), width: 1)
                        : null,
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.gear,
                    color: _showSettings ? const Color(0xFF3B82F6) : Colors.white70,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(RobotProvider robot, bool isLandscape) {
    final highestScore = [robot.humanScore, robot.animalScore, robot.otherScore]
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: isLandscape
          ? _buildLandscapeLayout(robot, highestScore)
          : _buildPortraitLayout(robot, highestScore),
    );
  }

  Widget _buildPortraitLayout(RobotProvider robot, double highestScore) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Detection Result
        _buildMainDetectionBadge(robot, highestScore),
        const SizedBox(height: 16),
        // Confidence Bars
        _buildConfidenceBars(robot),
        const SizedBox(height: 12),
        // Stats Row
        _buildStatsRow(robot),
      ],
    );
  }

  Widget _buildLandscapeLayout(RobotProvider robot, double highestScore) {
    return Row(
      children: [
        // Main Detection Result
        Expanded(
          flex: 2,
          child: _buildMainDetectionBadge(robot, highestScore),
        ),
        const SizedBox(width: 20),
        // Confidence Bars
        Expanded(
          flex: 3,
          child: _buildConfidenceBars(robot),
        ),
        const SizedBox(width: 20),
        // Stats
        Expanded(
          flex: 2,
          child: _buildStatsRow(robot),
        ),
      ],
    );
  }

  Widget _buildMainDetectionBadge(RobotProvider robot, double highestScore) {
    String label;
    IconData icon;
    Color color;

    switch (robot.detectedClass.toUpperCase()) {
      case 'HUMANS':
      case 'HUMAN':
        label = 'HUMAN DETECTED';
        icon = FontAwesomeIcons.person;
        color = const Color(0xFF3B82F6);
        break;
      case 'ANIMALS':
      case 'ANIMAL':
        label = 'ANIMAL DETECTED';
        icon = FontAwesomeIcons.paw;
        color = const Color(0xFFF59E0B);
        break;
      default:
        label = 'SCANNING...';
        icon = FontAwesomeIcons.eye;
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${highestScore.toStringAsFixed(1)}% Confidence',
                style: GoogleFonts.jetBrainsMono(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildConfidenceBars(RobotProvider robot) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBar('Human', robot.humanScore, const Color(0xFF3B82F6)),
        const SizedBox(height: 8),
        _buildBar('Animal', robot.animalScore, const Color(0xFFF59E0B)),
        const SizedBox(height: 8),
        _buildBar('Other', robot.otherScore, const Color(0xFF64748B)),
      ],
    );
  }

  Widget _buildBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: (value / 100).clamp(0, 1),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 40,
          child: Text(
            '${value.toStringAsFixed(0)}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(RobotProvider robot) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('INFERENCE', robot.formattedInferenceTime, const Color(0xFF06B6D4)),
        _buildStatItem('UPTIME', robot.formattedUptime, const Color(0xFF8B5CF6)),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsPanel(RobotProvider robot) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SETTINGS',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showSettings = false),
                child: const FaIcon(
                  FontAwesomeIcons.xmark,
                  color: Color(0xFF64748B),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // IP Input
          Text(
            'ESP32-CAM IP Address',
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: TextField(
              controller: _ipController,
              style: GoogleFonts.jetBrainsMono(
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: '192.168.4.1',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: IconButton(
                  icon: const FaIcon(
                    FontAwesomeIcons.check,
                    size: 14,
                    color: Color(0xFF10B981),
                  ),
                  onPressed: () {
                    robot.updateIp(_ipController.text);
                    _refreshStream();
                    setState(() => _showSettings = false);
                  },
                ),
              ),
              onSubmitted: (val) {
                robot.updateIp(val);
                _refreshStream();
                setState(() => _showSettings = false);
              },
            ),
          ),
          const SizedBox(height: 16),

          // Current Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: robot.isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    robot.isOnline ? 'Connected to ${robot.esp32Ip}' : 'Not Connected',
                    style: GoogleFonts.inter(
                      color: robot.isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
