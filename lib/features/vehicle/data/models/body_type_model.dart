import '../../domain/entities/body_type.dart';

class BodyTypeModel extends BodyType {
  BodyTypeModel({required super.id, required super.value});

  factory BodyTypeModel.fromJson(Map<String, dynamic> json) {
    return BodyTypeModel(
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