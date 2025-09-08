import '../../domain/models/sample_model.dart';
import '../services/sample_service.dart';

/// Repository pattern implementation bridging domain and data sources.
class SampleRepository {
  final SampleService _service;
  const SampleRepository(this._service);

  Future<SampleModel> fetchSample(int id) async {
    final dto = await _service.fetchSampleDto(id);
    return SampleModel(id: dto.id, name: dto.name);
  }
}

