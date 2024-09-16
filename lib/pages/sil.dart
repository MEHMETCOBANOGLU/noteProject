import 'dart:math';
import 'package:flutter/material.dart';
import 'package:proje1/data/firestore.dart';
import 'package:proje1/model/courses.dart';

class EditNotes extends StatefulWidget {
  final NoteModel note; // Bu nesne edit sayfasına gelecek

  const EditNotes({Key? key, required this.note}) : super(key: key);

  @override
  State<EditNotes> createState() => _EditNotesState();
}

class _EditNotesState extends State<EditNotes> {
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _subtitleController = TextEditingController(text: widget.note.subtitle);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      surfaceTintColor: const Color(0x00ffffff),
      backgroundColor: const Color(0x00ffffff),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color((Random().nextDouble() * 0xFFFFFF).toInt())
                  .withOpacity(1.0),
              Color((Random().nextDouble() * 0xFFFFFF).toInt())
                  .withOpacity(1.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color((Random().nextDouble() * 0xFFFFFF).toInt())
                  .withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Color((Random().nextDouble() * 0xFFFFFF).toInt())
                  .withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: "Title",
                hintStyle: TextStyle(color: Colors.white),
                border: InputBorder.none,
              ),
              cursorColor: Colors.white,
            ),
            const Divider(
              color: Colors.white,
              thickness: 0.4,
            ),
            TextField(
              controller: _subtitleController,
              decoration: const InputDecoration(
                hintText: "Subtitle",
                hintStyle: TextStyle(color: Colors.white),
                border: InputBorder.none,
              ),
              cursorColor: Colors.white,
              maxLines: 6,
            ),
            const Divider(
              color: Colors.white,
              thickness: 0.4,
            ),
            TextButton(
              onPressed: () {
                Firestore_Datasource().Update_Note(widget.note.id,
                    _titleController.text, _subtitleController.text);

                Navigator.of(context).pop();
              },
              child: const Text(
                'Edit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showEditDialog(BuildContext context, NoteModel note) {
  showDialog(
    context: context,
    builder: (context) {
      return EditNotes(note: note); // NoteModel nesnesi burada geçiliyor
    },
  );
}
