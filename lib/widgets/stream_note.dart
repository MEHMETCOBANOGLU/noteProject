// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:proje1/data/firestore.dart';
// import 'package:proje1/widgets/task_widgets.dart';

// class Stream_note extends StatelessWidget {
//   Stream_note({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<QuerySnapshot>(
//         stream: Firestore_Datasource().stream(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return CircularProgressIndicator();
//           }
//           final noteslist = Firestore_Datasource().getNotes(snapshot);
//           return ListView.builder(
//             shrinkWrap: true,
//             itemBuilder: (context, index) {
//               final note = noteslist[index];
//               return Dismissible(
//                   key: UniqueKey(),
//                   onDismissed: (direction) {
//                     Firestore_Datasource().delet_note(note.id);
//                   },
//                   child: TaskWidget(note));
//             },
//             itemCount: noteslist.length,
//           );
//         });
//   }
// }
