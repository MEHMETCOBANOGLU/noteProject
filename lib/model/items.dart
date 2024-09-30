class Item {
  Item({
    required this.id,
    required this.expandedValue,
    required this.headerValue,
    this.isExpanded = false,
    this.subtitle,
    this.imageUrls,
  });

  String id;
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

  // Map'ten bir Item objesi oluşturma fonksiyonu
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      expandedValue: List<String>.from(map['expandedValue']),
      imageUrls:
          map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
      headerValue: map['headerValue'],
      subtitle: map['subtitle'],
      isExpanded: map['isExpanded'] ?? false,
    );
  }
}



// class Item {
//   Item({
//     required this.id,
//     required this.expandedValue,
//     required this.headerValue,
//     this.isExpanded = false,
//     this.subtitle,
//     this.imageUrls,
//   });

//   String id;
//   List<String> expandedValue;
//   List<String>? imageUrls;
//   String headerValue;
//   String? subtitle;
//   bool isExpanded;
// }
// /////////////////