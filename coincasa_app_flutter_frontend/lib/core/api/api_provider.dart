import 'api_client.dart';
import 'auth_api.dart';
import 'casa_api.dart';
import 'spese_api.dart';
import 'turni_api.dart';

class ApiProvider {
  ApiProvider._();

  static final ApiClient client = ApiClient();
  static final AuthApi auth = AuthApi(client);
  static final CasaApi casa = CasaApi(client);
  static final SpeseApi spese = SpeseApi(client);
  static final TurniApi turni = TurniApi(client);
}
