import 'package:envied/envied.dart';
part 'env.g.dart';

@Envied()
abstract class Env {
  @EnviedField(varName: 'APIKEY', defaultValue: '')
  static String apikey = _Env.apikey;

  @EnviedField(varName: 'BASEURL', defaultValue: '')
  static String baseurl = _Env.baseurl;

  @EnviedField(varName: 'PASSWORDKEY', defaultValue: '', obfuscate: true)
  static String passwordkey = _Env.passwordkey;
}
