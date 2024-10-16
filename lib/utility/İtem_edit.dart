import 'dart:io';
import 'package:Tablify/utility/list_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Tablify/data/database.dart';
import 'package:uuid/uuid.dart';
import '../model/items.dart';

// Resimleri kalıcı olarak kaydetme fonksiyonu
Future<String> saveImagePermanently(File image) async {
  final directory = await getApplicationDocumentsDirectory();
  final fileName = image.path.split('/').last;
  final newPath = '${directory.path}/$fileName';

  final savedImage = await image.copy(newPath);
  return savedImage.path;
}

//itemler için resim seçme #resimseçmee,itemresimm
Future<String?> pickImage(
  int index,
  ImagePicker picker,
  List<File?>? selectedImages, // Optional
  List<String?> existingImagePaths,
) async {
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    File file = File(image.path);
    String savedImagePath = await saveImagePermanently(file);
    return savedImagePath; // Seçilen resmin yolunu döndür
  } else {
    // Resim seçimi iptal edilirse null döndür
    return null;
  }
}

//listeden item silme #listedenitemsilme
Future<void> removeItemField(
  int index,
  List<TextEditingController> itemControllers,
  List<String?> existingImagePaths,
  List<File?> selectedImages,
  List<GlobalKey> menuKeys,
  List<FocusNode> focusNodes,
  SQLiteDatasource sqliteDatasource,
  Item item,
  BuildContext context,
  Function setState,
  Function onTableEdited,
  TextEditingController titleController, // Ensure titleController is passed
  TextEditingController
      subtitleController, // Ensure subtitleController is passed
) async {
  // Ask for user confirmation
  bool? confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('İtemi silmek istediğinize emin misiniz?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: <Widget>[
          TextButton(
            child: const Text('İptal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await sqliteDatasource.deleteItem(item.id, index);

    setState(() {
      // Remove the respective item at the given index
      if (index >= 0 && index < itemControllers.length) {
        itemControllers.removeAt(index);
      }
      if (index >= 0 && index < existingImagePaths.length) {
        existingImagePaths.removeAt(index);
      }
      if (index >= 0 && index < selectedImages.length) {
        selectedImages.removeAt(index);
      }
      if (index >= 0 && index < menuKeys.length) {
        menuKeys.removeAt(index);
      }
      if (index >= 0 && index < focusNodes.length) {
        focusNodes.removeAt(index);
      }
    });
    List<String> items =
        itemControllers.map((controller) => controller.text).toList();
    List<String> imagePaths = [];

    for (int i = 0; i < selectedImages.length; i++) {
      if (selectedImages[i] != null) {
        imagePaths.add(selectedImages[i]!.path);
        existingImagePaths[i] = selectedImages[i]!.path;
      } else {
        imagePaths.add(existingImagePaths[i]!);
      }
    }

    // Update the item in the database with the remaining data
    bool success = await sqliteDatasource.addOrUpdateNote(
      Item(
        id: item.id,
        headerValue: titleController.text,
        subtitle: subtitleController.text,
        expandedValue: items,
        imageUrls: imagePaths,
        tabId: item.tabId,
      ),
    );

    if (success) {
      // Notify the user of successful deletion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İtem başarıyla silindi!'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Trigger the table update and close the dialog
    onTableEdited();
    Navigator.of(context).pop(); // Close the dialog
  }
}

// 3 nokta ikonuna tıklandığında açılan menu
void showCustomMenu(
  BuildContext context,
  int index,
  GlobalKey key,
  List<TextEditingController> itemControllers,
  List<String?> imagePaths,
  List<File?>? selectedImages,
  List<String?> existingImagePaths,
  ImagePicker picker,
  List<String> options,
  TextEditingController newOptionController,
  bool isAddingNewOption,
  Function setState,
  void Function(String)? addNewOption, // Optional
  void Function(int)? removeOption, // Optional
  void Function(String)? onPaste, // Yeni parametre
  void Function(String)? onImagePicked, // Yeni parametre
) {
  final RenderBox renderBox =
      key.currentContext!.findRenderObject() as RenderBox;
  final Offset offset = renderBox.localToGlobal(Offset.zero);

  showMenu(
    elevation: 4.0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
    context: context,
    position: RelativeRect.fromLTRB(
      offset.dx + renderBox.size.width,
      offset.dy + renderBox.size.height,
      offset.dx,
      offset.dy,
    ),
    items: [
      PopupMenuItem(
        child: ListTile(
          leading: const Icon(Icons.photo),
          title: const Text('Resim Ekle'),
          onTap: () {
            Navigator.pop(context);
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              String? selectedImagePath = await pickImage(
                  index, picker, selectedImages, existingImagePaths);
              if (selectedImagePath != null) {
                if (onImagePicked != null) {
                  onImagePicked(
                      selectedImagePath); // Callback ile resmi güncelle
                }
                setState(() {
                  existingImagePaths[index] = selectedImagePath;
                  selectedImages?[index] = File(selectedImagePath);
                });
              }
            });
          },
        ),
      ),
      PopupMenuItem(
        child: ListTile(
          leading: const Icon(Icons.paste),
          title: const Text('Yapıştır'),
          onTap: () async {
            Navigator.pop(context); // Menü kapatılır
            ClipboardData? data = await Clipboard.getData('text/plain');
            if (data != null && data.text != null && data.text!.isNotEmpty) {
              if (onPaste != null) {
                onPaste(data.text!); // Callback ile metni yapıştır
              } else {
                setState(() {
                  itemControllers[index].text = data.text!;
                });
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Panoda metin bulunamadı!'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ),
      if (addNewOption != null && removeOption != null)
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Liste Kutusu'),
            onTap: () {
              Navigator.pop(context);
              showListBoxDialog(
                context,
                index,
                itemControllers,
                options,
                newOptionController,
                isAddingNewOption,
                setState,
                addNewOption,
                removeOption,
              );
            },
          ),
        ),
    ],
  );
}

// Long press edit dialog for items
void showCustomEditMenu(
  BuildContext context,
  int index,
  GlobalKey key,
  String text,
  ImagePicker picker,
  List<File?>? selectedImages,
  List<String?> existingImagePaths,
  String? imageUrl,
  List<TextEditingController> itemControllers,
  Function setState,
  List<GlobalKey> menuKeys,
  List<FocusNode> focusNodes,
  SQLiteDatasource sqliteDatasource,
  Item item,
  Function onTableEdited,
  TextEditingController titleController, // Ensure titleController is passed
  TextEditingController subtitleController,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      final TextEditingController controller =
          TextEditingController(text: text);
      final FocusNode focusNode = FocusNode();

      return AlertDialog(
        title: const Center(child: Text('Item Güncelle')),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.multiline,
              minLines: 1,
              maxLines: null,
              decoration: InputDecoration(
                hintText: 'Item ${index + 1}',
                prefixIcon: imageUrl != null && imageUrl!.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                        child: Image.file(
                          File(imageUrl!),
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                      )
                    : IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          // Resim seçildikten sonra hem dialog içi hem dışı state güncellenmeli
                          String? selectedImagePath = await pickImage(index,
                              picker, selectedImages, existingImagePaths);
                          if (selectedImagePath != null) {
                            setDialogState(() {
                              imageUrl = selectedImagePath;
                            });
                            // Dialog dışındaki state'i de güncelle
                            setState(() {
                              existingImagePaths[index] = selectedImagePath;
                              selectedImages?[index] = File(selectedImagePath);
                            });
                          }
                        },
                        icon: Icon(Icons.image,
                            size: 50, color: Colors.grey.shade400),
                      ),
                suffixIcon: SizedBox(
                  width: 70,
                  height: 40,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: IconButton(
                          key: key,
                          icon: const Icon(Icons.more_vert_sharp),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            showCustomMenu(
                              context,
                              index,
                              key,
                              itemControllers,
                              existingImagePaths,
                              selectedImages,
                              existingImagePaths,
                              picker,
                              [], // options listesi, isterseniz buraya ekleyebilirsiniz
                              TextEditingController(),
                              false,
                              setState,
                              null,
                              null,
                              (String pastedText) {
                                // Dialog içindeki controller'ı güncelle
                                controller.text = pastedText;
                              },
                              (String imagePath) {
                                setDialogState(() {
                                  imageUrl = imagePath;
                                });

                                // Dialog dışındaki state'i güncelle
                                setState(() {
                                  existingImagePaths[index] = imagePath;
                                  selectedImages?[index] = File(imagePath);
                                });
                              },
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 30,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              itemControllers[index].text = controller.text;
                              existingImagePaths[index] = imageUrl ??
                                  ''; // Sadece seçilen index için resmi güncelle
                            });

                            // // Veritabanına kaydetme
                            // item.expandedValue[index] = controller.text;
                            // item.imageUrls![index] = existingImagePaths[
                            //         index] ??
                            //     ''; // Sadece seçilen index'in resmini güncelle

                            removeItemField(
                                index,
                                itemControllers,
                                existingImagePaths,
                                selectedImages ?? [],
                                menuKeys,
                                focusNodes,
                                sqliteDatasource,
                                item,
                                context,
                                setState,
                                onTableEdited,
                                titleController,
                                subtitleController);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                child: const Text(
                  "İptal",
                  style: TextStyle(color: Colors.black),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text(
                  "Kaydet",
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  // Veriyi UI'ya kaydetme
                  setState(() {
                    itemControllers[index].text = controller.text;
                    existingImagePaths[index] = imageUrl ??
                        ''; // Sadece seçilen index için resmi güncelle
                  });

                  // Veritabanına kaydetme
                  item.expandedValue[index] = controller.text;
                  item.imageUrls![index] = existingImagePaths[index] ??
                      ''; // Sadece seçilen index'in resmini güncelle

                  bool success = await sqliteDatasource.addOrUpdateNote(item);

                  if (success) {
                    print('Updating item: ${itemControllers[index].text}');
                    print(
                        'Updated image path at index $index: ${existingImagePaths[index]}');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İtem başarıyla güncellendi!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('İtem güncellenemedi!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                  Navigator.of(context).pop(); // Dialogu kapat
                },
              ),
            ],
          ),
        ],
      );
    },
  );
}
