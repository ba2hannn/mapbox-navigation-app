class Year {
  final String id;
  final String value;

  Year({required this.id, required this.value});

  factory Year.fromJson(Map<String, dynamic> json) {
    return Year(
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