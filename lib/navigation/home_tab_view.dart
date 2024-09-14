import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proje1/components/hcard.dart';
import 'package:proje1/components/vcard.dart';
import 'package:proje1/data/firestore.dart';
import 'package:proje1/model/courses.dart';

import '../const/theme.dart';

class HomeTabView extends StatefulWidget {
  // final NoteModel note;
  const HomeTabView({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  // final List<CourseModel> _courses = CourseModel.courses;
  // final List<CourseModel> _courseSections = CourseModel.courseSections;
  late List<NoteModel> _notesList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body:
          //  Container(
          //   clipBehavior: Clip.hardEdge,
          //   decoration: BoxDecoration(
          //     color: RiveAppTheme.background,
          //     borderRadius: BorderRadius.circular(30),
          //   ),
          //   child:
          SingleChildScrollView(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 60,
            bottom: MediaQuery.of(context).padding.bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Notes",
                style: TextStyle(
                  fontSize: 30,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Color.fromARGB(255, 2, 40, 106).withOpacity(0.5),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              scrollDirection: Axis.horizontal,
              child: StreamBuilder<QuerySnapshot>(
                stream: Firestore_Datasource().stream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return CircularProgressIndicator();
                  }

                  _notesList = Firestore_Datasource()
                      .getNotes(snapshot)
                      .cast<NoteModel>();

                  return Row(
                    children: _notesList
                        .map(
                          (note) => Padding(
                            key: ValueKey(note.id),
                            padding: const EdgeInsets.all(10),
                            child: VCard(note: note),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Text(
                "Edit Notes",
                style: TextStyle(
                  fontSize: 30,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Color.fromARGB(255, 2, 40, 106).withOpacity(0.5),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Wrap(
                children: List.generate(
                  _notesList.length,
                  (index) => Container(
                    key: ValueKey(_notesList[index].id),
                    width: MediaQuery.of(context).size.width > 992
                        ? ((MediaQuery.of(context).size.width - 20) / 2)
                        : MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                    child: HCard(note: _notesList[index]),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
