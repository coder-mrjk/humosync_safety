import 'package:flutter/material.dart';
import '../../components/premium_card.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/logs_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LogsTab extends StatefulWidget {
  const LogsTab({super.key});

  @override
  State<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<LogsTab> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final logsProvider = Provider.of<LogsProvider>(context);
    final filteredLogs = logsProvider.getLogsByType(_selectedFilter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 5),
          child: Text(
            'EVENT ARCHIVE',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),
        _buildFilterBar(),
        Expanded(
          child: filteredLogs.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    return _buildDetailedLogItem(filteredLogs[index])
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideX(begin: 0.05);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.folderOpen,
            color: const Color(0xFF334155),
            size: 48,
          ),
          const SizedBox(height: 15),
          Text(
            'NO RECORDS FOUND',
            style: GoogleFonts.jetBrainsMono(
              color: const Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            const SizedBox(width: 10),
            _buildFilterChip('Intrusions'),
            const SizedBox(width: 10),
            _buildFilterChip('RFID'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                )
              : null,
          color: isSelected
              ? null
              : const Color(0xFF1E293B).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white24 : const Color(0xFF334155),
            width: 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedLogItem(LogEntry log) {
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
      margin: const EdgeInsets.only(bottom: 15),
      child: PremiumCard(
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Center(child: FaIcon(icon, color: color, size: 22)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              log.title.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: log.type == 'intrusion'
                                    ? const Color(0xFFEF4444)
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
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
                        const SizedBox(height: 6),
                        Text(
                          log.description,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.calendarDay,
                                size: 10,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(log.timestamp),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (log.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image.network(
                        log.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 100,
                          color: Colors.black,
                          child: const Center(
                            child: FaIcon(
                              FontAwesomeIcons.triangleExclamation,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                          child: Text(
                            'SENSOR CAPTURE',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
  }
}
