class BodyType {
  final String id;
  final String value;

  BodyType({required this.id, required this.value});

  factory BodyType.fromJson(Map<String, dynamic> json) {
    return BodyType(
      id: json['id'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}