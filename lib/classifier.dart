import 'dart:convert';
import 'dart:io';
import 'package:tranquil_inbox_ward/ollama_client.dart';
/// 根据邮件文本内容返回分类标签
///
/// [emailText] 邮件正文
/// [enableOllama] 是否启用 Ollama 分类，默认 true（启用时调用 classifyEmailWithOllama）
/// [enableBlackwords] 是否启用黑名单过滤，默认 false（启用时检查本地 blackwords.json）
/// [blackwordsPath] 黑名单 JSON 文件路径，默认为 './blackwords.json'
Future<String> classifyEmail(
  String emailText, {
  bool enableOllama = true,
  bool enableBlackwords = false,
  String blackwordsPath = './blackwords.json',
}) async {
  // 1. 如果启用黑名单，先进行黑名单匹配（优先级高，一旦命中直接返回“垃圾”）
  if (enableBlackwords) {
    final blackwords = await _loadBlackwords(blackwordsPath);
    final lowerText = emailText.toLowerCase();
    for (final word in blackwords) {
      if (lowerText.contains(word.toLowerCase())) {
        return '垃圾';
      }
    }
  }

  // 2. 如果启用 Ollama，调用模型分类
  if (enableOllama) {
    try {
      final ollamaResult = await classifyEmailWithOllama(emailText);
      return ollamaResult;
    } catch (e) {
      print('Ollama 调用失败: $e，降级使用关键词匹配');
      // 继续执行下面的关键词匹配逻辑
    }
  }

  // 3. 降级或未启用 Ollama 时的关键词匹配（原规则）
  //final text = emailText.toLowerCase();

  //if (text.contains('@mycompany.com')) return '工作';
  //if (text.contains('urgent') || text.contains('紧急')) return '重要';
  //if (text.contains('newsletter') || text.contains('订阅')) return '广告';
  // if (text.contains('spam') || text.contains('click here')) return '垃圾'; // 已由黑名单覆盖
  return '普通';
}

/// 从本地 JSON 文件加载黑名单词汇列表
/// 文件格式必须为：{"blackwords": ["word1", "word2"]}
Future<List<String>> _loadBlackwords(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    print('警告: 黑名单文件 $path 不存在，返回空列表');
    return [];
  }
  try {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is Map && decoded.containsKey('blackwords')) {
      final list = decoded['blackwords'];
      if (list is List) {
        return list.map((e) => e.toString()).toList();
      }
    }
    // 格式不符合要求时，打印错误并返回空列表
    print('错误: 黑名单文件格式不正确，应为 {"blackwords": ["word1", "word2"]}');
    return [];
  } catch (e) {
    print('读取黑名单文件失败: $e');
    return [];
  }
}