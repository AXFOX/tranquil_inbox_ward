import 'package:ollama_dart/ollama_dart.dart';

/// 调用 Ollama 模型对邮件内容进行分类，使用 few-shot 示例引导输出格式
///
/// [emailContent] 邮件正文
/// [model] 使用的模型名称，默认 'mollysama/rwkv-7-g1g:1.5b'
/// [config] Ollama 客户端配置，默认使用缺省值（http://localhost:11434）
/// [useFewShotExamples] 是否使用预设的三轮对话示例，默认为 true
/// 返回提取出的分类词（如 "普通"、"广告"、"垃圾"），如果提取失败则返回原始模型输出
Future<String> classifyEmailWithOllama(
  String emailContent, {
  String model = 'mollysama/rwkv-7-g1g:1.5b',
  OllamaConfig? config,
  bool useFewShotExamples = true,
}) async {
  final client = OllamaClient(config: config ?? OllamaConfig());

  // 构建消息列表
  final List<ChatMessage> messages = [];

  if (useFewShotExamples) {
    // 第一轮：广告邮件示例
    messages.add(ChatMessage.user(
        '你是一个经验丰富的邮件分类专家，请根据以下邮件内容进行分类（例如：普通、广告、垃圾）只需要回复一个位于【】中的词，邮件内容如下：【限时特惠】奢华腕表系列 - 250 美元起'));
    messages.add(ChatMessage.assistant('【广告】'));

    // 第二轮：普通邮件示例
    messages.add(ChatMessage.user(
        '请根据以下邮件内容进行分类（只需要回复【】中的词）：\n\n【会议通知】明天下午2点项目组讨论，地点三楼会议室'));
    messages.add(ChatMessage.assistant('【普通】'));

    // 第三轮：垃圾邮件示例
    messages.add(ChatMessage.user(
        '请根据以下邮件内容进行分类（只需要回复【】中的词）：\n\n【中奖通知】恭喜您获得一等奖，请点击 http://fake.link 领取'));
    messages.add(ChatMessage.assistant('【垃圾】'));
  }

  // 添加真正的用户邮件内容
  messages.add(ChatMessage.user('请对以下邮件内容进行分类，只需要回复【】中的词：\n\n$emailContent'));

  try {
    final response = await client.chat.create(
      request: ChatRequest(
        model: model,
        messages: messages,
      ),
    );

    final rawResult = response.message?.content?.trim();
    if (rawResult == null || rawResult.isEmpty) {
      throw Exception('模型未返回有效内容');
    }

    // 提取最后一个【】中的内容（防止模型思考过程也包含【】）
    final RegExp bracketRegex = RegExp(r'【(.*?)】');
    final matches = bracketRegex.allMatches(rawResult);
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      String extracted = lastMatch.group(1)!;
      // 可选：验证提取的内容是否属于期望的类别
      if (['普通', '广告', '垃圾'].contains(extracted)) {
        return extracted;
      } else {
        // 如果提取出的词不在预期类别中，仍返回原模型输出（或根据需要抛出异常）
        print('警告：提取的分类 "$extracted" 不是预期类别，返回原始结果');
        return rawResult;
      }
    } else {
      // 没有匹配到【】，返回原始内容
      print('警告：模型返回的内容中没有【】，返回原始结果');
      return rawResult;
    }
  } finally {
    client.close();
  }
}

/// 示例用法
Future<void> main() async {
  const email = '您好，这是本周的项目进度报告，请查收附件。祝好，王工';

  try {
    // 使用默认配置（本地 Ollama 服务）
    final output = await classifyEmailWithOllama(email);
    print('分类结果：\n$output');
  } catch (e) {
    print('调用失败：$e');
  }

  // 如果需要自定义配置（例如远程服务器）
  // final customConfig = OllamaConfig(baseUrl: 'http://192.168.1.100:11434');
  // final output2 = await classifyEmailWithOllama(email, config: customConfig);
}