import 'package:flutter/material.dart';
import 'package:proje1/data/firestore.dart';
import '../model/courses.dart';

class EditNotes extends StatefulWidget {
  final NoteModel note;
  const EditNotes({Key? key, required this.note}) : super(key: key);

  @override
  State<EditNotes> createState() => _EditNotesState();
}

class _EditNotesState extends State<EditNotes> {
  late TextEditingController _titleController = TextEditingController();
  late TextEditingController _subtitleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _subtitleController = TextEditingController(text: widget.note.subtitle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE1BEE7).withOpacity(0.7), // Pastel Purple
              const Color(0xFFBBDEFB).withOpacity(0.7), // Light Blue
              const Color(0xFFB2DFDB).withOpacity(0.7), // Pastel Turkuaz
              const Color(0xFFE1BEE7).withOpacity(0.7), // Açık Lavanta
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              headerAdd(),
              bodyAdd(),
            ],
          ),
        ),
      ),
    );
  }

  Widget headerAdd() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Color.fromARGB(255, 2, 40, 106).withOpacity(0.5),
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 30,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 3
                    ..color = Color.fromARGB(255, 2, 40, 106).withOpacity(0.5),
                ),
              )
            ],
          ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Color.fromARGB(255, 2, 40, 106).withOpacity(0.3),
                ),
                child: const Icon(
                  Icons.color_lens,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Color.fromARGB(255, 2, 40, 106).withOpacity(0.3),
                ),
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget bodyAdd() {
    return Expanded(
        child: Container(
      height: double
          .infinity, //container botttom side size should be the end of screen
      padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white, // Arka plan rengi
                hintText: "Title",
                hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(
                    width: 1.0, // Kalınlık her zaman aynı
                    color: Color(0xFFFFA500), // Enabled border orange color
                  ),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    width: 2.0, // Daha kalın enabled border
                    color: Color.fromARGB(255, 2, 40, 106)
                        .withOpacity(0.5), // Light Blue
                  ),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    width: 4.0, // Daha da kalın focused border
                    color: Color(0xFFE1BEE7), // Pastel Purple
                  ),
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
              cursorColor: const Color.fromARGB(255, 178, 223, 186)
                  .withOpacity(0.2), // imlec rengi
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20), // Kesik köşeler için yarıçap
              child: TextFormField(
                controller: _subtitleController,
                maxLines: 20,
                decoration: InputDecoration(
                  // filled: true,
                  // fillColor: Colors.white, // Arka plan rengi
                  hintText: "Subtitle",
                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1.0, // Kalınlık her zaman aynı
                      color: Color(0xFFFFA500),
                    ), // Çerçeveyi gizle
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      width: 2.0,
                      color: Color.fromARGB(255, 2, 40, 106)
                          .withOpacity(0.5), // Light Blue
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      width: 4.0,
                      color: const Color(0xFFE1BEE7)
                          .withOpacity(0.5), // Pastel Purple
                    ),
                  ),
                ),
                cursorColor:
                    const Color.fromARGB(255, 178, 223, 186).withOpacity(0.2),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subtitle';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Firestore_Datasource().Update_Note(widget.note.id,
                    _titleController.text, _subtitleController.text);

                Navigator.of(context).pop();
              },
              child: Text('Edit Note',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 2, 40, 106).withOpacity(0.7),
                  )),
            ),
          ],
        ),
      ),
    ));
  }
}
