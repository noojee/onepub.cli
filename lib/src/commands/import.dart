/* Copyright (C) OnePub IP Pty Ltd - All Rights Reserved
 * licensed under the GPL v2.
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */
import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

import '../api/api.dart';
import '../exceptions.dart';
import '../onepub_settings.dart';
import '../util/one_pub_token_store.dart';
import '../util/token_export_file.dart';

// Name of the environment variable used by the `onepub import`
// command to pass the OnePub token into the import.
// Import supports multiple ways of importing the token.
const onepubSecretEnvKey = 'ONEPUB_TOKEN';

/// Imports a the onepub token generated by the onepub login process
/// and then addes it
class ImportCommand extends Command<int> {
  ///
  ImportCommand() : super() {
    argParser
      ..addFlag('file',
          abbr: 'f',
          negatable: false,
          help: 'Imports the OnePub token from onepub.token.yaml')
      ..addFlag('ask',
          abbr: 'a',
          negatable: false,
          help: 'Prompts the user to enter the OnePub token');
  }

  @override
  String get description => '''
${blue('Import a OnePub token.')}
Use `onepub export` to obtain the OnePub token.

  Ask the user to enter the OnePub token:
  ${green('onepub import --ask')}

  Import the OnePub token from the $onepubSecretEnvKey environment variable:
  ${green('onepub import')};

  Import the OnePub token from onepub.token.yaml:
  ${green('onepub import --file [<path to credentials>]')} ''';

  @override
  String get name => 'import';

  @override
  Future<int> run() async {
    await import();
    return 0;
  }

  ///
  Future<void> import() async {
    // if (OnePubTokenStore().isLoggedIn) {
    //   throw ExitException(
    //       exitCode: -1,
    //       message: 'You may not import a token when you are logged in '
    //           'to the OnePub CLI.');
    // }
    final file = argResults!['file'] as bool;
    final ask = argResults!['ask'] as bool;

    if (file && ask) {
      throw ExitException(
          exitCode: -1, message: 'You may not pass --ask and --file');
    }

    final String onepubToken;

    if (ask) {
      onepubToken = fromUser();
    } else if (file) {
      onepubToken = fromFile();
    } else {
      onepubToken = fromSecret();
    }

    await API().checkVersion();
    final organisation = await API().fetchOrganisation(onepubToken);
    if (!organisation.success) {
      throw ExitException(exitCode: 1, message: organisation.errorMessage!);
    }

    final settings = OnePubSettings.use()
      ..operatorEmail = 'not set during import'
      ..obfuscatedOrganisationId = organisation.obfuscatedId
      ..organisationName = organisation.name;
    await settings.save();

    OnePubTokenStore().addToken(
      onepubApiUrl: OnePubSettings.use().onepubApiUrlAsString,
      onepubToken: onepubToken,
    );

    print(blue('Successfully logged into ${organisation.name}.'));
  }

  /// pull the secret from onepub.export.yaml
  String fromFile() {
    final String pathToTokenFile;
    if (argResults!.rest.length > 1) {
      throw ExitException(exitCode: 1, message: '''
The onepub import command only takes zero or one arguments. 
Found: ${argResults!.rest.join(',')}''');
    }
    if (argResults!.rest.isEmpty) {
      pathToTokenFile = join(pwd, TokenExportFile.exportFilename);
    } else {
      pathToTokenFile = argResults!.rest[0];
    }

    if (!exists(pathToTokenFile)) {
      throw ExitException(
          exitCode: 1,
          message: "The OnePub token file '$pathToTokenFile', does not exist");
    }

    return TokenExportFile.load(pathToTokenFile).onepubToken;
  }

  /// pull the secret from an env var
  String fromSecret() {
    print(orange('Importing OnePub secret from $onepubSecretEnvKey'));

    if (!Env().exists(onepubSecretEnvKey)) {
      throw ExitException(exitCode: 1, message: '''
    The OnePub environment variable $onepubSecretEnvKey doesn't exist.
    Add it to your CI/CD secrets?.''');
    }

    return env[onepubSecretEnvKey]!;
  }

  String fromUser() => ask('ONEPUB_TOKEN:',
      validator: Ask.all([
        Ask.regExp('[a-zA-Z0-9-=]*',
            error: 'The secret contains invalid characters.'),
      ]));
}
