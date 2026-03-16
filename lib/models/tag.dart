import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 5)
class Tag extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String colorHex;

  Tag({
    required this.id,
    required this.name,
    this.colorHex = '007AFF',
  });

  Tag copyWith({String? id, String? name, String? colorHex}) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorHex': colorHex,
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'] as String,
        name: json['name'] as String,
        colorHex: json['colorHex'] as String? ?? '007AFF',
      );
}
