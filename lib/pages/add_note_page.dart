import 'dart:math';
import 'package:flutter/material.dart';
import 'package:proje1/data/firestore.dart';

class AddNotePopup extends StatefulWidget {
  const AddNotePopup({Key? key}) : super(key: key);

  @override
  State<AddNotePopup> createState() => _AddNotePopupState();
}

class _AddNotePopupState extends State<AddNotePopup> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  int indexx = 0;

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
                Firestore_Datasource().AddNote(
                  indexx,
                  _titleController.text,
                  _subtitleController.text,
                );
                Navigator.of(context).pop();
              },
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Call showDialog to display the AddNotePopup:
void showAddNoteDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return const AddNotePopup();
    },
  );
}
