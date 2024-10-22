//sekmeler için bir model oluşturuldu #modell,tabmodell
class TabItem {
  String id;
  String name;
  int order;

  TabItem({required this.id, required this.name, required this.order});

  @override
  String toString() {
    return 'TabItem{id: $id, name: $name, order: $order}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'order': order,
    };
  }

  factory TabItem.fromMap(Map<String, dynamic> map) {
    return TabItem(
      id: map['id'],
      name: map['name'],
      order: (map['order'] ?? 0) as int, // Null ise 0 değeri atanır
    );
  }
}
