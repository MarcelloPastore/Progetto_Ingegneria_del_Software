import 'account_api.dart';
import 'api_client.dart';
import 'auth_api.dart';
import 'casa_api.dart';
import 'problemi_api.dart';
import 'scadenze_api.dart';
import 'spese_api.dart';
import 'turni_api.dart';

class ApiProvider {
  ApiProvider._();

  static ApiClient client = ApiClient();
  static AccountApi account = AccountApi(client);
  static AuthApi auth = AuthApi(client);
  static CasaApi casa = CasaApi(client);
  static SpeseApi spese = SpeseApi(client);
  static TurniApi turni = TurniApi(client);
  static ProblemiApi problemi = ProblemiApi(client);
  static ScadenzeApi scadenze = ScadenzeApi(client);
}
