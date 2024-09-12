import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proje1/model/courses.dart';
import 'package:uuid/uuid.dart';
import '../model/notes_model.dart';

class Firestore_Datasource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> CreateUser(String email) async {
    try {
      await _firestore
          .collection('users')
          .doc("9gIrHJTwMwLTJX51oJOu")
          //.doc(_auth.currentUser!.uid)
          //.set({"id": _auth.currentUser!.uid, "email": email});
          .set({"id": "9gIrHJTwMwLTJX51oJOu", "email": "mehmet@gmail.com"});
      return true;
    } catch (e) {
      print(e);
      return true;
    }
  }

  Future<bool> AddNote(
    int indexx,
    String title,
    String subtitle,
  ) async {
    try {
      var uuid = Uuid().v4();
      await _firestore
          .collection('users')
          .doc("9gIrHJTwMwLTJX51oJOu")
          .collection('notes')
          .doc(uuid)
          .set({
        'id': uuid,
        'title': title,
        'subtitle': subtitle,
      });
      return true;
    } catch (e) {
      print(e);
      return true;
    }
  }

  List getNotes(AsyncSnapshot snapshot) {
    try {
      final notesList = snapshot.data!.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return NoteModel(
          data['id'],
          data['title'],
          data['subtitle'],
        );
      }).toList();
      return notesList;
    } catch (e) {
      print(e);
      return [];
    }
  }

  // Stream<QuerySnapshot> stream(bool isDone) {
  Stream<QuerySnapshot> stream() {
    return _firestore
        .collection('users')
        .doc("9gIrHJTwMwLTJX51oJOu")
        .collection('notes')
        // .where('isDon', isEqualTo: isDone)
        .snapshots();
  }

  Future<bool> Update_Note(String uuid, String title, String subtitle) async {
    try {
      await _firestore
          .collection('users')
          .doc("9gIrHJTwMwLTJX51oJOu")
          .collection('notes')
          .doc(uuid)
          .update({
        'title': title,
        'subtitle': subtitle,
      });
      return true;
    } catch (e) {
      print(e);
      return true;
    }
  }

  Future<bool> delet_note(String uuid) async {
    try {
      await _firestore
          .collection('users')
          .doc("9gIrHJTwMwLTJX51oJOu")
          .collection('notes')
          .doc(uuid)
          .delete();
      return true;
    } catch (e) {
      print(e);
      return true;
    }
  }

  Future<bool> updateNoteOrder(String noteId, int newIndex) async {
    try {
      await _firestore
          .collection('users')
          .doc("9gIrHJTwMwLTJX51oJOu")
          .collection('notes')
          .doc(noteId)
          .update({'order': newIndex});
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
}
