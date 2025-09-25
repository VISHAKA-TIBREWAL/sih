// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'track_map_screen.dart';
import 'ai_recommendations_screen.dart';
import 'override_controls_screen.dart';
import 'what_if_analysis_screen.dart';
import 'performance_screen.dart';
import '../utils/page_transitions_fixed.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;
  
  @override
  void initState() {
    super.initState();
    
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    _sidebarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sidebarController,
      curve: Curves.easeOutQuart,
      reverseCurve: Curves.easeInQuart,
    ));
    
    _sidebarController.value = 1.0;
  }
  
  @override
  void dispose() {
    _sidebarController.dispose();
    super.dispose();
  }
  
  void _logout() {
    Navigator.of(context).pushReplacement(
      PageRoutes.fadeThrough(const LoginScreen()),
    );
  }
  
  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  void _showTrainDetailsPopup(BuildContext context, String trainId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<ApiResponse<TrainDetails>>(
          future: ApiService().getTrainDetails(trainId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Train $trainId Details'),
                content: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.isSuccess) {
              return AlertDialog(
                title: Text('Train $trainId Details'),
                content: const Text('Failed to load train details'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final train = snapshot.data!.data!;
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.train, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${train.name} (${train.id})'),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailSection('Route Information', [
                        _buildDetailRow('Route', train.route),
                        _buildDetailRow('Current Station', train.currentStation),
                        _buildDetailRow('Next Station', train.nextStation),
                        _buildDetailRow('Status', train.status, statusColor: train.status == 'On Time' ? Colors.green : Colors.red),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Operational Details', [
                        _buildDetailRow('Speed', '${train.speed} km/h'),
                        _buildDetailRow('Delay', train.delay > 0 ? '${train.delay} minutes' : 'On time'),
                        _buildDetailRow('Departure', train.departureTime),
                        _buildDetailRow('Expected Arrival', train.arrivalTime),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Train Composition', [
                        _buildDetailRow('Coaches', '${train.coaches}'),
                        _buildDetailRow('Engine Type', train.engineType),
                        _buildDetailRow('Passengers', '${train.passengers} / ${train.capacity}'),
                        _buildDetailRow('Occupancy', '${((train.passengers / train.capacity) * 100).toStringAsFixed(1)}%'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Crew Information', [
                        _buildDetailRow('Driver', train.driver),
                        _buildDetailRow('Guard', train.guard),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Track & Weather', [
                        _buildDetailRow('Signal Status', train.signal, statusColor: train.signal == 'Green' ? Colors.green : Colors.amber),
                        _buildDetailRow('Track Condition', train.trackCondition),
                        _buildDetailRow('Weather', train.weather),
                        _buildDetailRow('Distance Progress', '${train.distanceCovered} / ${train.totalDistance} km'),
                      ]),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTrainTrackPopup(BuildContext context, String trainId) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<ApiResponse<TrackInfo>>(
          future: ApiService().getTrainTrackInfo(trainId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Track Train $trainId'),
                content: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.isSuccess) {
              return AlertDialog(
                title: Text('Track Train $trainId'),
                content: const Text('Failed to load track information'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            }

            final track = snapshot.data!.data!;
            final currentLoc = track.currentLocation;
            final routeInfo = track.routeInfo;
            final opStatus = track.operationalStatus;

            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Tracking ${track.trainName}'),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailSection('Current Location', [
                        _buildDetailRow('Station', currentLoc['station'] ?? 'Unknown'),
                        _buildDetailRow('Signal', currentLoc['signal'] ?? 'Unknown', 
                          statusColor: currentLoc['signal'] == 'Green' ? Colors.green : 
                                     currentLoc['signal'] == 'Yellow' ? Colors.amber : Colors.red),
                        _buildDetailRow('Track Condition', currentLoc['trackCondition'] ?? 'Unknown'),
                        if (currentLoc['coordinates'] != null) 
                          _buildDetailRow('Coordinates', 
                            '${currentLoc['coordinates']['lat']?.toStringAsFixed(4)}, ${currentLoc['coordinates']['lng']?.toStringAsFixed(4)}'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Route Progress', [
                        _buildDetailRow('Route', routeInfo['route'] ?? 'Unknown'),
                        _buildDetailRow('Distance Covered', '${routeInfo['distanceCovered'] ?? 0} km'),
                        _buildDetailRow('Total Distance', '${routeInfo['totalDistance'] ?? 0} km'),
                        _buildDetailRow('Progress', '${routeInfo['progressPercentage']?.toStringAsFixed(1) ?? 0}%'),
                      ]),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        child: LinearProgressIndicator(
                          value: (routeInfo['progressPercentage'] ?? 0) / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailSection('Operational Status', [
                        _buildDetailRow('Current Speed', '${opStatus['speed'] ?? 0} km/h'),
                        _buildDetailRow('Status', opStatus['status'] ?? 'Unknown'),
                        _buildDetailRow('Delay', opStatus['delay'] != null ? '${opStatus['delay']} minutes' : 'Unknown'),
                        _buildDetailRow('Weather', opStatus['weather'] ?? 'Unknown'),
                      ]),
                      const SizedBox(height: 16),
                      _buildDetailSection('Next Station', [
                        _buildDetailRow('Station', track.nextStation),
                        _buildDetailRow('ETA', track.estimatedArrival),
                      ]),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: statusColor ?? Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            ClipRect(
              child: AnimatedBuilder(
                animation: _sidebarAnimation,
                builder: (context, child) {
                  return _buildSidebar();
                },
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _buildTopAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildCriticalAlerts(),
                          const SizedBox(height: 24),
                          _buildRealTimeTrainStatus(),
                          const SizedBox(height: 24),
                          _buildSummarySection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopAppBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isSidebarExpanded ? Icons.menu_open : Icons.menu,
              color: const Color(0xFF0D47A1),
            ),
            onPressed: _toggleSidebar,
            tooltip: _isSidebarExpanded ? 'Collapse sidebar' : 'Expand sidebar',
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final double sidebarWidth = _sidebarAnimation.value * 250;
    
    if (sidebarWidth < 1) {
      return const SizedBox(width: 0);
    }

    return Container(
      width: sidebarWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Icon(Icons.train, color: Color(0xFF0D47A1), size: 32),
                if (_sidebarAnimation.value > 0.3) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Railway Control',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(Icons.dashboard, 'Dashboard', true, null),
                _buildSidebarItem(Icons.map, 'Track Map', false, () {
                  Navigator.of(context).push(
                    PageRoutes.fadeThrough(const TrackMapScreen()),
                  );
                }),
                _buildSidebarItem(Icons.psychology, 'AI Recommendations', false, () {
                  Navigator.of(context).push(
                    PageRoutes.fadeThrough(const AiRecommendationsScreen()),
                  );
                }),
                _buildSidebarItem(Icons.settings, 'Override Controls', false, () {
                  Navigator.of(context).push(
                    PageRoutes.fadeThrough(const OverrideControlsScreen()),
                  );
                }),
                _buildSidebarItem(Icons.analytics, 'What-If Analysis', false, () {
                  Navigator.of(context).push(
                    PageRoutes.fadeThrough(const WhatIfAnalysisScreen()),
                  );
                }),
                _buildSidebarItem(Icons.speed, 'Performance', false, () {
                  Navigator.of(context).push(
                    PageRoutes.fadeThrough(const PerformanceScreen()),
                  );
                }),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: _buildSidebarItem(Icons.logout, 'Logout', false, _logout),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, bool isSelected, VoidCallback? onTap) {
    if (_sidebarAnimation.value < 0.3) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            size: 22,
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[600],
          ),
          onPressed: onTap,
          tooltip: title,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Railway Operations Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              'Last updated: ${_formatTime(DateTime.now())}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Real-time monitoring and control center',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCriticalAlerts() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.red[700], size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signal failure detected at Junction A - Train 12002 delayed by 15 minutes',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2 minutes ago',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Alert acknowledged'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
              child: const Text('Acknowledge'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeTrainStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Real-time Train Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 6),
                Text('Live - Last updated: ${_formatTime(DateTime.now())}', 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16.0,
          runSpacing: 16.0,
          children: [
            _buildTrainCard(
              trainNumber: '12002',
              trainName: 'Shatabdi Express',
              currentLocation: 'New Delhi',
              nextLocation: 'Kanpur Central',
              eta: '14:30',
              passengers: '1,200',
              status: 'On Time',
              statusColor: Colors.green,
            ),
            _buildTrainCard(
              trainNumber: '12951',
              trainName: 'Mumbai Rajdhani',
              currentLocation: 'Vadodara',
              nextLocation: 'Surat',
              eta: '16:45 (+22 min)',
              passengers: '1,800',
              status: 'Delayed',
              statusColor: Colors.red,
            ),
            _buildTrainCard(
              trainNumber: '22691',
              trainName: 'Rajdhani Express',
              currentLocation: 'Gwalior',
              nextLocation: 'Jhansi',
              eta: '18:20',
              passengers: '1,500',
              status: 'On Time',
              statusColor: Colors.green,
            ),
            _buildTrainCard(
              trainNumber: '12425',
              trainName: 'Jammu Express',
              currentLocation: 'Ambala',
              nextLocation: 'Jammu Tawi',
              eta: '21:15 (+39 min)',
              passengers: '1,100',
              status: 'Delayed',
              statusColor: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrainCard({
    required String trainNumber,
    required String trainName,
    required String currentLocation,
    required String nextLocation,
    required String eta,
    required String passengers,
    required String status,
    required Color statusColor,
  }) {
    return HoverCard(
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trainNumber,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(trainName, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 12),
            _buildInfoRow(icon: Icons.location_on, label: 'Current:', value: currentLocation),
            _buildInfoRow(icon: Icons.location_on, label: 'Next:', value: nextLocation),
            _buildInfoRow(icon: Icons.access_time, label: 'ETA:', value: eta),
            _buildInfoRow(icon: Icons.person, label: 'Passengers:', value: passengers),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () {
                    _showTrainDetailsPopup(context, trainNumber);
                  }, 
                  child: const Text('Details')
                ),
                ElevatedButton(
                  onPressed: () {
                    _showTrainTrackPopup(context, trainNumber);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Track'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: label,
              style: const TextStyle(color: Colors.grey),
              children: [
                TextSpan(
                  text: ' $value',
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummarySection() {
    return Wrap(
      spacing: 24.0,
      runSpacing: 24.0,
      children: [
        _buildSummaryCard(
          icon: Icons.access_time,
          iconColor: Colors.green,
          title: 'On Time',
          value: '2',
        ),
        _buildSummaryCard(
          icon: Icons.warning_rounded,
          iconColor: Colors.red,
          title: 'Delayed',
          value: '2',
        ),
        _buildSummaryCard(
          icon: Icons.person,
          iconColor: Colors.blue,
          title: 'Total Passengers',
          value: '5,600',
        ),
        _buildSummaryCard(
          icon: Icons.speed,
          iconColor: Colors.orange,
          title: 'Avg Speed',
          value: '95 km/h',
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return HoverCard(
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HoverCard extends StatefulWidget {
  final Widget child;

  const HoverCard({super.key, required this.child});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isHovering ? 0.15 : 0.05),
              blurRadius: _isHovering ? 12 : 4,
              offset: Offset(0, _isHovering ? 6 : 2),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}