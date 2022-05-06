#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:onepub/src/entry_point.dart';
import 'package:onepub/src/version/version.g.dart';

void main(List<String> arguments) {
  print(orange('OnePub version: $packageVersion '));

  print('');

  entrypoint(arguments);
}
