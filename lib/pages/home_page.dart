import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:proje1/const/colors.dart';
import 'package:proje1/model/courses.dart';
import 'package:proje1/navigation/home_tab_view.dart';
import 'package:proje1/pages/add_note_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool show =
      true; // FloatingActionButton'ın görünür olup olmadığını kontrol eder
  List<NoteModel> notesList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColors,
      floatingActionButton: Visibility(
        // FloatingActionButton butonu sadece show değişkeni true olduğunda görünür
        visible: show,
        child: FloatingActionButton(
          onPressed: () {
            showAddNoteDialog(context);
          },
          backgroundColor: Color((Random().nextDouble() * 0xFFFFFF).toInt())
              .withOpacity(0.8),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      body: SafeArea(
        child: NotificationListener<UserScrollNotification>(
          // Kullanıcı kaydırma hareketleri dinlenir
          onNotification: (notification) {
            if (notification.metrics.maxScrollExtent == 0) {
              // Eğer kaydırılacak içerik yoksa show true olarak kalır
              setState(() {
                show = true;
              });
            } else {
              // Kaydırma varsa normal şekilde yönetir
              if (notification.direction == ScrollDirection.forward) {
                setState(() {
                  show = true; // FloatingActionButton butonu görünür hale gelir
                });
              } else if (notification.direction == ScrollDirection.reverse) {
                setState(() {
                  show = false; // FloatingActionButton butonu gizlenir
                });
              }
            }
            return true;
          },
          child: const HomeTabView(),
        ),
      ),
    );
  }
}
