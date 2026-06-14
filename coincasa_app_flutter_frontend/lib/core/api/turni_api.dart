import '../models/turno.dart';
import '../models/salute_casa_item.dart';
import 'api_client.dart';

class TurniApi {
  TurniApi(this._client);

  final ApiClient _client;

  Future<List<Turno>> list(String casaId) async {
    final data = await _client.getJson('/case/$casaId/turni');
    return _parseList(data);
  }

  Future<List<Turno>> listOggi(String casaId) async {
    final data = await _client.getJson('/case/$casaId/turni/oggi');
    return _parseList(data);
  }

  Future<List<SaluteCasaItem>> saluteCase(String casaId) async {
    final data = await _client.getJson('/case/$casaId/turni/salute-casa');
    final list = _asList(data);
    return list.map(SaluteCasaItem.fromJson).toList();
  }

  Future<Turno> create(String casaId, Map<String, dynamic> payload) async {
    final data = await _client.postJson('/case/$casaId/turni', body: payload);
    return Turno.fromJson(_asMap(data));
  }

  Future<Turno> getById(String casaId, String turnoId) async {
    final data = await _client.getJson('/case/$casaId/turni/$turnoId');
    return Turno.fromJson(_asMap(data));
  }

  Future<Turno> update(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.putJson(
      '/case/$casaId/turni/$turnoId',
      body: payload,
    );
    return Turno.fromJson(_asMap(data));
  }

  Future<void> delete(String casaId, String turnoId) async {
    await _client.deleteJson('/case/$casaId/turni/$turnoId');
  }

  Future<void> autoAssegna(String casaId, String turnoId) async {
    await _client.putJson('/case/$casaId/turni/$turnoId/autoassegna');
  }

  Future<void> assegna(
    String casaId,
    String turnoId,
    Map<String, dynamic> payload,
  ) async {
    await _client.putJson(
      '/case/$casaId/turni/$turnoId/assegna',
      body: payload,
    );
  }

  Future<void> toggleRotazione(String casaId, String turnoId) async {
    await _client.patchJson('/case/$casaId/turni/$turnoId/rotazione');
  }

  Future<void> completa(String casaId, String turnoId) async {
    await _client.postJson('/case/$casaId/turni/$turnoId/completa');
  }

  List<Turno> _parseList(dynamic data) {
    final list = _asList(data);
    return list.map(Turno.fromJson).toList();
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic>) {
      final candidate = data['items'] ?? data['results'] ?? data['turni'];
      if (candidate is List) {
        return candidate.cast<Map<String, dynamic>>();
      }
    }
    throw const FormatException('Expected a list response.');
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw const FormatException('Expected an object response.');
  }
}
