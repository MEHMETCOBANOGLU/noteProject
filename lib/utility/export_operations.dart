import 'package:Tablify/model/TabItem.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
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
  try {
    // SQLite veritabanından tüm sekmeleri ve notları alıyoruz
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    // Her sekmedeki notları topla
    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      allData[tab.name] = tabNotes.map((e) => e.toMap()).toList();
    }

    // JSON formatına çevir
    String jsonData = jsonEncode(allData);

    // Geçici dizine JSON dosyasını kaydet
    final tempDir = await getTemporaryDirectory();
    String jsonFilePath = '${tempDir.path}/data.json';
    File jsonFile = File(jsonFilePath);
    await jsonFile.writeAsString(jsonData);

    // Zip dosyasını oluştur
    final zipEncoder = ZipFileEncoder();
    String zipFilePath = '${tempDir.path}/export_data.zip';
    zipEncoder.create(zipFilePath);

    // JSON dosyasını zip'e ekle
    zipEncoder.addFile(jsonFile);

    // Resimler için "images" klasörünü zip dosyası içinde oluşturun
    Directory imagesDir = Directory('${tempDir.path}/images');
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    for (var tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      for (var item in tabNotes) {
        if (item.imageUrls != null && item.imageUrls!.isNotEmpty) {
          for (String imageUrl in item.imageUrls!) {
            if (imageUrl.isNotEmpty) {
              try {
                Uri uri = Uri.parse(imageUrl);
                if (uri.scheme == 'http' || uri.scheme == 'https') {
                  // Eğer URL internetten ise görseli indir
                  final response =
                      await HttpClient().getUrl(Uri.parse(imageUrl));
                  final fileBytes = await response.close();
                  String fileName = imageUrl.split('/').last;
                  File imageFile = File('${imagesDir.path}/$fileName');
                  await fileBytes.pipe(imageFile.openWrite());

                  // Görseli "images" klasörü içinde zip dosyasına ekleyin
                  zipEncoder.addFile(imageFile, 'images/$fileName');
                } else {
                  // Yerel dosya yolunu kontrol et ve zip'e ekle
                  File localImageFile = File(imageUrl);
                  if (await localImageFile.exists()) {
                    String fileName = localImageFile.path.split('/').last;
                    File imageFile = File('${imagesDir.path}/$fileName');
                    localImageFile.copySync(imageFile.path);

                    // Görseli "images" klasörü içinde zip dosyasına ekleyin
                    zipEncoder.addFile(imageFile, 'images/$fileName');
                  } else {
                    print('Yerel dosya bulunamadı: $imageUrl');
                  }
                }
              } catch (e) {
                print('Resim indirilemedi veya eklenemedi: $e');
              }
            } else {
              // Eğer URL boşsa, "resim yok" mesajı ekleyebilirsiniz
              print('Boş resim URL\'si bulundu.');
            }
          }
        }
      }
    }

    zipEncoder.close();

    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());

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
    // Hata mesajı
    print('Hata: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Veri yüklenirken bir hata oluştu.'),
    ));
  }
}

//Exporta dosya olarak paylaşma fonksiyonu #dosyaa,paylaşş
Future<void> exportAsFile(BuildContext context) async {
  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
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
Future<void> saveToDownloads(BuildContext context) async {
  try {
    List<TabItem> allTabs = await SQLiteDatasource().getTabs();
    Map<String, dynamic> allData = {};

    for (TabItem tab in allTabs) {
      List<Item> tabNotes = await SQLiteDatasource().getNotes(tab.id);
      allData[tab.name] = tabNotes
          .map((e) => e.toMap())
          .toList(); // Her sekmenin notlarını ekliyoruz
    }

    String jsonData = jsonEncode(allData);
    List<int> binaryData = utf8.encode(jsonData);
    List<int>? compressedData = GZipEncoder().encode(binaryData);

    final directory = Directory('/storage/emulated/0/Download');
    String formattedDate =
        DateFormat('dd.MM.yyyy_HH.mm').format(DateTime.now());
    final file =
        File('${directory.path}/Tablify_dataExport_$formattedDate.bin');
    await file.writeAsBytes(compressedData!);

    // Başarı mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dosya başarıyla indirilenler klasörüne kaydedildi.'),
    ));
    Navigator.of(context).pop();
  } catch (e) {
    // Hata mesajı göster
    print('Dosya kaydedilirken hata oluştu: $e');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Dosya kaydedilirken bir hata oluştu.'),
    ));
  }
}

//Export HTML dosyası olarak Firebase'e yükleme #htmll
Future<void> exportAsHtml(BuildContext context) async {
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

    allTabs.forEach((tab) {
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
    });
    htmlContent += "</body></html>";

    final directory = await getApplicationDocumentsDirectory();
    String fileName = 'export_${Uuid().v4()}.html';
    File file = File('${directory.path}/$fileName');
    await file.writeAsString(htmlContent);
    final FirebaseStorage _storage = FirebaseStorage.instance;
    // Firebase Storage'a yükle ve linki al
    TaskSnapshot uploadTask =
        await _storage.ref('tablify/exports/html/$fileName').putFile(file);
    String downloadUrl = await uploadTask.ref.getDownloadURL();

    // Linki doğrudan tarayıcıda aç
    await launch(downloadUrl);

    // İşlem tamamlandığında kullanıcıya bildirim göster
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('HTML linki kopyalandı ve tarayıcı açılıyor...'),
    ));
  } catch (e) {
    print('Hata: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('HTML export sırasında bir hata oluştu.'),
    ));
  }
}
