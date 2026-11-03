import 'package:flutter/material.dart';

import '../data/pos_database.dart';
import '../models/pos_models.dart';

class TablesAndTeamsScreen extends StatefulWidget {
  const TablesAndTeamsScreen({super.key});

  @override
  State<TablesAndTeamsScreen> createState() => _TablesAndTeamsScreenState();
}

class _TablesAndTeamsScreenState extends State<TablesAndTeamsScreen> {
  late Future<List<PosTeam>> _teamsFuture;
  late Future<List<PosTable>> _tablesFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _teamsFuture = PosDatabase.instance.getTeams();
      _tablesFuture = PosDatabase.instance.getTables();
    });
  }

  Future<void> _addTeam() async {
    final nameController = TextEditingController();
    final colorController = TextEditingController(text: '#8A4B18');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Team name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: colorController,
              decoration: const InputDecoration(labelText: 'Color code (#RRGGBB)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final trimmed = nameController.text.trim();
              if (trimmed.isEmpty) {
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await PosDatabase.instance.addTeam(PosTeam(
        name: nameController.text.trim(),
        color: colorController.text.trim().isEmpty ? '#8A4B18' : colorController.text.trim(),
      ));
      _reload();
    }

    nameController.dispose();
    colorController.dispose();
  }

  Future<void> _addTable() async {
    final labelController = TextEditingController();
    final teams = await PosDatabase.instance.getTeams();
    final teamNames = teams.map((team) => team.name).toList();
    String? selectedTeamName = teamNames.isNotEmpty ? teamNames.first : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Table number (00-99)'),
              ),
              const SizedBox(height: 12),
              if (teamNames.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: selectedTeamName,
                  decoration: const InputDecoration(labelText: 'Team'),
                  items: teamNames
                      .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                      .toList(),
                  onChanged: (value) => setState(() => selectedTeamName = value),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = labelController.text.trim();
                if (value.isEmpty) {
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final tableValue = labelController.text.trim();
      final safeLabel = tableValue.length == 1 ? '0$tableValue' : tableValue;
      await PosDatabase.instance.addTable(PosTable(
        label: safeLabel,
        teamName: selectedTeamName ?? 'General',
        occupied: false,
      ));
      _reload();
    }

    labelController.dispose();
  }

  Future<void> _toggleTable(PosTable table) async {
    await PosDatabase.instance.updateTable(PosTable(
      id: table.id,
      label: table.label,
      teamName: table.teamName,
      occupied: !table.occupied,
    ));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tables & teams')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FutureBuilder<List<PosTeam>>(
                future: _teamsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final teams = snapshot.data ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Teams', style: TextStyle(fontWeight: FontWeight.bold))),
                              TextButton.icon(
                                onPressed: _addTeam,
                                icon: const Icon(Icons.add),
                                label: const Text('Add team'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (teams.isEmpty)
                            const Text('No teams yet.')
                          else
                            Expanded(
                              child: ListView.builder(
                                itemCount: teams.length,
                                itemBuilder: (context, index) {
                                  final team = teams[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Color(int.tryParse(team.color.replaceAll('#', '0xFF')) ?? 0xFF8A4B18),
                                    ),
                                    title: Text(team.name),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FutureBuilder<List<PosTable>>(
                future: _tablesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final tables = snapshot.data ?? [];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Tables', style: TextStyle(fontWeight: FontWeight.bold))),
                              TextButton.icon(
                                onPressed: _addTable,
                                icon: const Icon(Icons.add),
                                label: const Text('Add table'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (tables.isEmpty)
                            const Text('No tables yet.')
                          else
                            Expanded(
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: tables.length,
                                itemBuilder: (context, index) {
                                  final table = tables[index];
                                  return GestureDetector(
                                    onTap: () => _toggleTable(table),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: table.occupied ? Colors.orange.shade200 : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black26),
                                      ),
                                      padding: const EdgeInsets.all(6),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            table.label,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            table.teamName.isEmpty ? 'Unassigned' : table.teamName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                          Text(
                                            table.occupied ? 'Occupied' : 'Open',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
