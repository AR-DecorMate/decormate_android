import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/ai_prompts.dart';

class AiService {
  GenerativeModel? _textModel;
  GenerativeModel? _visionModel;
  ChatSession? _chat;
  bool _usingFallback = false;

  static String get _primaryKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _fallbackKey => dotenv.env['GEMINI_API_KEY_FALLBACK'] ?? '';

  String get _activeKey => _usingFallback ? _fallbackKey : _primaryKey;

  bool get isAvailable => _primaryKey.isNotEmpty || _fallbackKey.isNotEmpty;

  void _initModels({bool forceFallback = false}) {
    if (forceFallback && !_usingFallback && _fallbackKey.isNotEmpty) {
      _usingFallback = true;
      _textModel = null;
      _visionModel = null;
      _chat = null;
      debugPrint('[AiService] Switching to fallback API key');
    }
    if (_textModel != null) return;
    final key = _activeKey;
    debugPrint('[AiService] API key loaded (${_usingFallback ? "fallback" : "primary"}): ${key.isEmpty ? "EMPTY" : "${key.substring(0, 8)}..."}');
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
      _chat = null;
      // Retry with fallback key if not already using it
      if (!_usingFallback && _fallbackKey.isNotEmpty) {
        debugPrint('[AiService] Retrying with fallback key...');
        _initModels(forceFallback: true);
        return sendMessage(prompt);
      }
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
      // Retry with fallback key if not already using it
      if (!_usingFallback && _fallbackKey.isNotEmpty) {
        debugPrint('[AiService] Retrying analyzeImage with fallback key...');
        _initModels(forceFallback: true);
        return analyzeImage(imageBytes, prompt);
      }
      return 'Error: $e';
    }
  }

  void resetChat() {
    _chat = null;
  }
}
