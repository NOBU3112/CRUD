import 'package:flutter/material.dart';
import 'package:localstore/localstore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Notebook',
      home: ListPage(),
    );
  }
}

class SampleItem {
  final String id;
  String name;
  String content;
  final DateTime date;

  SampleItem({required this.id, required this.name, required this.content, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content':content,
      'date': date.microsecondsSinceEpoch,
    };
  }

  factory SampleItem.fromMap(Map<String, dynamic> map) {
    return SampleItem(
      id: map['id'],
      name: map['name'],
      content: map['content'],
      date: DateTime.fromMicrosecondsSinceEpoch(map['date']),
    );
  }
}

class ListPage extends StatefulWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final store = Localstore.instance;
  List<SampleItem> items = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final Map<String, dynamic>? data = await loadUserInfo();
    if (data != null && data.isNotEmpty) {
      setState(() {
        items = List<Map<String, dynamic>>.from(data['items'])
            .map((item) => SampleItem.fromMap(item))
            .toList();
      });
    }
  }

  Future<void> saveData() async {
    final userInfo = {'items': items.map((item) => item.toMap()).toList()};
    await saveUserInfo(userInfo);
  }

  void addItem(String newName, String newContent) {
    DateTime currentDate = DateTime.now();
    final newItem = SampleItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: newName,
      content: newContent,
      date: DateTime(currentDate.year,currentDate.month,currentDate.day),
    );
    setState(() {
      items.add(newItem);
    });
    saveData();
  }

  void updateItem(String id, String newName, String newContent) {
    setState(() {
      final index = items.indexWhere((element) => element.id == id);
      if (index != -1) {
        items[index].name = newName;
        items[index].content = newContent;
      }
    });
    saveData();
  }

  void removeItem(String id) {
    setState(() {
      items.removeWhere((item) => item.id == id);
    });
    saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showModalBottomSheet<Map<String,dynamic>>(
                context: context, 
                builder: (context) => const SampleItemUpdate(),
              ).then((value) {
                if (value != null) {
                  final name = value['name'];
                  final content = value['content'];
                  addItem(name, content);
                }
              });
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('${items[index].name} '),
            subtitle: Text('Added on: ${items[index].date.day}-${items[index].date.month}-${items[index].date.year} '),  
            leading: const CircleAvatar(
              foregroundImage: AssetImage('assets/images/flutter_logo.png'),  
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailPage(
                    item: items[index],
                    onUpdate: (newName, newContent) {
                      updateItem(items[index].id, newName, newContent);
                    },
                    onDelete: () {
                      removeItem(items[index].id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
            trailing: const Icon(Icons.keyboard_arrow_right),
          );
        },
      ),
    );
  }
}

class SampleItemUpdate extends StatefulWidget {
  const SampleItemUpdate({Key? key}) : super(key: key);

  @override
  State<SampleItemUpdate> createState() => _SampleItemUpdateState();
}

class _SampleItemUpdateState extends State<SampleItemUpdate> {
  late TextEditingController nameEditingController;
  late TextEditingController contentEditingController;

  @override
  void initState(){
    super.initState();
    nameEditingController = TextEditingController();
    contentEditingController = TextEditingController();
  }

  @override
  void dispose(){
    nameEditingController.dispose();
    contentEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa'),
        actions: [
          IconButton(
            onPressed: (){
              Navigator.of(context).pop({
                'name':nameEditingController.text,
                'content':contentEditingController.text});
            },
            icon: const Icon(Icons.save),
          )
        ],
      ),
      body: Column( 
        children:[
          TextFormField(
            controller: nameEditingController,
            decoration: const InputDecoration(hintText: 'Tên'),
          ),
          TextFormField(
            controller: contentEditingController,
            decoration: const InputDecoration(
              hintText: 'Nội dung',
              contentPadding: EdgeInsets.symmetric(vertical: 20.0),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemDetailPage extends StatelessWidget {
  final SampleItem item;
  final Function(String, String) onUpdate;
  final VoidCallback onDelete;

  const ItemDetailPage({
    Key? key,
    required this.item,
    required this.onUpdate,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nameEditingController = TextEditingController(text: item.name);
    final contentEditingController = TextEditingController(text: item.content);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Detail'),
        actions: [
          IconButton(
            onPressed: () {
              onUpdate(nameEditingController.text, contentEditingController.text);
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: const Text("Are you sure you want to delete this item?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text("Delete"),
                      ),
                    ],
                  );
                },
              ).then((confirmed) {
                if (confirmed ?? false) {
                  onDelete();
                  Navigator.pop(context); // Navigate back to the ListView
                }
              });
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${item.id}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: nameEditingController,
              decoration: const InputDecoration(hintText: 'Tên'),
            ),
            TextFormField(
              controller: contentEditingController,
              decoration: const InputDecoration(
                hintText: 'Nội dung',
                contentPadding: EdgeInsets.symmetric(vertical: 20.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> saveUserInfo(Map<String, dynamic> info) async {
  await Localstore.instance
      .collection('users')
      .doc('info')
      .set(info);
}

Future<Map<String, dynamic>?> loadUserInfo() async {
  final data = await Localstore.instance
      .collection('users')
      .doc('info')
      .get();
  return data;
}