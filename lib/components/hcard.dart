import 'dart:math';

import 'package:flutter/material.dart';
import 'package:proje1/data/firestore.dart';
import '../model/courses.dart';
import '../pages/edit_pages.dart';

class HCard extends StatelessWidget {
  const HCard({
    Key? key,
    required this.note,
  }) : super(key: key);

  final NoteModel note;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(note.id), // UniqueKey(),
      onDismissed: (direction) {
        Firestore_Datasource().delet_note(note.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_sweep, color: Colors.red, size: 30),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 110),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          // color: note.color,
          color: Color((Random().nextDouble() * 0xFFFFFF).toInt())
              .withOpacity(1.0),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontFamily: "Poppins",
                        color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  // Text(
                  //   section.caption,
                  //   style: const TextStyle(
                  //       fontSize: 17, fontFamily: "Inter", color: Colors.white),
                  // )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: VerticalDivider(thickness: 0.8, width: 0),
            ),
            IconButton(
                onPressed: () {
                  // Note nesnesini edit dialog'a gönderiyoruz
                  showEditDialog(context, note);
                },
                icon: const Icon(Icons.edit_note_rounded,
                    size: 30, color: Colors.white)),
            // Image.asset(section.image)
          ],
        ),
      ),
    );
  }
}
