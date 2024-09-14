import 'package:flutter/material.dart';
import 'package:proje1/components/hcard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proje1/data/firestore.dart';
import 'package:proje1/model/courses.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({Key? key}) : super(key: key);

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  late List<NoteModel> _notesList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 60,
            bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildStackedCardCarousel(),
            // Diğer widget'larınız...
          ],
        ),
      ),
    );
  }

  Widget buildStackedCardCarousel() {
    return StreamBuilder<QuerySnapshot>(
      stream: Firestore_Datasource().stream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _notesList =
              Firestore_Datasource().getNotes(snapshot).cast<NoteModel>();
          return StackedCardCarousel(
            items: _notesList.map((note) => HCard(note: note)).toList(),
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
