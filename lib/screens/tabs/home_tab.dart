import 'package:flutter/material.dart';
import '../../components/premium_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/robot_provider.dart';
import '../../providers/logs_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../live_cam_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Key to force refresh of the Image widget
  Key _streamKey = UniqueKey();

  late TextEditingController _camIpController;
  late TextEditingController _motorIpController;

  @override
  void initState() {
    super.initState();
    // Listen for detection changes to trigger logs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final robot = Provider.of<RobotProvider>(context, listen: false);
      final logs = Provider.of<LogsProvider>(context, listen: false);

      robot.addListener(() {
        if (robot.detectedClass != 'OTHERS' &&
            robot.detectionConfidence > 0.7) {
          logs.addLocalLog(robot.detectedClass, robot.detectionConfidence);
        }
      });
    });

    final robot = Provider.of<RobotProvider>(context, listen: false);
    _camIpController = TextEditingController(text: robot.esp32Ip);
    _motorIpController = TextEditingController(text: robot.motorIp);
  }

  @override
  void dispose() {
    _camIpController.dispose();
    _motorIpController.dispose();
    super.dispose();
  }

  void _refreshStream() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final robotProvider = Provider.of<RobotProvider>(context);
    final logsProvider = Provider.of<LogsProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(robotProvider),
          const SizedBox(height: 20),
          _buildLiveFeed(robotProvider).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 15),
          _buildAiDiagnostics(
            robotProvider,
          ).animate().slideY(begin: 0.1, delay: 100.ms).fadeIn(),
          const SizedBox(height: 15),
          _buildSystemStatus(
            robotProvider,
          ).animate().slideY(begin: 0.1, delay: 150.ms).fadeIn(),
          const SizedBox(height: 15),
          _buildRecentActivity(
            logsProvider,
          ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildHeader(RobotProvider robot) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COMMAND CENTER',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'DUAL-LINK SYSTEM',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: const Color(0xFF06B6D4),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Dynamic IP Entries
        Row(
          children: [
            _buildIpField(
              controller: _camIpController,
              label: 'CAM IP',
              color: const Color(0xFF3B82F6),
              onSubmitted: (val) {
                if (val.isNotEmpty) robot.updateIp(val.trim());
              },
            ),
            const SizedBox(width: 10),
            _buildIpField(
              controller: _motorIpController,
              label: 'CAR IP',
              color: const Color(0xFF10B981),
              onSubmitted: (val) {
                if (val.isNotEmpty) robot.updateMotorIp(val.trim());
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIpField({
    required TextEditingController controller,
    required String label,
    required Color color,
    required Function(String) onSubmitted,
  }) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: controller,
            style: GoogleFonts.jetBrainsMono(color: Colors.white, fontSize: 10),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'IP...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.only(bottom: 14),
            ),
            onSubmitted: (val) => onSubmitted(val),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveFeed(RobotProvider robot) {
    final hasStream = robot.esp32StreamUrl.isNotEmpty && robot.isOnline;
    final streamUrl = robot.esp32StreamUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LiveCamScreen()),
        );
      },
      child: PremiumCard(
        padding: EdgeInsets.zero,
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
          children: [
            // Live Stream or Placeholder
            if (hasStream)
              Image.network(
                streamUrl,
                key: _streamKey,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                gaplessPlayback: true, // Prevents flicker during refresh
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF3B82F6),
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Connecting to stream...',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.videoSlash,
                        color: Color(0xFF475569),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Stream Unavailable',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _refreshStream,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'TAP TO RETRY',
                            style: GoogleFonts.jetBrainsMono(
                              color: const Color(0xFF3B82F6),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF334155),
                          width: 2,
                        ),
                      ),
                      child: FaIcon(
                        robot.isOnline
                            ? FontAwesomeIcons.camera
                            : FontAwesomeIcons.wifi,
                        color: const Color(0xFF475569),
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      robot.isOnline
                          ? 'Waiting for stream...'
                          : 'ESP32-CAM Offline',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!robot.isOnline) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Check device connection',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF475569),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // Scanline effect overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Top Left - Live Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      (hasStream
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF64748B))
                          .withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: hasStream
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFFEF4444,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasStream)
                      Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(duration: 800.ms, end: const Offset(1.5, 1.5))
                          .fadeOut(duration: 800.ms),
                    if (hasStream) const SizedBox(width: 8),
                    Text(
                      hasStream ? 'LIVE' : 'OFFLINE',
                      style: GoogleFonts.jetBrainsMono(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top Right - Refresh Button
            if (hasStream)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _refreshStream,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.rotate,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                ),
              ),

            // Bottom - Detection Overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Detection Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: robot.detectionColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: robot.detectionColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            _getDetectionIcon(robot.detectedClass),
                            color: robot.detectionColor,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            robot.detectedClass.toUpperCase(),
                            style: GoogleFonts.jetBrainsMono(
                              color: robot.detectionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Confidence
                    Text(
                      robot.confidencePercent,
                      style: GoogleFonts.jetBrainsMono(
                        color: robot.confidenceColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  IconData _getDetectionIcon(String detectedClass) {
    switch (detectedClass.toUpperCase()) {
      case 'HUMAN':
      case 'HUMANS':
        return FontAwesomeIcons.person;
      case 'ANIMALS':
        return FontAwesomeIcons.paw;
      default:
        return FontAwesomeIcons.eye;
    }
  }

  Widget _buildAiDiagnostics(RobotProvider robot) {
    // Determine RFID status display
    String rfidStatus = 'Inactive';
    Color rfidColor = const Color(0xFF64748B);

    if (robot.detectedClass.toUpperCase() == 'HUMAN' ||
        robot.detectedClass.toUpperCase() == 'HUMANS') {
      if (robot.rfidRequested) {
        rfidStatus = 'Waiting...';
        rfidColor = const Color(0xFFF59E0B);
      }
    }

    if (robot.rfidAuthorized) {
      rfidStatus = 'Authorized';
      rfidColor = const Color(0xFF10B981);
    } else if (robot.rfidRequested && robot.rfidCardId.isNotEmpty) {
      rfidStatus = 'Denied';
      rfidColor = const Color(0xFFEF4444);
    }

    // Determine final classification color
    Color finalColor = const Color(0xFF94A3B8);
    if (robot.finalClassification == 'Authorized') {
      finalColor = const Color(0xFF10B981);
    } else if (robot.finalClassification == 'Intruder') {
      finalColor = const Color(0xFFEF4444);
    } else if (robot.finalClassification == 'Human Detected') {
      finalColor = const Color(0xFF3B82F6);
    } else if (robot.finalClassification == 'Animal Detected') {
      finalColor = const Color(0xFFF59E0B);
    }

    return PremiumCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.brain,
                      color: Color(0xFF06B6D4),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Diagnostics',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: robot.aiReady
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: robot.aiReady
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : const Color(0xFFEF4444).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  robot.aiReady ? 'TFLITE ✓' : 'AI OFFLINE',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: robot.aiReady
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  label: 'DETECTED',
                  value: robot.detectedClass.toUpperCase(),
                  valueColor: robot.detectionColor,
                  icon: _getDetectionIcon(robot.detectedClass),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'CONFIDENCE',
                  value: robot.confidencePercent,
                  valueColor: robot.confidenceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatBox(
                  label: 'RFID STATUS',
                  value: rfidStatus.toUpperCase(),
                  valueColor: rfidColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'CLASSIFICATION',
                  value: robot.finalClassification.toUpperCase(),
                  valueColor: finalColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus(RobotProvider robot) {
    return PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.microchip,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'System Status',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMiniStatus(
                  icon: FontAwesomeIcons.wifi,
                  label: 'CONNECTION',
                  value: robot.isOnline ? 'ONLINE' : 'OFFLINE',
                  color: robot.isOnline
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
              Expanded(
                child: _buildMiniStatus(
                  icon: FontAwesomeIcons.sdCard,
                  label: 'SD CARD',
                  value: robot.sdReady ? 'READY' : 'NO SD',
                  color: robot.sdReady
                      ? const Color(0xFF10B981)
                      : const Color(0xFF64748B),
                ),
              ),
              Expanded(
                child: _buildMiniStatus(
                  icon: FontAwesomeIcons.camera,
                  label: 'RECORDINGS',
                  value: robot.recordingCount.toString(),
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _buildMiniStatus(
                  icon: FontAwesomeIcons.clock,
                  label: 'UPTIME',
                  value: robot.formattedUptime,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatus({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 18),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 8,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    Color? valueColor,
    IconData? icon,
    double fontSize = 18,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                FaIcon(icon, color: valueColor, size: 16),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? const Color(0xFF06B6D4),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF64748B),
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(LogsProvider logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SECURITY LOGS',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'LATEST 5',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        ...logs.recentLogs.map((log) => _buildLogItem(log)),
        if (logs.recentLogs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40.0),
            child: Center(
              child: Opacity(
                opacity: 0.5,
                child: Column(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.database,
                      color: Color(0xFF64748B),
                      size: 24,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Monitoring secure channels...',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLogItem(LogEntry log) {
    Color color;
    IconData icon;

    switch (log.type) {
      case 'intrusion':
        color = const Color(0xFFEF4444);
        icon = FontAwesomeIcons.userSecret;
        break;
      case 'rfid-success':
        color = const Color(0xFF10B981);
        icon = FontAwesomeIcons.idCard;
        break;
      case 'rfid-fail':
        color = const Color(0xFFEF4444);
        icon = FontAwesomeIcons.ban;
        break;
      case 'human':
        color = const Color(0xFF3B82F6);
        icon = FontAwesomeIcons.person;
        break;
      case 'animal':
        color = const Color(0xFFF59E0B);
        icon = FontAwesomeIcons.paw;
        break;
      default:
        color = const Color(0xFF3B82F6);
        icon = FontAwesomeIcons.shieldHalved;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Center(child: FaIcon(icon, color: color, size: 20)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.title,
                    style: GoogleFonts.inter(
                      color: log.type == 'intrusion'
                          ? const Color(0xFFEF4444)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.description,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('HH:mm').format(log.timestamp),
              style: GoogleFonts.jetBrainsMono(
                color: const Color(0xFF475569),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
