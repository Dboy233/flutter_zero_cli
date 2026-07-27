// Example: run fluzer programmatically
//
// Run with: dart example/example.dart create my_app

import 'package:fluzer/fluzer.dart';

void main(List<String> arguments) async {
  // The Fluzer CLI can be invoked programmatically by passing
  // the same arguments you would use on the command line.
  final exitCode = await const Fluzer().run(arguments);

  if (exitCode != 0) {
    print('fluzer exited with code $exitCode');
  }
}
