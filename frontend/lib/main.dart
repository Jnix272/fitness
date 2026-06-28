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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
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
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: 'Coach'),
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
  final String _selectedTemplate = "FullBodyA";

  void _startWorkout() async {
    try {
      final protocols = await _apiClient.getProtocols(_selectedTemplate);
      final warmups = protocols.where((p) => p['phase'] == 'warm-up').toList();

      if (mounted && warmups.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProtocolScreen(
          title: 'Warm-up',
          protocols: warmups,
          onComplete: () {
            Navigator.of(context).pop();
            _logWorkout();
          },
        )));
      } else {
        _logWorkout();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            "rpe": 8
          }
        ]
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session logged!')));
        _showCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCooldown() async {
    try {
      final protocols = await _apiClient.getProtocols(_selectedTemplate);
      final cooldowns = protocols.where((p) => p['phase'] == 'cool-down').toList();

      if (mounted && cooldowns.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProtocolScreen(
          title: 'Cool-down',
          protocols: cooldowns,
          onComplete: () {
            Navigator.of(context).pop();
          },
        )));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Coach'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Greeting & Date
              Text(
                'Today\'s Workout',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Quick Start Button
              FilledButton.icon(
                onPressed: _startWorkout,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Workout'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Overview
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Sessions',
                      value: '12',
                      subtitle: 'This week',
                      icon: Icons.fitness_center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Streak',
                      value: '5',
                      subtitle: 'Days',
                      icon: Icons.local_fire_department,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Analytics
              Text(
                'Weekly Highlights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FutureBuilder<List<dynamic>>(
                  future: _apiClient.getWeeklyAnalytics(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text('Unable to load analytics', style: TextStyle(color: Colors.red[400])),
                      );
                    }

                    final data = snapshot.data ?? [];
                    if (data.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('No data yet. Start a workout to see your progress!'),
                      );
                    }

                    return Column(
                      children: data.take(3).map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item['primary_muscle_group'] ?? 'Unknown'),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item['hard_sets']} sets',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Vol: ${item['volume_load']} kg',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Coach Suggestions
              Text(
                'Coach Recommendations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: _apiClient.getNextSuggestions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Unable to load suggestions',
                        style: TextStyle(color: Colors.red[400]),
                      ),
                    );
                  }

                  final data = snapshot.data ?? {};
                  final nextTemplate = data['recommended_template'] ?? 'N/A';
                  final suggestions = (data['suggestions'] as List<dynamic>?) ?? [];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primary),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next: $nextTemplate',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (suggestions.isNotEmpty)
                          ...suggestions.take(2).map((s) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb, size: 16, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(child: Text(s.toString())),
                              ],
                            ),
                          )),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class ProtocolScreen extends StatelessWidget {
  final String title;
  final List<dynamic> protocols;
  final VoidCallback onComplete;

  const ProtocolScreen({super.key, required this.title, required this.protocols, required this.onComplete});

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
                  Text(p['protocol_type'], style: Theme.of(context).textTheme.titleLarge),
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
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProtocolScreen(
          title: 'Warm-up',
          protocols: warmups,
          onComplete: () {
            Navigator.of(context).pop();
            _logWorkout();
          },
        )));
      } else {
        _logWorkout();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            "rpe": 8
          }
        ]
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session logged!')));
        _showCooldown();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showCooldown() async {
    try {
      final protocols = await _apiClient.getProtocols(_selectedTemplate);
      final cooldowns = protocols.where((p) => p['phase'] == 'cool-down').toList();
      
      if (mounted && cooldowns.isNotEmpty) {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProtocolScreen(
          title: 'Cool-down',
          protocols: cooldowns,
          onComplete: () {
            Navigator.of(context).pop();
          },
        )));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          
          final data = snapshot.data ?? [];
          if (data.isEmpty) return const Center(child: Text("No data yet."));

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Weekly Hard Sets per Muscle Group', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              if (value.toInt() >= 0 && value.toInt() < data.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(data[value.toInt()]['primary_muscle_group'], style: const TextStyle(fontSize: 10)),
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
                            )
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Volume Load Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // close loader
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
          decoration: const InputDecoration(hintText: 'Ask a fitness question...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close input dialog
              final msg = controller.text;
              if (msg.isEmpty) return;
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
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
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Ask'),
          )
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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          
          final data = snapshot.data;
          final suggestions = (data?['suggestions'] as List<dynamic>?) ?? [];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Next Template: ${data?['recommended_template']}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Summary: ${data?['summary']}'),
              const SizedBox(height: 16),
              const Text('Suggestions:', style: TextStyle(fontWeight: FontWeight.bold)),
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
