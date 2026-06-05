import 'dart:convert';
import 'package:shelf/shelf.dart';

/// 打印完整 HTTP 请求内容（方法、URI、头、体）的中间件
Middleware logFullRequest() {
  return (Handler innerHandler) {
    return (Request request) async {
      // 1. 读取请求体所有字节（注意：读完后原请求的 body 就空了）
      final bodyBytes = await request.read().toList();

      // 2. 将字节列表合并成完整字符串（用于打印）
      final bodyString = utf8.decode(
        bodyBytes.expand((chunk) => chunk).toList(),
        allowMalformed: true,
      );

      // 3. 打印完整请求
      print('══════════ Incoming Request ══════════');
      print('${request.method} ${request.requestedUri}');
      print('Headers:');
      request.headers.forEach((name, value) {
        print('  $name: $value');
      });
      print('Body:');
      print(bodyString);
      print('═══════════════════════════════════════');

      // 4. 把读出的字节重新注入一个新请求，传给后续处理器
      final rebuiltRequest = request.change(
        body: Stream.fromIterable(bodyBytes),
      );

      // 5. 调用下一个处理器（路由或后续中间件）
      return innerHandler(rebuiltRequest);
    };
  };
}