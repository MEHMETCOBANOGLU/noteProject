import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:Tablify/data/aym_data.dart';

//AYM bilgilendirme sayfasi #bilgii,infoo
class AymGuidePage extends StatefulWidget {
  const AymGuidePage({super.key});

  @override
  State<AymGuidePage> createState() => _AymGuidePageState();
}

class _AymGuidePageState extends State<AymGuidePage> {
  final PageController _pageController = PageController(initialPage: 0);
  int currentPage = 0;
  // Bir sonraki sayfaya ilerleme fonksiyonu #ilerlee
  gotoNextPage() {
    if (currentPage + 1 < aymData.length) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding:
              const EdgeInsets.only(left: 25, right: 25, top: 25, bottom: 8),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  itemCount: aymData.length,
                  controller: _pageController,
                  onPageChanged: (pageNumber) {
                    setState(() {
                      currentPage = pageNumber;
                    });
                    log(pageNumber.toString());
                  },
                  itemBuilder: (context, index) {
                    return SingleChildScrollView(
                      // Kaydırılabilir hale getiriyoruz
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            aymData[index]['title']!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.green[300],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            aymData[index]['description']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (aymData[index]['subtitle'] != null) ...[
                            Center(
                              child: Text(
                                aymData[index]['subtitle']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Colors.green[300],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (aymData[index]['subtitle2'] != null) ...[
                            Text(
                              aymData[index]['subtitle2']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.green[300],
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          if (aymData[index]['description2'] != null) ...[
                            Text(
                              aymData[index]['description2']!,
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 15),
                          ],
                          if (aymData[index]['subtitle3'] != null) ...[
                            Text(
                              aymData[index]['subtitle3']!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.green[300],
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          if (aymData[index]['description3'] != null) ...[
                            Text(
                              aymData[index]['description3']!,
                              style: const TextStyle(
                                fontSize: 18,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (aymData[index]['sample'] != null) ...[
                            Center(
                              child: Text(
                                textAlign: TextAlign.center,
                                aymData[index]['sample']!,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.maxFinite,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_pageController.page == aymData.length - 1) {
                          Navigator.pop(context);
                        } else {
                          _pageController.jumpToPage(aymData.length - 1);
                        }
                      },
                      onDoubleTap: () {
                        Navigator.pop(context);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Atla",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 18),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(aymData.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Container(
                            height: 10,
                            width: currentPage == index ? 25 : 10,
                            decoration: BoxDecoration(
                              color: currentPage == index
                                  ? Colors.green
                                  : Colors.green[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }),
                    ),
                    InkWell(
                      onTap: () {
                        gotoNextPage();
                      },
                      child: Container(
                        height: height * 0.05,
                        width: width * 0.15,
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Text(
                            "İleri",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
