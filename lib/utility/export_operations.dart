import 'package:Tablify/model/TabItem.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../data/database.dart';
import '../model/items.dart';

//Export Bulut link paylaş fonksiyonu #bulutt,paylaşş
Future<void> exportToFirebase(BuildContext context) async {
  // Depolama iznini kontrol ediyoruz
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    // Eğer Android 11 veya üzeri bir sürümde çalışıyorsak MANAGE_EXTERNAL_STORAGE iznini iste
    if (Platform.isAndroid &&
        await Permission.manageExternalStorage.request().isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Depolama izni ayarlardan verilmelidir.')),
        );
        await openAppSettings();
        return;
      } else if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Depolama izni verilmedi.')),
        );
        return;
      }
    }
  }

  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      for (var note in tabNotes) {
        if (note.imageUrls != null && note.imageUrls!.isNotEmpty) {
          List<String> base64Images = [];
          for (String imageUrl in note.imageUrls!) {
            File imageFile = File(imageUrl);
            if (await imageFile.exists()) {
              String base64Image = base64Encode(imageFile.readAsBytesSync());
              base64Images.add(base64Image);
            }
          }
          note.imageUrls = base64Images;
        }
      }
      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

    String jsonData = jsonEncode(allData);
    final tempDir = await getTemporaryDirectory();
    String jsonFilePath = '${tempDir.path}/data.json';
    File jsonFile = File(jsonFilePath);
    await jsonFile.writeAsString(jsonData);

    // Dosyayı zip'leyin ve Firebase'e yükleyin
    final zipEncoder = ZipFileEncoder();
    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
    String zipFilePath = '${tempDir.path}/export_data_$formattedDate.zip';
    zipEncoder.create(zipFilePath);
    zipEncoder.addFile(jsonFile);
    zipEncoder.close();

    FirebaseStorage storage = FirebaseStorage.instance;
    File zipFile = File(zipFilePath);
    TaskSnapshot uploadTask = await storage
        .ref('tablify/exports/Tablify_dataExport_$formattedDate.zip')
        .putFile(zipFile);

    String downloadUrl = await uploadTask.ref.getDownloadURL();
    Clipboard.setData(ClipboardData(text: downloadUrl));
    await Share.share('Verileriniz burada: $downloadUrl');

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          'Veriler başarıyla yüklendi ve paylaşılabilir link oluşturuldu.'),
    ));
  } catch (e) {
    print('Hata: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Veri yüklenirken bir hata oluştu.'),
    ));
  }
}

//Exporta dosya olarak paylaşma fonksiyonu #dosyaa,paylaşş
Future<void> exportAsFile(BuildContext context) async {
  // Depolama iznini kontrol ediyoruz
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    if (Platform.isAndroid &&
        await Permission.manageExternalStorage.request().isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Depolama izni ayarlardan verilmelidir.')),
        );
        await openAppSettings();
        return;
      } else if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Depolama izni verilmedi.')),
        );
        return;
      }
    }
  }

  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      for (var note in tabNotes) {
        if (note.imageUrls != null && note.imageUrls!.isNotEmpty) {
          List<String> base64Images = [];
          for (String imageUrl in note.imageUrls!) {
            File imageFile = File(imageUrl);
            if (await imageFile.exists()) {
              String base64Image = base64Encode(imageFile.readAsBytesSync());
              base64Images.add(base64Image);
            }
          }
          note.imageUrls = base64Images;
        }
      }
      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

    String jsonData = jsonEncode(allData);
    List<int> binaryData = utf8.encode(jsonData);
    List<int>? compressedData = GZipEncoder().encode(binaryData);

    final directory = await getApplicationDocumentsDirectory();
    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
    final file =
        File('${directory.path}/Tablify_dataExport_$formattedDate.bin');
    await file.writeAsBytes(compressedData!);

    await Share.shareXFiles([XFile(file.path)],
        text: 'Here is your data export');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Veriler başarıyla dışa aktarıldı.')),
    );
    Navigator.of(context).pop();
  } catch (e) {
    print('Veri dışa aktarılırken hata oluştu: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Veriler dışa aktarılırken bir hata oluştu.')),
    );
  }
}

//Export Dosyayı cihazın indirilenler klasörüne kaydetme #dosyalarımakaydett
// import 'package:permission_handler/permission_handler.dart';

Future<void> saveToDownloads(BuildContext context) async {
  try {
    // Handle storage permissions
    var status = await Permission.storage.status;
    print("Initial storage permission status: $status");

    if (!status.isGranted) {
      // Request MANAGE_EXTERNAL_STORAGE for Android 11+
      if (Platform.isAndroid &&
          await Permission.manageExternalStorage.request().isGranted) {
        status = PermissionStatus.granted;
      } else {
        status = await Permission.storage.request();
        print("After permission request: $status");
      }
    }

    if (status.isGranted) {
      // Process file saving operations
      List<TabItem> allTabs = await SQLiteDatasource().getTabs();
      Map<String, dynamic> allData = {};

      for (TabItem tab in allTabs) {
        List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);

        for (var note in tabNotes) {
          if (note.imageUrls != null && note.imageUrls!.isNotEmpty) {
            List<String> base64Images = [];
            for (String imageUrl in note.imageUrls!) {
              File imageFile = File(imageUrl);
              if (await imageFile.exists()) {
                String base64Image = base64Encode(imageFile.readAsBytesSync());
                base64Images.add(base64Image);
              }
            }
            note.imageUrls = base64Images;
          }
        }

        allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
      }

      String jsonData = jsonEncode(allData);
      List<int> binaryData = utf8.encode(jsonData);
      List<int>? compressedData = GZipEncoder().encode(binaryData);

      // Save to Downloads folder
      String formattedDate =
          DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
      String filePath =
          '/storage/emulated/0/Download/Tablify_dataExport_$formattedDate.bin';
      final file = File(filePath);
      await file.writeAsBytes(compressedData!);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Dosya indirilenler klasörüne basarıyla kaydedildi.'),
      ));
      Navigator.of(context).pop();
    } else if (status.isPermanentlyDenied) {
      print("Permission permanently denied");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Depolama izni kalıcı olarak reddedildi. Lütfen ayarlardan etkinleştirin.')),
      );
      await openAppSettings();
    } else {
      print("Permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Depolama izni reddedildi.')),
      );
    }
  } catch (e) {
    print('Error saving file: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dosya indirilirken bir hata oluştu.'),
    ));
  }
}

//Export HTML dosyası olarak Firebase'e yükleme #htmll
Future<void> exportAsHtml(BuildContext context) async {
  // Depolama iznini kontrol ediyoruz
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    if (Platform.isAndroid &&
        await Permission.manageExternalStorage.request().isGranted) {
      status = PermissionStatus.granted;
    } else {
      status = await Permission.storage.request();
      if (status.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Depolama izni ayarlardan verilmelidir.')),
        );
        await openAppSettings();
        return;
      } else if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Depolama izni verilmedi.')),
        );
        return;
      }
    }
  }

  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

    String htmlContent = """
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Export Edilen Veriler</title>
</head>
<body>
  <h1>Export Edilen Veriler</h1>
""";

    for (var tab in allTabs) {
      htmlContent += "<fieldset><legend>${tab.name}</legend>";
      List<dynamic> items = allData[tab.name];
      for (var itemMap in items) {
        Item item = Item.fromMap(itemMap);
        htmlContent +=
            "<table border='1' cellpadding='5' style='width: 100%;'>";
        htmlContent +=
            "<tr><th style='text-align: left; width: 30%;'>Başlık</th><td>${item.headerValue}</td></tr>";
        htmlContent +=
            "<tr><th style='text-align: left;'>Alt Başlık</th><td>${item.subtitle ?? 'Yok'}</td></tr>";
        htmlContent +=
            "<tr><th style='text-align: left;'>Items</th><td><ul>${item.expandedValue.map((val) => "<li>$val</li>").join('')}</ul></td></tr>";
        htmlContent += "</table><br/>";
      }
      htmlContent += "</fieldset><br/>";
    }
    htmlContent += "</body></html>";

    final directory = await getApplicationDocumentsDirectory();
    String fileName = 'export_${const Uuid().v4()}.html';
    File file = File('${directory.path}/$fileName');
    await file.writeAsString(htmlContent);

    final FirebaseStorage storage = FirebaseStorage.instance;
    TaskSnapshot uploadTask =
        await storage.ref('tablify/exports/html/$fileName').putFile(file);
    String downloadUrl = await uploadTask.ref.getDownloadURL();

    await launch(downloadUrl);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('HTML linki kopyalandı ve tarayıcı açılıyor...'),
    ));
  } catch (e) {
    print('Hata: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('HTML export sırasında bir hata oluştu.'),
    ));
  }
}
