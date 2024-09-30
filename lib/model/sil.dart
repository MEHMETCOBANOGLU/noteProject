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
// /////////
// /////////
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/services.dart';
// import 'package:proje1/data/firestore.dart';
// import 'package:uuid/uuid.dart';

// import '../model/items.dart';

// class AddItemPage extends StatefulWidget {
//   const AddItemPage({super.key});

//   @override
//   _AddItemPageState createState() => _AddItemPageState();
// }

// class _AddItemPageState extends State<AddItemPage> {
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _subtitleController = TextEditingController();
//   final List<TextEditingController> _itemControllers = [
//     TextEditingController()
//   ];
//   final ImagePicker _picker = ImagePicker();
//   final List<String?> _base64Images = [null]; // Storing Base64 image strings
//   // final List<GlobalKey> _menuKeys = [GlobalKey()]; // Store keys for menu items
//   final GlobalKey _menuKey = GlobalKey();

//   Future<void> _addNote() async {
//     // Validate non-empty title and at least one item
//     if (_titleController.text.isNotEmpty && _itemControllers.isNotEmpty) {
//       List<String> items =
//           _itemControllers.map((controller) => controller.text).toList();


//       List<String> base64Images = _base64Images.whereType<String>().toList();

//       // Validate that there is at least one non-empty item
      
//         bool success = await FirestoreDatasource().addNote(
//           Item(
//             id: const Uuid().v4(),
//             headerValue: _titleController.text,
//             subtitle: _subtitleController.text,
//             expandedValue: items,
//             imageUrls: base64Images,
//           ),
//         );

//       if (success) {
//         _titleController.clear();
//         for (var controller in _itemControllers) {
//           controller.clear();
//         }
//         _itemControllers.clear();
//         Navigator.pop(context);
//       } else {
//         print("Error adding note");
//       }
//     }
//   }

//   void _clearFields() {
//     _titleController.clear();
//     _subtitleController.clear();
//     _itemControllers.clear();
//     _base64Images.clear();
//     _menuKeys.clear(); // Clear the keys as well

//     // Add one empty field by default
//     _addItemField();
//   }

//   Future<void> _pickImage(int index) async {
//     final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
//     if (image != null) {
//       File file = File(image.path);
//       List<int> imageBytes = await file.readAsBytes();
//       String base64Image = base64Encode(imageBytes);
//       if (_base64Images.length > index) {
//         setState(() {
//           _base64Images[index] = base64Image;
//         });
//       }
//     }
//   }

//   void _addItemField() {
//     setState(() {
//       _itemControllers.add(TextEditingController());
//       _base64Images.add(null);
//     });
//   }

//   void _removeItemField(int index) {
//     setState(() {
//       if (_itemControllers.length > 1) {
//         _itemControllers.removeAt(index);
//         _base64Images.removeAt(index);
//       } 
//     });
//   }

//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _titleController.dispose();
//     for (var controller in _itemControllers) {
//       controller.dispose();
//     }
//     super.dispose();
//   }

//   void _showCustomMenu(BuildContext context, int index, GlobalKey key) {
//     final RenderBox renderBox =
//         key.currentContext!.findRenderObject() as RenderBox;
//     final Offset offset = renderBox.localToGlobal(Offset.zero);

//     showMenu(
//       elevation: 4.0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
//       context: context,
//       position: RelativeRect.fromLTRB(
//         offset.dx, // Left
//         offset.dy + renderBox.size.height, // Top
//         offset.dx + renderBox.size.width, // Right
//         offset.dy, // Bottom
//       ),
//       items: [
//         PopupMenuItem(
//           child: ListTile(
//             leading: const Icon(Icons.photo),
//             title: const Text('Resim Ekle'),
//             onTap: () async {
//               Navigator.pop(context);
//               await _pickImage(index); // Use the image picker function
//             },
//           ),
//         ),
//         PopupMenuItem(
//           child: ListTile(
//             leading: const Icon(Icons.paste),
//             title: const Text('Yapıştır'),
//             onTap: () async {
//               Navigator.pop(context);
//               ClipboardData? data = await Clipboard.getData('text/plain');
//               if (data != null) {
//                 setState(() {
//                   _itemControllers[index].text = data.text ?? '';
//                 });
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       appBar: AppBar(
//         title: const Text('Yeni Tablo Ekle'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _titleController,
//               keyboardType: TextInputType.multiline,
//               minLines: 1, // At least one line
//               maxLines: null, // Allow multiline expansion
//               decoration: const InputDecoration(
//                 hintText: 'Başlık',
//                 icon: Icon(Icons.title),
//               ),
//             ),
//             const SizedBox(height: 10),
//             Padding(
//               padding: const EdgeInsets.only(left: 40.0),
//               child: TextField(
//                 controller: _subtitleController,
//                 keyboardType: TextInputType.multiline,
//                 minLines: 1, // At least one line
//                 maxLines: null, // Allow multiline expansion
//                 decoration: const InputDecoration(
//                   hintText: 'Alt Başlık',
//                   icon: Icon(Icons.subtitles),
//                 ),
//               ),
//             ),
//             Expanded(
//               child: ListView.builder(
//                 itemCount: _itemControllers.length + 1, // +1 for the add button
//                 itemBuilder: (context, index) {
//                   if (index < _itemControllers.length) {
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 8.0),
//                       child: Row(
//                         children: [
//                           Expanded(
//                             child: TextField(
//                               controller: _itemControllers[index],
//                               keyboardType: TextInputType.multiline,
//                               minLines: 1, // At least one line
//                               maxLines: null, // Allow multiline expansion
//                               decoration: InputDecoration(
//                                 hintText: 'Item ${index + 1}',
//                                 prefixIcon: _base64Images[index] != null
//                                     ? Image.memory(
//                                         base64Decode(_base64Images[index]!),
//                                         width: 50,
//                                         height: 50,
//                                       )
//                                     : null, // Display image if available
//                                 suffixIcon: Row(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     IconButton(
//                                       padding: EdgeInsets.zero,
//                                       icon: const Icon(Icons.more_vert_sharp),
//                                       onPressed: () => _showCustomMenu(
//                                         context,
//                                         index,
//                                         _menuKeys[index], // Use unique key here
//                                       ),
//                                     ),
//                                     IconButton(
//                                       padding: EdgeInsets.zero,
//                                       icon: const Icon(
//                                           Icons.remove_circle_outline,
//                                           color: Colors.red),
//                                       onPressed: () => _removeItemField(index),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   } else {
//                     return GestureDetector(
//                       onTap: _addItemField,
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(vertical: 4.0),
//                         padding: const EdgeInsets.all(16.0),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: const [
//                             Icon(Icons.add, color: Colors.grey),
//                             SizedBox(width: 8),
//                             Text('Add Item',
//                                 style: TextStyle(color: Colors.grey)),
//                           ],
//                         ),
//                       ),
//                     );
//                   }
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _addNote,
//               child: const Text('Ekle'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
