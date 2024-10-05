// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter/services.dart'; // For copying text to clipboard
// import 'package:proje1/aym/isimDilVeSecenek_duzenleyici.dart';
// import '../utility/image_copy.dart'; // Assuming this is where copyImageToClipboard is defined

// // Resim ve metin kopyalama dialogu
// Future<void> selectAndCopyImageDialog(
//     BuildContext context, String expandedValue) async {
//   final ImagePicker picker = ImagePicker();
//   XFile? selectedImage;

//   return showDialog(
//     context: context,
//     builder: (context) {
//       return StatefulBuilder(
//         builder: (BuildContext context, StateSetter setState) {
//           return AlertDialog(
//             title: const Center(
//                 child: Text(
//               'Resim ve Metin Kopyalama',
//               style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontStyle: FontStyle.italic,
//                   color: Colors.green),
//             )),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: <Widget>[
//                 // Display the clean version of the expanded value
//                 // Text(
//                 //   getDisplayText(expandedValue), // Clean the text
//                 //   style: const TextStyle(
//                 //       fontSize: 16, fontWeight: FontWeight.bold),
//                 // ),
//                 // const SizedBox(height: 10),

//                 // Image display
//                 selectedImage == null
//                     ? Container(
//                         height: 150,
//                         width: 150,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                         ),
//                         child: const Center(
//                           child: Text('Resim seçilmedi'),
//                         ),
//                       )
//                     : Container(
//                         height: 150,
//                         width: 150,
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                         ),
//                         child: Image.file(
//                           File(selectedImage!.path),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                 const SizedBox(height: 10),

//                 // Button to select an image
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green[50],
//                   ),
//                   onPressed: () async {
//                     final XFile? image =
//                         await picker.pickImage(source: ImageSource.gallery);
//                     if (image != null) {
//                       setState(() {
//                         selectedImage = image;
//                       });
//                     }
//                   },
//                   child: const Text('Resim Seç',
//                       style: TextStyle(
//                           color: Colors.grey, fontWeight: FontWeight.bold)),
//                 ),
//               ],
//             ),
//             actions: <Widget>[
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   TextButton(
//                     child: const Text(
//                       'İptal',
//                       style: TextStyle(color: Colors.black),
//                     ),
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                   ),

//                   // Copy both clean text and image
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green[50],
//                     ),
//                     child: const Text('Kopyala',
//                         style: TextStyle(
//                             color: Colors.green, fontWeight: FontWeight.bold)),
//                     onPressed: () async {
//                       // // Get the clean version of the text
//                       // String displayText = getDisplayText(expandedValue);

//                       // // Copy the cleaned text to the clipboard
//                       // Clipboard.setData(ClipboardData(text: displayText));

//                       // Check if an image is selected and copy it
//                       if (selectedImage != null) {
//                         await copyImageToClipboard(
//                             context, selectedImage!.path);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                               duration: Duration(seconds: 1),
//                               content:
//                                   Text('Metin ve resim panoya kopyalandı!')),
//                         );
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                               duration: Duration(seconds: 1),
//                               content: Text(
//                                   'Metin panoya kopyalandı! Resim seçilmedi.')),
//                         );
//                       }

//                       Navigator.of(context).pop();
//                     },
//                   ),
//                 ],
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }
