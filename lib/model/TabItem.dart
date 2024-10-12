class TabItem {
  String id;
  String name;

  TabItem({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory TabItem.fromMap(Map<String, dynamic> map) {
    return TabItem(
      id: map['id'],
      name: map['name'],
    );
  }
}
