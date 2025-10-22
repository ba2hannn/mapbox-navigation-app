import '../../domain/entities/year.dart';

class YearModel extends Year {
  YearModel({required super.id, required super.value});

  factory YearModel.fromJson(Map<String, dynamic> json) {
    return YearModel(
      id: json['id'] as String,
      value: json['value'] as String,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
    };
  }
}