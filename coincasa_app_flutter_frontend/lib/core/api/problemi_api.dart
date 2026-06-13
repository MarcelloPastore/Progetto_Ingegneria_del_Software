import '../models/problema.dart';
import 'api_client.dart';

class ProblemiApi {
  ProblemiApi(this._client);

  final ApiClient _client;

  Future<List<Problema>> list(String casaId) async {
    final data = await _client.getJson('/case/$casaId/problemi');
    return _parseList(data);
  }

  Future<List<Problema>> listNonRisolti(String casaId) async {
    final data = await _client.getJson('/case/$casaId/problemi/non-risolti');
    return _parseList(data);
  }

  Future<Problema> getById(String casaId, String problemaId) async {
    final data = await _client.getJson('/case/$casaId/problemi/$problemaId');
    return Problema.fromJson(_asMap(data));
  }

  Future<Problema> create(String casaId, Map<String, dynamic> payload) async {
    final data = await _client.postJson(
      '/case/$casaId/problemi',
      body: payload,
    );
    return Problema.fromJson(_asMap(data));
  }

  Future<Problema> update(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.putJson(
      '/case/$casaId/problemi/$problemaId',
      body: payload,
    );
    return Problema.fromJson(_asMap(data));
  }

  Future<void> delete(String casaId, String problemaId) async {
    await _client.deleteJson('/case/$casaId/problemi/$problemaId');
  }

  Future<Problema> autoAssegna(String casaId, String problemaId) async {
    final data = await _client.putJson(
      '/case/$casaId/problemi/$problemaId/autoassegna',
    );
    return Problema.fromJson(_asMap(data));
  }

  Future<Problema> rinuncia(String casaId, String problemaId) async {
    final data = await _client.putJson(
      '/case/$casaId/problemi/$problemaId/rinuncia',
    );
    return Problema.fromJson(_asMap(data));
  }

  Future<Problema> assegna(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.putJson(
      '/case/$casaId/problemi/$problemaId/assegna',
      body: payload,
    );
    return Problema.fromJson(_asMap(data));
  }

  Future<Problema> aggiornaStato(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.patchJson(
      '/case/$casaId/problemi/$problemaId/stato',
      body: payload,
    );
    return Problema.fromJson(_asMap(data));
  }

  Future<Problema> aggiornaPriorita(
    String casaId,
    String problemaId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.patchJson(
      '/case/$casaId/problemi/$problemaId/priorita',
      body: payload,
    );
    return Problema.fromJson(_asMap(data));
  }

  List<Problema> _parseList(dynamic data) {
    final list = _asList(data);
    return list.map(Problema.fromJson).toList();
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic>) {
      final candidate = data['items'] ?? data['results'] ?? data['problemi'];
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
