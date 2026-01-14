import 'package:flutter/material.dart';
import '../../components/premium_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/robot_provider.dart';
import '../../providers/logs_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final robotProvider = Provider.of<RobotProvider>(context);
    final logsProvider = Provider.of<LogsProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildLiveFeed().animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 15),
          _buildAiDiagnostics(
            robotProvider,
          ).animate().slideY(begin: 0.1, delay: 100.ms).fadeIn(),
          const SizedBox(height: 15),
          _buildRecentActivity(
            logsProvider,
          ).animate().slideY(begin: 0.1, delay: 200.ms).fadeIn(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
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
          'SYSTEM STATUS:',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: const Color(0xFF06B6D4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveFeed() {
    return Consumer<RobotProvider>(
      builder: (context, robot, child) {
        final hasStream = robot.esp32StreamUrl.isNotEmpty;

        return PremiumCard(
          padding: EdgeInsets.zero,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (hasStream)
                  Image.network(
                    robot.esp32StreamUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF3B82F6),
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
                        ],
                      ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.camera,
                          color: Color(0xFF475569),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Waiting for ESP32-CAM...',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Scanline effect
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
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (hasStream
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF64748B))
                              .withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
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
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .scale(
                                duration: 800.ms,
                                end: const Offset(1.5, 1.5),
                              )
                              .fadeOut(duration: 800.ms),
                        if (hasStream) const SizedBox(width: 8),
                        Text(
                          hasStream ? 'LIVE FEED' : 'OFFLINE',
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiDiagnostics(RobotProvider robot) {
    // Determine RFID status display
    String rfidStatus = 'Inactive';
    Color rfidColor = const Color(0xFF64748B);

    if (robot.detectedClass == 'Human') {
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
    }

    return PremiumCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.brain,
                    color: Color(0xFF06B6D4),
                    size: 16,
                  ),
                  const SizedBox(width: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'TFLITE AI',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: const Color(0xFF06B6D4),
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
                  valueColor: robot.detectedClass == 'Human'
                      ? const Color(0xFF3B82F6)
                      : robot.detectedClass == 'Animal'
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatBox(
                  label: 'CONFIDENCE',
                  value:
                      '${(robot.detectionConfidence * 100).toStringAsFixed(0)}%',
                  valueColor: robot.detectionConfidence > 0.7
                      ? const Color(0xFF10B981)
                      : robot.detectionConfidence > 0.4
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF94A3B8),
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    Color? valueColor,
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
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF06B6D4),
            ),
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
