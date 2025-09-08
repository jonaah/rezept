/// Data Transfer Object (API layer model)
class SampleDto {
  final int id;
  final String name;
  const SampleDto({required this.id, required this.name});

  factory SampleDto.fromJson(Map<String, dynamic> json) =>
      SampleDto(id: json['id'] as int, name: json['name'] as String);

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

