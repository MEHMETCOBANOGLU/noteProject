import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
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

  @override
  void initState() {
    super.initState();
    // iOS için status bar'ı şeffaf yapmak için bu kod eklenebilir
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Status bar rengini şeffaf yapar
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Visibility(
        // FloatingActionButton butonu sadece show değişkeni true olduğunda görünür
        visible: show,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AddNotePopup()));
            // showAddNoteDialog(
            //     context); // Burada showAddNoteDialog fonksiyonu var, bunu proje içinde tanımladığını varsayıyorum.
          },
          backgroundColor: const Color(0xFFBBDEFB).withOpacity(0.7),
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFE1BEE7).withOpacity(0.5), // Pastel Purple
              const Color(0xFFBBDEFB).withOpacity(0.5), // Light Blue
              const Color(0xFFB2DFDB).withOpacity(0.5), // Pastel Turkuaz
              const Color(0xFFE1BEE7).withOpacity(0.5), // Açık Lavanta
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
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
                    show =
                        true; // FloatingActionButton butonu görünür hale gelir
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
      ),
    );
  }
}
