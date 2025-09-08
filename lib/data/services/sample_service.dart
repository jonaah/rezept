import 'dart:async';
import '../model/sample_dto.dart';

/// Simulated remote service / API client.
class SampleService {
  const SampleService();

  Future<SampleDto> fetchSampleDto(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return SampleDto(id: id, name: 'Sample #$id');
  }
}

