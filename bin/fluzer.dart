// fluzer 入口 / Entry point for fluzer
// 用法 / Usage:
//   dart run bin/fluzer.dart new user
//
// 安装后 / After install:
//   dart pub global activate fluzer
//   fluzer new user

import 'dart:io';

import 'package:fluzer/fluzer.dart';

/// 程序入口 / Entry point
Future<void> main(List<String> arguments) async {
  final exitCode = await Fluzer().run(arguments);
  exit(exitCode);
}
