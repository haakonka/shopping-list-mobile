import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileSystem {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<String> get _jsonFile async {
    final path = await _localPath;
    return '$path/items.json';
  }

  void createFile(Directory dir, String fileName) {
    File file = File("${dir.path}/$fileName.json");
    file.createSync();

    file.writeAsStringSync("[]");
  }

  void deleteFile(Directory dir, String filename) {
    File file = File("${dir.path}/$filename");
    file.deleteSync();
  }

  List<String> getFiles(Directory dir) {
    List<String> strings = [];
    List<FileSystemEntity> files = dir.listSync();
    for (FileSystemEntity file in files) {
      String fileName = file.path.split('/').last;
      if (fileName.contains(".json")) {
        strings.add(fileName);
      }
    }
    return strings;
  }
}
