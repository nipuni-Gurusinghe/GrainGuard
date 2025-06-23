import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'container_info.dart';
import 'navbar.dart';

class ContainerPage extends StatefulWidget {
  const ContainerPage({super.key});

  @override
  State<ContainerPage> createState() => _ContainerPageState();
}

class _ContainerPageState extends State<ContainerPage> {
  late final DatabaseReference _userContainersRef;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Pop if no user logged in
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return;
    }
    _uid = user.uid;
    _userContainersRef = FirebaseDatabase.instance.ref('$_uid/containers');
  }

  Future<void> _addNewContainer() async {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Container"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              decoration: const InputDecoration(hintText: "Enter Container ID"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(hintText: "Enter Container Name"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Add"),
            onPressed: () async {
              final id = idCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (id.isEmpty || name.isEmpty) return;

              await _userContainersRef.child(id).set({'id': id, 'name': name});
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteContainer(String containerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Container"),
        content: const Text("Are you sure you want to delete this container?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _userContainersRef.child(containerId).remove();
    }
  }

  Future<void> _editContainerName(String containerId, String oldName) async {
    final nameCtrl = TextEditingController(text: oldName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Container Name"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: "Enter new container name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return; // Do not allow empty names
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newName = nameCtrl.text.trim();
      if (newName.isEmpty) return;

      await _userContainersRef.child(containerId).update({'name': newName});
      // StreamBuilder will automatically update UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2D7CAD), Color(0xFF2D7CAD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Your Containers",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _userContainersRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error loading data'));
                    }
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: Text('No containers yet'));
                    }

                    final dataMap = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map,
                    );

                    final containers = dataMap.values
                        .cast<Map>()
                        .map<Map<String, String>>((e) => {
                              'id': e['id'] as String,
                              'name': e['name'] as String,
                            })
                        .toList();

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: containers.length,
                      itemBuilder: (_, i) {
                        final c = containers[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContainerInfoPage(
                                      containerId: c['id']!,
                                      containerName: c['name']!,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.inventory_2,
                                          size: 26, color: Colors.white),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('ID: ${c['id']}',
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 13)),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text('Name: ${c['name']}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          tooltip: 'Edit container name',
                                          onPressed: () => _editContainerName(
                                            c['id']!,
                                            c['name']!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _confirmAndDeleteContainer(c['id']!),
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text("Delete"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  elevation: 0,
                                  minimumSize: const Size(80, 32),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  textStyle: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed: _addNewContainer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.deepOrangeAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text(
                        "Add more containers",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const Navbar(currentIndex: 1),
    );
  }
}
