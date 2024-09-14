import 'dart:math';
import 'package:flutter/material.dart';
import 'package:proje1/model/courses.dart';

class VCard extends StatefulWidget {
  const VCard({
    Key? key,
    required this.note,
  }) : super(key: key);

  // final CourseModel course;
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260, maxHeight: 260),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        //create gradient for random color each time
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
              Container(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  widget.note.title,
                  style: const TextStyle(
                      fontSize: 24, fontFamily: "Poppins", color: Colors.black),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.note.subtitle,
                overflow: TextOverflow.ellipsis,
                maxLines: 5,
                softWrap: false,
                style:
                    TextStyle(color: Colors.black.withOpacity(1), fontSize: 15),
              ),

              const SizedBox(height: 8),
              // Text(
              //   widget.course.caption.toUpperCase(),
              //   style: const TextStyle(
              //       fontSize: 13,
              //       fontFamily: "Inter",
              //       fontWeight: FontWeight.w600,
              //       color: Colors.white),
              // ),
              const Spacer(),
              // Wrap(
              //   spacing: 8,
              //   children: List.generate(
              //     avatars.length,
              //     (index) => Transform.translate(
              //       offset: Offset(index * -20, 0),
              //       child: ClipRRect(
              //         key: Key(index.toString()),
              //         borderRadius: BorderRadius.circular(22),
              //         child: Image.asset(
              //             "assets/samples/ui/rive_app/images/avatars/avatar_${avatars[index]}.jpg",
              //             width: 44,
              //             height: 44),
              //       ),
              //     ),
              //   ),
              // )
            ],
          ),
          // Positioned(
          //     right: -10, top: -10, child: Image.asset(widget.course.image))
        ],
      ),
    );
  }
}
