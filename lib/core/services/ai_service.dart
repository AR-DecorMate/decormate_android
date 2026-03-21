import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/ai_prompts.dart';

class AiService {
  GenerativeModel? _textModel;
  GenerativeModel? _visionModel;
  ChatSession? _chat;

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  bool get isAvailable => _apiKey.isNotEmpty;

  void _initModels() {
    if (_textModel != null) return;
    final key = _apiKey;
    debugPrint('[AiService] API key loaded: ${key.isEmpty ? "EMPTY" : "${key.substring(0, 8)}..."}');
    if (key.isEmpty) return;
    _textModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: key,
      systemInstruction: Content.text(AiPrompts.systemPrompt),
    );
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: key,
    );
    debugPrint('[AiService] Models initialized successfully');
  }

  Future<String> sendMessage(String prompt) async {
    _initModels();
    if (_textModel == null) {
      debugPrint('[AiService] textModel is null — API key missing');
      return AiPrompts.unavailableMessage;
    }

    _chat ??= _textModel!.startChat();
    try {
      debugPrint('[AiService] Sending message: ${prompt.substring(0, prompt.length.clamp(0, 50))}...');
      final response = await _chat!.sendMessage(Content.text(prompt));
      debugPrint('[AiService] Response received: ${response.text?.substring(0, (response.text?.length ?? 0).clamp(0, 80))}');
      return response.text ?? 'No response received.';
    } catch (e, stack) {
      debugPrint('[AiService] ERROR in sendMessage: $e');
      debugPrint('[AiService] Stack: $stack');
      _chat = null; // Reset chat on error so next attempt starts fresh
      return 'Error: $e';
    }
  }

  Future<String> analyzeImage(Uint8List imageBytes, String prompt) async {
    _initModels();
    if (_visionModel == null) return AiPrompts.unavailableMessage;

    try {
      final response = await _visionModel!.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);
      return response.text ?? 'No analysis received.';
    } catch (e, stack) {
      debugPrint('[AiService] ERROR in analyzeImage: $e');
      debugPrint('[AiService] Stack: $stack');
      return 'Error: $e';
    }
  }

  void resetChat() {
    _chat = null;
  }
}
