// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:proje1/model/items.dart';
// import 'package:uuid/uuid.dart';
// import 'package:device_info_plus/device_info_plus.dart';

// class FirestoreDatasource {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<String> getDeviceId() async {
//     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

//     if (Platform.isAndroid) {
//       AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
//       return androidInfo.id; // Android cihaz ID'si
//     } else if (Platform.isIOS) {
//       IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
//       return iosInfo.identifierForVendor ??
//           'UnknownIOSDevice'; // iOS cihaz ID'si
//     }
//     return 'UnknownDevice'; // Eğer cihaz ID alınamazsa
//   }

//   Future<String?> uploadImage(File image) async {
//     List<int> imageBytes = await image.readAsBytes();
//     return base64Encode(imageBytes);
//   }

//   // Not ekleme fonksiyonu
//   Future<bool> addNote(Item item) async {
//     try {
//       var uuid = const Uuid().v4();
//       var order = DateTime.now().millisecondsSinceEpoch;

//       String deviceId = await getDeviceId();

//       // Firestore'a notu ekleme işlemi
//       await _firestore
//           .collection('users')
//           .doc(deviceId)
//           .collection('notes')
//           .doc(uuid)
//           .set({
//         'id': uuid,
//         'title': item.headerValue,
//         'subtitle': item.subtitle,
//         'items': item.expandedValue,
//         'imageUrls': item.imageUrls ?? [],
//         'isExpanded': item.isExpanded,
//         'order': order,
//       });
//       return true;
//     } catch (e) {
//       print(e);
//       return false;
//     }
//   }

//   // Notları almak için stream fonksiyonu
//   Stream<List<Item>> getNotes() async* {
//     String deviceId = await getDeviceId();
//     yield* _firestore
//         .collection('users')
//         .doc(deviceId)
//         .collection('notes')
//         .orderBy('order')
//         .snapshots()
//         .map((snapshot) => snapshot.docs.map((doc) {
//               var data = doc.data();
//               return Item(
//                 id: data['id'],
//                 headerValue: data['title'],
//                 expandedValue: List<String>.from(data['items']),
//                 subtitle: data['subtitle'],
//                 imageUrls: List<String>.from(data['imageUrls'] ?? []),
//                 isExpanded: data['isExpanded'] ?? false,
//               );
//             }).toList());
//   }

// // Notu güncelleme fonksiyonu
//   Future<bool> updateNote(String id, String title, String subtitle,
//       List<String> items, List<String> imageUrls) async {
//     try {
//       String deviceId = await getDeviceId();

//       await _firestore
//           .collection('users')
//           .doc(deviceId)
//           .collection('notes')
//           .doc(id)
//           .update({
//         'title': title,
//         'subtitle': subtitle, // Alt başlığı ekliyoruz
//         'items': items,
//         'imageUrls': imageUrls, // Resim URL'lerini doğrudan ekliyoruz
//       });
//       return true;
//     } catch (e) {
//       print(e);
//       return false;
//     }
//   }

//   // Not silme fonksiyonu
//   Future<bool> deleteItem(String id) async {
//     try {
//       String deviceId = await getDeviceId();

//       await _firestore
//           .collection('users')
//           .doc(deviceId)
//           .collection('notes')
//           .doc(id)
//           .delete();
//       return true;
//     } catch (e) {
//       print(e);
//       return false;
//     }
//   }

//   // Genişletme/daraltma durumu güncelleme fonksiyonu
//   Future<void> updateExpandedState(String id, bool isExpanded) async {
//     try {
//       String deviceId = await getDeviceId();

//       await _firestore
//           .collection('users')
//           .doc(deviceId)
//           .collection('notes')
//           .doc(id)
//           .update({'isExpanded': isExpanded});
//     } catch (e) {
//       print("Error updating expanded state: $e");
//     }
//   }

//   // Notların sırasını güncelleme fonksiyonu
//   Future<void> updateNoteOrder(List<Item> data) async {
//     try {
//       String deviceId = await getDeviceId();

//       for (int i = 0; i < data.length; i++) {
//         await _firestore
//             .collection('users')
//             .doc(deviceId)
//             .collection('notes')
//             .doc(data[i].id)
//             .update({
//           'order': i, // Her notun sırasını güncelliyoruz.
//         });
//       }
//     } catch (e) {
//       print("Error updating note order: $e");
//     }
//   }

//   // Future<String?> uploadImage(File image) async {
//   //   try {
//   //     var uuid = const Uuid().v4();
//   //     Reference storageRef =
//   //         FirebaseStorage.instance.ref().child('images/$uuid.jpg');
//   //     UploadTask uploadTask = storageRef.putFile(image);
//   //     TaskSnapshot taskSnapshot = await uploadTask;
//   //     String imageUrl = await taskSnapshot.ref.getDownloadURL();
//   //     print("Image uploaded and URL is: $imageUrl"); // Bu satırı ekleyin
//   //     return imageUrl;
//   //   } catch (e) {
//   //     print("Error uploading image: $e"); // Bu hata mesajını kontrol edin
//   //     return null;
//   //   }
//   // }

//   // Tüm notları alma fonksiyonu
//   Future<List<Item>> getItems() async {
//     try {
//       String deviceId = await getDeviceId();

//       QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .doc(deviceId)
//           .collection('notes')
//           .orderBy('order')
//           .get();

//       List<Item> items = snapshot.docs.map((doc) {
//         var data = doc.data() as Map<String, dynamic>;
//         return Item(
//           id: data['id'],
//           headerValue: data['title'],
//           expandedValue: List<String>.from(data['items']),
//           subtitle: data['subtitle'],
//           imageUrls: List<String>.from(data['imageUrls'] ?? []),
//           isExpanded: data['isExpanded'] ?? false,
//         );
//       }).toList();

//       return items;
//     } catch (e) {
//       print("Error fetching items: $e");
//       return [];
//     }
//   }

//   // Tüm notları silme fonksiyonu
//   Future<void> deleteAllItems() async {
//     try {
//       String deviceId = await getDeviceId();

//       QuerySnapshot snapshot = await _firestore
//           .collection('users')
//           .doc(deviceId)
//           .collection('notes')
//           .get();

//       for (QueryDocumentSnapshot doc in snapshot.docs) {
//         await _firestore
//             .collection('users')
//             .doc(deviceId)
//             .collection('notes')
//             .doc(doc.id)
//             .delete();
//       }

//       print("All items deleted successfully.");
//     } catch (e) {
//       print("Error deleting all items: $e");
//     }
//   }
// }
