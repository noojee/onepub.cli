/* Copyright (C) OnePub IP Pty Ltd - All Rights Reserved
 * licensed under the GPL v2.
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart' hide equals;

/// Runs a onepub command on the cli and returns the output
/// stripped of any ansi chars.
List<String> runCmd(String command, {String? workingDirectory}) {
  workingDirectory ??= pwd;
  var pathToRoot = DartProject.self.pathToProjectRoot;
  var pathToOnePub = join(pathToRoot, 'bin', 'onepub.dart');

  var results =
      '$pathToOnePub $command'.toList(workingDirectory: workingDirectory);

  var clean = <String>[];

  /// strip all of the ansi chars from results to make matching easier.
  for (var result in results) {
    clean.add(Ansi.strip(result));
  }

  return clean;
}
