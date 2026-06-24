import '../../data/models/quota.dart';
import '../../data/models/spesa.dart';
import 'api_client.dart';

class SpeseApi {
  SpeseApi(this._client);

  final ApiClient _client;

  Future<List<Spesa>> list(
    String casaId, {
    Map<String, String>? queryParameters,
  }) async {
    final data = await _client.getJson(
      '/case/$casaId/spese',
      queryParameters: queryParameters,
    );
    return _parseList(data, Spesa.fromJson, key: 'spese');
  }

  Future<Spesa> getById(String casaId, String spesaId) async {
    final data = await _client.getJson('/case/$casaId/spese/$spesaId');
    return Spesa.fromJson(_asMap(data));
  }

  Future<Spesa> create(String casaId, Map<String, dynamic> payload) async {
    final data = await _client.postJson('/case/$casaId/spese', body: payload);
    return Spesa.fromJson(_asMap(data));
  }

  Future<Spesa> update(
    String casaId,
    String spesaId,
    Map<String, dynamic> payload,
  ) async {
    final data = await _client.putJson(
      '/case/$casaId/spese/$spesaId',
      body: payload,
    );
    return Spesa.fromJson(_asMap(data));
  }

  Future<void> delete(String casaId, String spesaId) async {
    await _client.deleteJson('/case/$casaId/spese/$spesaId');
  }

  Future<List<Quota>> getQuote(String casaId, String spesaId) async {
    final data = await _client.getJson('/case/$casaId/spese/$spesaId/quote');
    return _parseList(data, Quota.fromJson, key: 'quote');
  }

  Future<void> pagaQuota(String casaId, String spesaId, String quotaId) async {
    await _client.postJson('/case/$casaId/spese/$spesaId/quote/$quotaId/paga');
  }

  Future<void> pareggia(String casaId, List<String> idUtentiCreditori) async {
    await _client.postJson(
      '/case/$casaId/spese/pareggia',
      body: {'idUtentiCreditori': idUtentiCreditori},
    );
  }

  Future<double> getSaldo(String casaId) async {
    final data = await _client.getJson('/case/$casaId/saldo');
    return _parseAmount(data, key: 'saldo');
  }

  Future<double> getCreditoTot(String casaId) async {
    final data = await _client.getJson('/case/$casaId/credito');
    return _parseAmount(data, key: 'credito');
  }

  Future<double> getDebitoTot(String casaId) async {
    final data = await _client.getJson('/case/$casaId/debito');
    return _parseAmount(data, key: 'debito');
  }

  Future<double> getCreditoVerso(String casaId, String inquilinoId) async {
    final data = await _client.getJson('/case/$casaId/credito/$inquilinoId');
    return _parseAmount(data, key: 'credito');
  }

  Future<double> getDebitoVerso(String casaId, String inquilinoId) async {
    final data = await _client.getJson('/case/$casaId/debito/$inquilinoId');
    return _parseAmount(data, key: 'debito');
  }

  List<T> _parseList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson, {
    String? key,
  }) {
    final list = _asList(data, key: key);
    return list.map(fromJson).toList();
  }

  List<Map<String, dynamic>> _asList(dynamic data, {String? key}) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map<String, dynamic>) {
      final candidate = key != null
          ? data[key]
          : data['items'] ?? data['results'] ?? data['spese'] ?? data['quote'];
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

  double _parseAmount(dynamic data, {required String key}) {
    if (data is num) {
      return data.toDouble();
    }
    if (data is Map<String, dynamic>) {
      final value = data[key] ?? data['value'] ?? data['amount'];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    throw const FormatException('Expected a numeric response.');
  }
}
