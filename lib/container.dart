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
  late final DatabaseReference _globalContainersRef;
  late final DatabaseReference _userContainersRef;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return;
    }
    _uid = user.uid;
    _globalContainersRef = FirebaseDatabase.instance.ref('containers');
    _userContainersRef = FirebaseDatabase.instance.ref('users/$_uid/myContainers');
  }

  Future<void> _addNewContainer() async {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Add New Container", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter Container ID",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "Enter Container Name",
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = idCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (id.isEmpty || name.isEmpty) return;
              
              // Add to global containers
              await _globalContainersRef.child(id).set({
                'id': id,
                'name': name,
                'ownerId': _uid,
                'createdAt': ServerValue.timestamp,
              });
              
              // Add reference to user's myContainers
              await _userContainersRef.child(id).set(true);
              
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ACC1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              shadowColor: const Color(0xFF00ACC1).withOpacity(0.4),
            ),
            child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndDeleteContainer(String containerId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        title: const Text("Delete Container", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this container?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Remove from global containers
      await _globalContainersRef.child(containerId).remove();
      // Remove from user's myContainers
      await _userContainersRef.child(containerId).remove();
    }
  }

  Future<void> _editContainerName(String containerId, String oldName) async {
    final nameCtrl = TextEditingController(text: oldName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B263B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Container Name", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter new container name",
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00ACC1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              shadowColor: const Color(0xFF00ACC1).withOpacity(0.4),
            ),
            child: const Text("Update", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newName = nameCtrl.text.trim();
      if (newName.isEmpty) return;
      // Update in global containers
      await _globalContainersRef.child(containerId).update({'name': newName});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: SafeArea(
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
                // Listen to the user's myContainers first
                stream: _userContainersRef.onValue,
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return const Center(child: Text('Error loading data', style: TextStyle(color: Colors.white)));
                  }
                  if (!userSnapshot.hasData || userSnapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('No containers yet', style: TextStyle(color: Colors.white)));
                  }

                  // Get the list of container IDs the user owns
                  final userContainerIds = (userSnapshot.data!.snapshot.value as Map).keys.cast<String>();
                  
                  // Now listen to the global containers to get details
                  return StreamBuilder<DatabaseEvent>(
                    stream: _globalContainersRef.onValue,
                    builder: (context, globalSnapshot) {
                      if (globalSnapshot.hasError) {
                        return const Center(child: Text('Error loading container details', style: TextStyle(color: Colors.white)));
                      }
                      if (!globalSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final globalContainers = globalSnapshot.data!.snapshot.value as Map? ?? {};
                      
                      // Filter only the containers this user owns
                      final containers = userContainerIds
                          .where((id) => globalContainers.containsKey(id))
                          .map((id) {
                            final containerData = globalContainers[id] as Map;
                            return {
                              'id': id,
                              'name': containerData['name'] as String,
                            };
                          })
                          .toList();

                      if (containers.isEmpty) {
                        return const Center(child: Text('No containers yet', style: TextStyle(color: Colors.white)));
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: containers.length,
                        itemBuilder: (_, i) {
                          final c = containers[i];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B263B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: GestureDetector(
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
                                            color: Colors.white.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.inventory_2, size: 26, color: Colors.white),
                                        ),
                                        const SizedBox(height: 6),
                                        Text('ID: ${c['id']}',
                                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Name: ${c['name']}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Spacer(),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                                        tooltip: 'Edit container name',
                                        onPressed: () => _editContainerName(c['id']!, c['name']!),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        tooltip: 'Delete container',
                                        iconSize: 20,
                                        color: Colors.redAccent.withOpacity(0.6),
                                        onPressed: () => _confirmAndDeleteContainer(c['id']!),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: 220,
                  child: ElevatedButton(
                    onPressed: _addNewContainer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      shadowColor: const Color(0xFF00ACC1).withOpacity(0.4),
                    ),
                    child: const Text(
                      "Add more containers",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const Navbar(currentIndex: 1),
    );
  }
}
