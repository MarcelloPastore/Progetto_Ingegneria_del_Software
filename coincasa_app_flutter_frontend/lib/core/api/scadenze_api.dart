import '../models/scadenza.dart';
import 'api_client.dart';

class ScadenzeApi {
  ScadenzeApi(this._client);

  final ApiClient _client;

  Future<List<Scadenza>> list(String casaId) async {
    final data = await _client.getJson('/case/$casaId/scadenze');
    return _parseList(data);
  }

  Future<Scadenza> getById(String casaId, String idScadenza) async {
    final data = await _client.getJson('/case/$casaId/scadenze/$idScadenza');
    return Scadenza.fromJson(_asMap(data));
  }

  Future<Scadenza> create(String casaId, Map<String, dynamic> payload) async {
    final data = await _client.postJson(
      '/case/$casaId/scadenze',
      body: payload,
    );
    return Scadenza.fromJson(_asMap(data));
  }

  Future<Scadenza> update(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.putJson(
      '/case/$casaId/scadenze/$idScadenza',
      body: payload,
    );
    return Scadenza.fromJson(_asMap(data));
  }

  Future<void> delete(String casaId, String idScadenza) async {
    await _client.deleteJson('/case/$casaId/scadenze/$idScadenza');
  }

  Future<Scadenza> updateRicorrenza(
    String casaId,
    String idScadenza,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.patchJson(
      '/case/$casaId/scadenze/$idScadenza/ricorrenza',
      body: payload,
    );
    return Scadenza.fromJson(_asMap(data));
  }

  List<Scadenza> _parseList(dynamic data) {
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic>) {
      final candidate =
          data['scadenze'] ?? data['items'] ?? data['results'];
      if (candidate is List) {
        list = candidate;
      } else {
        throw const FormatException('Expected a list response.');
      }
    } else {
      throw const FormatException('Expected a list response.');
    }
    return list
        .map((e) => Scadenza.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Expected an object response.');
  }
}
