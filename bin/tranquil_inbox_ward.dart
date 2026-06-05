import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

import 'package:tranquil_inbox_ward/server.dart';
import 'package:tranquil_inbox_ward/logging_middleware.dart';  // 导入

void main() async {
  final router = createRouter();

  final handler = Pipeline()
      .addMiddleware(logFullRequest())   // 先打印完整请求
      .addMiddleware(logRequests())      // 再打印 shelf 自带的简要日志
      .addHandler(router.call);

  final port = int.tryParse(Platform.environment['PORT'] ?? '9800') ?? 9800;
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print('Serving at http://${server.address.host}:${server.port}');
}