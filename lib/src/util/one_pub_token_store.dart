import 'package:dcli/dcli.dart';
import '../onepub_settings.dart';

import '../token_store/credential.dart';
import '../token_store/hosted.dart';
import '../token_store/io.dart';
import '../token_store/token_store.dart';

class OnePubTokenStore {
  static const onepubSecretEnvKey = 'ONEPUB_SECRET';

  void save(
      {required String onepubToken, required String obfuscatedPublisherId}) {
    withEnvironment(() {
      OnePubSettings().obfuscatedPublisherId = obfuscatedPublisherId;
      OnePubSettings().save();
      clearOldTokens();
      tokenStore.addCredential(
          Credential.token(_hostedUrl(obfuscatedPublisherId), onepubToken));
    }, environment: {onepubSecretEnvKey: onepubToken});
  }

// True if we have a onepub token.
  bool get isLoggedIn =>
      tokenStore
          .findCredential(_hostedUrl(OnePubSettings().obfuscatedPublisherId)) !=
      null;

  /// throws [StateError] if called when not logged in.
  /// returns the onepubToken.
  String fetch() {
    final credentials = tokenStore
        .findCredential(_hostedUrl(OnePubSettings().obfuscatedPublisherId));

    if (credentials == null || credentials.token == null) {
      throw StateError('You may not call fetch when not logged in');
    }

    return credentials.token!;
  }

  /// Removes the onepub token from the pub token store.
  void clearOldTokens() {
    tokenStore.removeMatchingCredential(
        validateAndNormalizeHostedUrl(OnePubSettings().onepubApiUrl));
    // tokenStore
    //  .removeCredential(_hostedUrl(OnePubSettings().obfuscatedPublisherId));
  }

  TokenStore get tokenStore => TokenStore(dartConfigDir);

  Uri _hostedUrl(String obfuscatedPublisherId) {
    final url = '${OnePubSettings().onepubApiUrl}/$obfuscatedPublisherId/';
    return validateAndNormalizeHostedUrl(url);
  }
}
