import 'dart:math';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proje1/model/courses.dart';

class VCard extends StatefulWidget {
  const VCard({
    Key? key,
    required this.note,
  }) : super(key: key);

  final NoteModel note;

  @override
  State<VCard> createState() => _VCardState();
}

class _VCardState extends State<VCard> {
  final avatars = [4, 5, 6];

  @override
  void initState() {
    avatars.shuffle();
    super.initState();
  }

  void copyText(String content, String message) {
    FlutterClipboard.copy(content).then((value) {
      Get.snackbar(
        "Copied",
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFBBDEFB).withOpacity(0.7),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        // Kartın geri kalan kısımlarına uzun basıldığında
        copyText("${widget.note.title}\n${widget.note.subtitle}",
            "Both Title and Subtitle copied!");
      },
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromARGB(255, 2, 40, 106).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: const Color(0xFFB2DFDB).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 1),
            )
          ],
          borderRadius: BorderRadius.circular(30),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: () {
                    // Title kısmına uzun basıldığında
                    copyText(widget.note.title, "Title copied!");
                  },
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Text(
                      widget.note.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(
                          fontSize: 24,
                          fontFamily: "Poppins",
                          color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onLongPress: () {
                    // Subtitle kısmına uzun basıldığında
                    copyText(widget.note.subtitle, "Subtitle copied!");
                  },
                  child: Text(
                    widget.note.subtitle,
                    overflow: TextOverflow
                        .ellipsis, //metin sığmadığında metnin sonuna üç nokta (...)
                    maxLines: 5,
                    softWrap: false,
                    style: TextStyle(
                        color: Colors.black.withOpacity(1), fontSize: 15),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
