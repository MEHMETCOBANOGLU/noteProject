//itemler için bir model oluşturuldu #modell,itemsmodell
class Item {
  Item({
    required this.id,
    required this.expandedValue,
    required this.headerValue,
    required this.tabId,
    this.isExpanded = false,
    this.subtitle,
    this.imageUrls,
  });

  String id;
  String tabId;
  List<String> expandedValue;
  List<String>? imageUrls;
  String headerValue;
  String? subtitle;
  bool isExpanded;

  // Map'e çevirme fonksiyonu
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expandedValue': expandedValue,
      'imageUrls': imageUrls ?? [], // Null durumu için boş bir liste
      'headerValue': headerValue,
      'subtitle': subtitle ?? '', // Null durumu için boş string
      'isExpanded': isExpanded,
    };
  }

  // Map'ten bir Item objesi oluşturma fonksiyonu json to ıtem
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '', // Eğer id null ise varsayılan boş string kullan
      tabId: map['tabId'] ?? '', // Eğer tabId null ise boş string kullan
      expandedValue:
          List<String>.from(map['expandedValue'] ?? []), // Boş liste kontrolü
      imageUrls:
          map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
      headerValue: map['headerValue'] ??
          '', // Eğer headerValue null ise boş string kullan
      subtitle:
          map['subtitle'], // Bu alan null olabilir, o yüzden kontrol gerekmez
      isExpanded: map['isExpanded'] ?? false, // Null durumunda false değeri ata
    );
  }
}
