import '../models/casa.dart';
import '../models/inquilino.dart';
import 'api_client.dart';

class CasaApi {
  CasaApi(this._client);

  final ApiClient _client;

  Future<List<Casa>> list() async {
    final data = await _client.getJson('/case');
    return _parseList(data, Casa.fromJson, key: 'case');
  }

  Future<Casa> getById(String casaId) async {
    final data = await _client.getJson('/case/$casaId');
    return Casa.fromJson(_asMap(data));
  }

  Future<Casa> create(Map<String, dynamic> payload) async {
    final data = await _client.postJson('/case', body: payload);
    return Casa.fromJson(_asMap(data));
  }

  Future<Casa> update(String casaId, Map<String, dynamic> payload) async {
    final data = await _client.putJson('/case/$casaId', body: payload);
    return Casa.fromJson(_asMap(data));
  }

  Future<void> delete(String casaId) async {
    await _client.deleteJson('/case/$casaId');
  }

  Future<Inquilino> addSelfWithInvite(
    String casaId, {
    required String inviteCodeOrLink,
  }) async {
    final data = await _client.postJson(
      '/case/$casaId/inquilini',
      body: {'inviteCode': inviteCodeOrLink},
    );
    return Inquilino.fromJson(_asMap(data));
  }

  Future<List<Inquilino>> listInquilini(String casaId) async {
    final data = await _client.getJson('/case/$casaId/inquilini');
    return _parseList(data, Inquilino.fromJson, key: 'inquilini');
  }

  Future<Inquilino> getInquilino(String casaId, String inquilinoId) async {
    final data = await _client.getJson('/case/$casaId/inquilini/$inquilinoId');
    return Inquilino.fromJson(_asMap(data));
  }

  Future<void> addInquilino(String casaId, Map<String, dynamic> payload) async {
    await _client.postJson('/case/$casaId/inquilini', body: payload);
  }

  Future<void> removeInquilino(String casaId, String inquilinoId) async {
    await _client.deleteJson('/case/$casaId/inquilini/$inquilinoId');
  }

  Future<void> updateRuolo(
    String casaId,
    String inquilinoId,
    Map<String, dynamic> payload,
  ) async {
    await _client.putJson(
      '/case/$casaId/inquilini/$inquilinoId/ruolo',
      body: payload,
    );
  }

  Future<String> getInviteLink(String casaId) async {
    final data = await _client.getJson('/case/$casaId/invite-link');
    if (data is String) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      final link = data['link'] ?? data['inviteLink'] ?? data['url'];
      if (link is String) {
        return link;
      }
    }
    throw const FormatException('Expected an invite link response.');
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
          : data['items'] ??
                data['results'] ??
                data['case'] ??
                data['inquilini'];
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
