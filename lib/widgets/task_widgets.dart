// import 'package:expandable/expandable.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:proje1/model/courses.dart';
// import 'package:proje1/pages/edit_pages.dart';
// import '../const/colors.dart';

// class TaskWidget extends StatefulWidget {
//   final NoteModel _note;
//   TaskWidget(this._note, {super.key});

//   @override
//   _TaskWidgetState createState() => _TaskWidgetState();
// }

// class _TaskWidgetState extends State<TaskWidget> {
//   late ExpandableController
//       controller; // ExpandableController'ı burada tanımlıyoruz

//   @override
//   void initState() {
//     super.initState();
//     controller = ExpandableController(); // controller burada başlatılıyor
//   }

//   @override
//   void dispose() {
//     controller.dispose(); // controller burada dispose ediliyor
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(
//           horizontal: 15, vertical: 15), // Container padding ayarlanıyor
//       child: Container(
//         width: double.infinity, // Genişlik tamamen kaplanıyor
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(10), // Yuvarlak köşeler
//           color: Colors.white, // Arka plan rengi beyaz
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.2), // Gölge rengi gri
//               spreadRadius: 5, // Gölgenin yayılması
//               blurRadius: 7, // Gölgenin bulanıklığı
//               offset: const Offset(0, 2), // Gölgenin konumu
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(10),
//           child: ExpandablePanel(
//             controller: controller,
//             theme: const ExpandableThemeData(
//               headerAlignment: ExpandablePanelHeaderAlignment.center,
//               tapBodyToExpand: true,
//               tapBodyToCollapse: true,
//               hasIcon: true, // Genişleme ikonu ekleniyor
//               tapHeaderToExpand: true,
//             ),
//             // header
//             header: Padding(
//               padding: const EdgeInsets.symmetric(
//                   horizontal:
//                       10), // Başlık için soldan ve sağdan padding ekleniyor
//               child: Text(
//                 widget._note.title, // Başlık yazısı gösteriliyor
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             //collapsed
//             collapsed: GestureDetector(
//               onTap: () {
//                 controller.toggle();
//               },
//               child: Text(
//                 widget._note
//                     .subtitle, // Alt başlık gösteriliyor (daraltıldığında)
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.w400,
//                   color: Colors.grey,
//                 ),
//                 softWrap: true, // Satır sarmalama aktif
//                 maxLines: 3, // En fazla 3 satır gösterilecek
//                 overflow: TextOverflow
//                     .ellipsis, // Uzun metinler üç nokta ile kesilecek
//               ),
//             ),

//             //expanded
//             expanded: Column(
//               crossAxisAlignment: CrossAxisAlignment.start, // Sola hizalanıyor
//               children: [
//                 const SizedBox(height: 10), // 10 birim boşluk ekleniyor
//                 Text(
//                   widget._note
//                       .subtitle, // Alt başlık genişletildiğinde gösteriliyor
//                   style: const TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w400,
//                     color: Colors.grey,
//                   ),
//                 ),
//                 const SizedBox(
//                     height: 10), // Alt başlık ile buton arasında boşluk
//                 Row(
//                   mainAxisAlignment:
//                       MainAxisAlignment.end, // Buton sağda hizalanıyor
//                   children: [
//                     GestureDetector(
//                       onTap: () {
//                         Navigator.of(context).push(MaterialPageRoute(
//                           builder: (context) => EditPages(widget
//                               ._note), // Not düzenleme sayfasına yönlendirme
//                         ));
//                       },
//                       child: Container(
//                         width: 90, // Buton genişliği
//                         height: 28, // Buton yüksekliği
//                         decoration: BoxDecoration(
//                           color: custom_green, // Buton arka plan rengi
//                           borderRadius: BorderRadius.circular(
//                               18), // Butonun köşe yuvarlaklığı
//                         ),
//                         child: const Center(
//                           child: Text(
//                             'edit', // Buton içeriği 'edit'
//                             style: TextStyle(
//                               color: Colors.white, // Yazı rengi beyaz
//                               fontSize: 14, // Yazı boyutu
//                               fontWeight: FontWeight.bold, // Yazı kalınlığı
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             builder: (context, collapsed, expanded) => Padding(
//               padding: const EdgeInsets.all(10).copyWith(
//                   top:
//                       0), // Genişleme ve daraltma bölümleri için padding ayarlanıyor
//               child: Expandable(
//                 collapsed: collapsed,
//                 expanded: expanded,
//                 theme: const ExpandableThemeData(
//                     crossFadePoint: 0), // Genişleme animasyonu için tema
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
