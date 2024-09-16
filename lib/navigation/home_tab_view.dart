import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:proje1/components/hcard.dart';
import 'package:proje1/components/vcard.dart';
import 'package:proje1/data/firestore.dart';
import 'package:stacked_card_carousel/stacked_card_carousel.dart';
import '../model/courses.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  late List<NoteModel> _notesList = [];
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  void _resetCards() {
    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
            // Title for Notes
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
            // Horizontal Scrollable Section for VCards
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
            // Title for Edit Notes
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
            // Wrap StackedCardCarousel with a fixed height
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: GestureDetector(
                onTap: _resetCards,
                child: StreamBuilder<QuerySnapshot>(
                  stream: Firestore_Datasource().stream(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    _notesList = Firestore_Datasource()
                        .getNotes(snapshot)
                        .cast<NoteModel>();

                    return Container(
                      height: 300, // Set the height for the stacked cards
                      child: StackedCardCarousel(
                        pageController: _pageController,
                        items: _notesList
                            .map((note) => HCard(note: note))
                            .toList(),
                        type: StackedCardCarouselType.cardsStack,
                        initialOffset: 1,
                        spaceBetweenItems: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
