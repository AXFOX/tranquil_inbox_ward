import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'classifier.dart';

/// 将分类标签转换为三分类得分数组 [正常, 广告, 诈骗]
List<double> categoryToScores(String category) {
  switch (category) {
  //  case '工作':
  //  case '重要':
    case '普通':
      return [1.0, 0.0, 0.0];
    case '广告':
      return [0.0, 1.0, 0.0];
    case '垃圾':
      return [0.0, 0.0, 1.0];
    default:
      return [1.0, 0.0, 0.0]; // 未知默认为正常
  }
}

Router createRouter() {
  final router = Router();

  router.post('/classify', (Request request) async {
    // 1. 读取请求体
    final body = await request.readAsString();
    if (body.isEmpty) {
      return Response(400, body: 'Empty body');
    }

    // 2. 解析 JSON
    Map<String, dynamic> requestData;
    try {
      requestData = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return Response(400, body: 'Invalid JSON: $e');
    }

    // 3. 提取 instances[0].token 并拼接
    final instances = requestData['instances'];
    if (instances == null || instances is! List || instances.isEmpty) {
      return Response(400, body: 'Missing or empty "instances"');
    }
    final firstInstance = instances[0];
    if (firstInstance is! Map<String, dynamic>) {
      return Response(400, body: 'Invalid instance format');
    }
    final tokens = firstInstance['token'];
    if (tokens is! List || tokens.isEmpty) {
      return Response(400, body: 'Missing or invalid "token"');
    }
    //print(tokens.toString());
    //final emailText = tokens.map((t) => t.toString()).join(' ');
    // PMail 当前默认一个http请求对应一封邮件，此时只会有一个元素，直接转字符串
    final emailText = tokens[0].toString();
    // 4. 分类
    final category = await classifyEmail(emailText);

    // 5. 转换为 PMail 需要的得分格式
    final scores = categoryToScores(category);

    // 6. 构造响应（只含 predictions）
    final responseBody = jsonEncode({
      'predictions': [scores],
    });

    return Response.ok(
      responseBody,
      headers: {'Content-Type': 'application/json'},
    );
  });

  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  return router;
}