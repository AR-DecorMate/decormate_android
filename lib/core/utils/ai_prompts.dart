class AiPrompts {
  static const systemPrompt = '''
You are DecorMate AI, an expert interior design assistant. You help users with:
- Furniture placement suggestions for rooms
- Style and decor recommendations
- Color palette advice
- Room layout optimization
- Matching furniture pieces together

Be concise, friendly, and practical. When suggesting items, mention specific furniture
categories available in the app: Sofa, Bed, Table, Chair, Lamps, Frames, Fan, Lights,
Curtains, Washbasin, Tap, Windows, Decor, Chandelier.

Keep responses under 200 words unless the user asks for detail.

STRICT FORMATTING RULES (NEVER BREAK THESE):
- Use ONLY plain paragraphs, bullet points (using - or *), and headings ending with a colon.
- NEVER use markdown bold (**text**), italic (*text*), headers (#), code blocks (`text`), or any other markdown.
- NEVER use dollar signs or LaTeX formatting.
- NEVER use numbered lists with dots (1. 2. 3.) - use bullet points instead.
- For emphasis, just write the word normally.
- For section titles, write them on their own line ending with a colon like "Color Palette:"
- Keep it simple plain text that looks clean without any renderer.
''';

  static const unavailableMessage =
      'AI assistant is not configured. Please set the GEMINI_API_KEY build parameter.';

  static String placementPrompt(String itemName, String roomType) =>
      'I want to place a $itemName in my $roomType. Where should I put it for the best look and function? Remember: plain text only, no markdown.';

  static String stylePrompt(String itemName) =>
      'What furniture and decor goes well with a $itemName? Suggest complementary pieces. Remember: plain text only, no markdown.';

  static String roomAnalysisPrompt =
      'Analyze this room photo. Identify: room type, color palette, current style, '
      'and recommend furniture categories and specific items that would improve the space. '
      'Remember: plain text only, no markdown formatting.';

  static String contextualTip(String itemName) =>
      'The user just placed a $itemName in their room using AR. '
      'Give ONE brief, helpful tip about positioning or complementary items. '
      'Keep it under 30 words. Plain text only, absolutely no formatting.';

  /// Strips all markdown/latex junk from AI response
  static String cleanResponse(String text) {
    return text
        // Remove bold **text**
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        // Remove italic *text*
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        // Remove headers ## etc
        .replaceAll(RegExp(r'^#{1,6}\s', multiLine: true), '')
        // Remove code blocks ```
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        // Remove inline code `text`
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Remove dollar signs (LaTeX)
        .replaceAll(RegExp(r'\$+'), '')
        // Remove underscores used for emphasis
        .replaceAll(RegExp(r'__(.+?)__'), r'$1')
        .replaceAll(RegExp(r'_(.+?)_'), r'$1')
        // Clean up extra whitespace
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
