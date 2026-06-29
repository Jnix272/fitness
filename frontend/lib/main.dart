import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'api_client.dart';

void main() {
  runApp(const WorkoutApp());
}

class WorkoutApp extends StatelessWidget {
  const WorkoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Coach',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    LoggerScreen(),
    ProgressScreen(),
    CoachScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Log'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Progress',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Coach',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiClient _apiClient = ApiClient();

  Future<void> _quickLog() async {
    try {
      await _apiClient.logSession({
        'session_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'template': 'FullBodyA',
        'notes': 'Quick logged from dashboard',
        'sets': [
          {
            'exercise_id': 1,
            'set_number': 1,
            'reps_completed': 10,
            'weight_kg': 20.0,
            'rir': 2,
            'rpe': 8,
          },
        ],
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Workout logged')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _openLogger() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const LoggerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const _DashboardHeader(),
            const SizedBox(height: 20),
            _WeeklySummaryCard(apiClient: _apiClient),
            const SizedBox(height: 14),
            _QuickActions(onStart: _openLogger, onQuickLog: _quickLog),
            const SizedBox(height: 14),
            _TodayPlanCard(onStart: _openLogger),
            const SizedBox(height: 14),
            _MiniMetrics(apiClient: _apiClient),
            const SizedBox(height: 14),
            _CoachCard(apiClient: _apiClient),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Let\'s get stronger today.',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () {},
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none, size: 30),
            ),
            Positioned(
              right: 5,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '3',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _DashCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF101923),
        border: Border.all(color: const Color(0xFF172433)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final ApiClient apiClient;

  const _WeeklySummaryCard({required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: apiClient.getWeeklyAnalytics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        final hardSets = data.fold<int>(
          0,
          (sum, item) => sum + ((item['hard_sets'] as num?)?.toInt() ?? 0),
        );
        final volume = data.fold<num>(
          0,
          (sum, item) => sum + ((item['volume_load'] as num?) ?? 0),
        );
        final avgRpe = data.isEmpty
            ? 7.4
            : data.fold<num>(
                    0,
                    (sum, item) => sum + ((item['avg_rpe'] as num?) ?? 0),
                  ) /
                  data.length;
        final progress = hardSets == 0 ? 0.75 : (hardSets / 56).clamp(0.0, 1.0);
        return _DashCard(
          child: Row(
            children: [
              const Expanded(
                child: _SummaryStat(
                  label: 'This Week',
                  value: '3 / 4',
                  note: 'workouts',
                ),
              ),
              SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 9,
                      backgroundColor: const Color(0xFF1C2A3A),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: const TextStyle(
                        color: Color(0xFF8DD7FF),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryStat(
                  label: 'Volume',
                  value: NumberFormat.compact().format(
                    volume == 0 ? 18240 : volume,
                  ),
                  note: '+12%',
                  positive: true,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Hard Sets',
                  value: hardSets == 0 ? '42' : hardSets.toString(),
                  note: '+8',
                  positive: true,
                ),
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'Avg. RPE',
                  value: avgRpe.toStringAsFixed(1),
                  note: 'Moderate',
                  accent: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final bool positive;
  final bool accent;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.note,
    this.positive = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: positive
                  ? const Color(0xFF26E579)
                  : accent
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[400],
              fontWeight: positive || accent
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onQuickLog;

  const _QuickActions({required this.onStart, required this.onQuickLog});

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionTile(
            icon: Icons.fitness_center,
            label: 'Start Workout',
            selected: true,
            onTap: onStart,
          ),
          _ActionTile(
            icon: Icons.assignment_outlined,
            label: 'Templates',
            onTap: onStart,
          ),
          _ActionTile(icon: Icons.history, label: 'History', onTap: () {}),
          _ActionTile(icon: Icons.bolt, label: 'Quick Log', onTap: onQuickLog),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : const Color(0xFF1B2531),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayPlanCard extends StatelessWidget {
  final VoidCallback onStart;

  const _TodayPlanCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    const items = [
      _PlanItem(
        'Push-ups',
        '3 sets - 8-15 reps',
        Icons.accessibility_new,
        true,
      ),
      _PlanItem(
        'Goblet Squat',
        '3 sets - 8-12 reps',
        Icons.downhill_skiing,
        true,
      ),
      _PlanItem(
        'Dumbbell Row',
        '3 sets - 8-12 reps',
        Icons.fitness_center,
        false,
      ),
      _PlanItem('Overhead Press', '3 sets - 8-10 reps', Icons.upload, false),
      _PlanItem('Plank', '3 sets - 30-60 sec', Icons.horizontal_rule, false),
    ];
    return _DashCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Today's Plan",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  'Full Body A',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, size: 30),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in items) _PlanRow(item: item),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Start Workout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanItem {
  final String name;
  final String details;
  final IconData icon;
  final bool complete;
  const _PlanItem(this.name, this.details, this.icon, this.complete);
}

class _PlanRow extends StatelessWidget {
  final _PlanItem item;
  const _PlanRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF202B38))),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_indicator, color: Colors.grey[700]),
          const SizedBox(width: 10),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFE9EEF2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: const Color(0xFF101923), size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.details,
                  style: TextStyle(color: Colors.grey[500], fontSize: 15),
                ),
              ],
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: item.complete
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: item.complete
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600]!,
                width: 2,
              ),
            ),
            child: item.complete
                ? const Icon(Icons.check, color: Colors.white, size: 21)
                : null,
          ),
        ],
      ),
    );
  }
}

class _MiniMetrics extends StatelessWidget {
  final ApiClient apiClient;
  const _MiniMetrics({required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: apiClient.getWeeklyAnalytics(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        final volume = data.fold<num>(
          0,
          (sum, item) => sum + ((item['volume_load'] as num?) ?? 0),
        );
        final avgRpe = data.isEmpty
            ? 7.4
            : data.fold<num>(
                    0,
                    (sum, item) => sum + ((item['avg_rpe'] as num?) ?? 0),
                  ) /
                  data.length;
        return Row(
          children: [
            Expanded(
              child: _MiniMetric(
                title: 'Volume (kg)',
                value: NumberFormat.compact().format(
                  volume == 0 ? 18240 : volume,
                ),
                note: '+12% vs last week',
                icon: Icons.bar_chart,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniMetric(
                title: 'RPE Trend',
                value: avgRpe.toStringAsFixed(1),
                note: 'Moderate',
                icon: Icons.show_chart,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: _MiniMetric(
                title: 'Streak',
                value: '5 days',
                note: 'Keep it up',
                icon: Icons.check_circle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String title;
  final String value;
  final String note;
  final IconData icon;
  const _MiniMetric({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: note == 'Moderate'
                  ? Theme.of(context).colorScheme.primary
                  : const Color(0xFF26E579),
            ),
          ),
          const SizedBox(height: 12),
          Icon(icon, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  final ApiClient apiClient;
  const _CoachCard({required this.apiClient});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: apiClient.getNextSuggestions(),
      builder: (context, snapshot) {
        final summary =
            snapshot.data?['summary']?.toString() ??
            'Review today\'s training balance before your next session.';
        return _DashCard(
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFF0C7C4C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          'Coach Recommendation',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'New',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(summary, maxLines: 3, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Text(
                      'View Details',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 30),
            ],
          ),
        );
      },
    );
  }
}

class ProtocolScreen extends StatelessWidget {
  final String title;
  final List<dynamic> protocols;
  final VoidCallback onComplete;

  const ProtocolScreen({
    super.key,
    required this.title,
    required this.protocols,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        itemCount: protocols.length,
        itemBuilder: (context, index) {
          final p = protocols[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['protocol_type'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text('Duration: ${p['duration_min']}'),
                  const SizedBox(height: 8),
                  Text(p['steps']),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onComplete,
        label: const Text('Complete'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}

class LoggerScreen extends StatefulWidget {
  const LoggerScreen({super.key});

  @override
  State<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends State<LoggerScreen> {
  final ApiClient _apiClient = ApiClient();
  final String _selectedTemplate = "FullBodyA";

  void _startWorkout() async {
    try {
      final protocols = await _apiClient.getProtocols(_selectedTemplate);
      final warmups = protocols.where((p) => p['phase'] == 'warm-up').toList();

      if (mounted && warmups.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProtocolScreen(
              title: 'Warm-up',
              protocols: warmups,
              onComplete: () {
                Navigator.of(context).pop();
                _logWorkout();
              },
            ),
          ),
        );
      } else {
        _logWorkout();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _logWorkout() async {
    try {
      await _apiClient.logSession({
        "session_date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
        "template": _selectedTemplate,
        "notes": "Logged from UI",
        "sets": [
          {
            "exercise_id": 1,
            "set_number": 1,
            "reps_completed": 10,
            "weight_kg": 20.0,
            "rir": 2,
            "rpe": 8,
          },
        ],
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Session logged!')));
        _showCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCooldown() async {
    try {
      final protocols = await _apiClient.getProtocols(_selectedTemplate);
      final cooldowns = protocols
          .where((p) => p['phase'] == 'cool-down')
          .toList();

      if (mounted && cooldowns.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProtocolScreen(
              title: 'Cool-down',
              protocols: cooldowns,
              onComplete: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: Center(
        child: ElevatedButton(
          onPressed: _startWorkout,
          child: const Text('Start & Log Workout'),
        ),
      ),
    );
  }
}

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Analytics')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiClient().getWeeklyAnalytics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text("No data yet."));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Weekly Hard Sets per Muscle Group',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    data[value.toInt()]['primary_muscle_group'],
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((entry) {
                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: (entry.value['hard_sets'] as num).toDouble(),
                              color: Theme.of(context).colorScheme.primary,
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Volume Load Breakdown',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return ListTile(
                        title: Text(item['primary_muscle_group']),
                        trailing: Text('Volume: ${item['volume_load']}'),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  void _askWhy(BuildContext context, String suggestion) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final explanation = await ApiClient().explainSuggestion(suggestion);
      if (context.mounted) {
        Navigator.pop(context); // close loader
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Coach Explanation'),
            content: Text(explanation),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _openChat(BuildContext context) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ask Coach'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ask a fitness question...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close input dialog
              final msg = controller.text;
              if (msg.isEmpty) {
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              try {
                final reply = await ApiClient().chatCoach(msg);
                if (context.mounted) {
                  Navigator.pop(context); // close loader
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Coach Reply'),
                      content: Text(reply),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Ask'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coach Recommendations')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiClient().getNextSuggestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data;
          final suggestions = (data?['suggestions'] as List<dynamic>?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Next Template: ${data?['recommended_template']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Summary: ${data?['summary']}'),
              const SizedBox(height: 16),
              const Text(
                'Suggestions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (var s in suggestions)
                ListTile(
                  leading: const Icon(Icons.lightbulb),
                  title: Text(s.toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.help_outline),
                    tooltip: 'Why?',
                    onPressed: () => _askWhy(context, s.toString()),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openChat(context),
        tooltip: 'Ask Coach',
        child: const Icon(Icons.chat),
      ),
    );
  }
}
