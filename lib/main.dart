import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:todoapp/classes/shoppingitem.dart';
import 'package:todoapp/classes/filesystem.dart';
import 'package:path_provider/path_provider.dart';
import 'package:basic_utils/basic_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FileSystem _fileSystem = FileSystem();
  late List<String> _jsonFileNames;
  late Directory _dir;

  @override
  void initState() {
    getApplicationDocumentsDirectory().then((Directory directory) {
      _dir = directory;

      _jsonFileNames = _getFiles(context, directory);

      if (_jsonFileNames.isEmpty) {
        _fileSystem.createFile(_dir, "Dagligvarer");
        _jsonFileNames = _getFiles(context, directory);
      }

      setState(() {});
    });
    super.initState();
  }

  refreshState() {
    _jsonFileNames = _getFiles(context, _dir);
    setState(() {});
  }

  List<String> _getFiles(BuildContext context, Directory directory) {
    List<String> filenames = <String>[];
    _dir = directory;
    filenames = _fileSystem.getFiles(_dir);

    return filenames;
  }

  Widget buildTabBar(List<String> fileNames) => DefaultTabController(
        length: fileNames.length,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                ...List.generate(
                    fileNames.length,
                    (i) => Tab(
                        child: Text(fileNames[i]
                            .substring(0, fileNames[i].length - 5)))),
              ],
            ),
            title: const Text('Handlelister'),
          ),
          body: TabBarView(
            children: [
              ...List.generate(
                  fileNames.length,
                  (i) => MyHomePage(
                        jsonFile: (fileNames[i]),
                        notifyParentWidget: refreshState,
                      )),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: buildTabBar(_jsonFileNames));
  }
}

class MyHomePage extends StatefulWidget {
  final Function() notifyParentWidget;
  const MyHomePage(
      {super.key, required this.jsonFile, required this.notifyParentWidget});

  final String jsonFile;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const IconData delete = IconData(0xe1b9, fontFamily: 'MaterialIcons');

  late Directory _dir;
  late File _jsonFile;
  String _fileName = "";
  bool _fileExists = false;
  late Future<List<ShoppingItem>> _items;
  late FocusNode _focusNode;
  final _controller = TextEditingController();

  FileSystem fileSystem = FileSystem();

  void _writeToFile(List<ShoppingItem> items) {
    if (_fileExists) {
      final jsonitems = jsonEncode(items);
      _jsonFile.writeAsStringSync(jsonitems);
    } else {
      fileSystem.createFile(_dir, _fileName);
    }

    setState(() {});
  }

  void _clearInput() {
    _controller.clear();
  }

  void _writeNewItemToList(String item) {
    List<ShoppingItem> items = [];
    items = _getItemsFromLocalFile();

    item = StringUtils.capitalize(item);
    ShoppingItem shoppingItem = ShoppingItem(item, false);

    items.add(shoppingItem);

    _sortitems(items);

    _writeToFile(items);

    _resetFocus();
    _clearInput();
  }

  @override
  void initState() {
    _fileName = widget.jsonFile;
    super.initState();
    _focusNode = FocusNode();

    getApplicationDocumentsDirectory().then((Directory directory) {
      _dir = directory;
      _jsonFile = File('${_dir.path}/$_fileName');
      _jsonFile.createSync();
      _fileExists = _jsonFile.existsSync();

      if (_fileExists) {
        setState(() {
          _items = _getitems(context);
        });
      }
    });

    _items = _getitems(context);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<List<ShoppingItem>> _getitems(BuildContext context) async {
    List<ShoppingItem> items = <ShoppingItem>[];

    var decodedData = await jsonDecode(_jsonFile.readAsStringSync());
    for (int i = 0; i < decodedData.length; i++) {
      ShoppingItem item = ShoppingItem.fromJson(decodedData[i]);
      items.add(item);
    }
    _sortitems(items);
    return items;
  }

  void _sortitems(List<ShoppingItem> items) {
    items.sort((a, b) {
      if (b.bought) {
        return -1;
      } else {
        return 1;
      }
    });
  }

  List<ShoppingItem> _getItemsFromLocalFile() {
    List<ShoppingItem> items = <ShoppingItem>[];
    var data = jsonDecode(_jsonFile.readAsStringSync());
    for (int i = 0; i < data.length; i++) {
      ShoppingItem item = ShoppingItem.fromJson(data[i]);
      items.add(item);
    }
    return items;
  }

  void _resetFocus() {
    setState(() {
      _focusNode.requestFocus();
    });
  }

  void _sortListAndWriteToFile(List<ShoppingItem> items) {
    _sortitems(items);

    _writeToFile(items);
  }

  void _deleteItem(int index, List<ShoppingItem> items) {
    items.removeAt(index);
    _sortListAndWriteToFile(items);
  }

  Widget buildShoppingList(List<ShoppingItem> items) => ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return GestureDetector(
            onTap: () {
              items[index].bought = true;
              _sortListAndWriteToFile(items);
            },
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ListTile(
                      title: Text(
                        items[index].toString(),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      trailing: SizedBox(
                        width: 50,
                        child: Row(
                          children: <Widget>[
                            IconButton(
                              onPressed: () => _deleteItem(index, items),
                              icon: const Icon(delete),
                            )
                          ],
                        ),
                      ),
                    ))));
      });

  void _deleteAndRefresh() {
    if (!(fileSystem.getFiles(_dir).length == 1)) {
      fileSystem.deleteFile(_dir, _fileName);
      widget.notifyParentWidget();
      return;
    }
    print("Kan ikke slette din siste liste");
  }

  void createAndRefresh(String value) {
    fileSystem.createFile(_dir, value);
    widget.notifyParentWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(children: [
      //Text field må kanskje ha tilgang til items?
      Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            focusNode: _focusNode,
            onSubmitted: (value) {
              _writeNewItemToList(value);
              setState(() {
                _items = _getitems(context);
              });
            },
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(10.0),
              hintText: 'Skriv her for å legge til nytt element..',
            ),
          )),
      Expanded(
          child: FutureBuilder<List<ShoppingItem>>(
              future: _items,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text("Her mangler vi dessvere en liste");
                }
                final items = snapshot.data!;
                return buildShoppingList(items);
              })),
      SizedBox(
          width: double.infinity,
          child: TextButton(
              onPressed: () => _deleteAndRefresh(),
              child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text("Slett handleliste")))),
      Padding(
        padding: const EdgeInsets.all(10.0),
        child: TextField(
          onSubmitted: (value) {
            createAndRefresh(value);
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(10.0),
            hintText: "Ny Handleliste",
          ),
        ),
      )
    ])));
  }
}
