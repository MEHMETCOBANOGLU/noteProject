import 'package:flutter/material.dart';

// tablo ekleme ve düzenleme sayfasındaki 3 nokta ikonundaki seçeneker menusu
void showListBoxDialog(
    BuildContext context,
    int index,
    List<TextEditingController> itemControllers,
    List<String> options,
    TextEditingController newOptionController,
    bool isAddingNewOption,
    Function setState,
    Function(String) addNewOption,
    Function(int) removeOption) {
  final ScrollController _scrollController = ScrollController();

  showDialog(
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Liste Kutusu'),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: isAddingNewOption
                          ? const Icon(Icons.format_list_bulleted)
                          : const Icon(Icons.format_list_bulleted_add),
                      onPressed: () {
                        setState(() {
                          isAddingNewOption = !isAddingNewOption;
                        });
                      },
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: Scrollbar(
                        trackVisibility: true,
                        thumbVisibility: true,
                        controller: _scrollController,
                        child: ListView.builder(
                          controller: _scrollController,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int idx) {
                            return Dismissible(
                              key: Key(options[idx]),
                              background: Container(
                                color: Colors.red[50],
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child:
                                    const Icon(Icons.delete, color: Colors.red),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                setState(() {
                                  removeOption(
                                      idx); // İlgili elemanı listeden sil
                                });
                              },
                              child: ListTile(
                                title: Text(options[idx]),
                                onTap: () {
                                  itemControllers[index].text = options[idx];
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (isAddingNewOption)
                      Column(
                        children: [
                          TextField(
                            controller: newOptionController,
                            decoration: const InputDecoration(
                              labelText: 'Yeni Seçenek Ekle',
                            ),
                            onSubmitted: (value) {
                              setState(() {
                                addNewOption(value); // Seçenek ekleme işlemi
                              });
                            },
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                addNewOption(newOptionController.text);
                                isAddingNewOption = !isAddingNewOption;

                                // Yeni eleman eklendikten sonra listenin en altına kaydır
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _scrollController.animateTo(
                                    _scrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                });
                              });
                            },
                            child: const Text('Ekle'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
