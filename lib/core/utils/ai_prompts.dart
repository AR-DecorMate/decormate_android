class AiPrompts {
  static const systemPrompt = '''
You are DecorMate AI, an expert interior design assistant. You help users with:
- Furniture placement suggestions for rooms
- Style and décor recommendations
- Color palette advice
- Room layout optimization
- Matching furniture pieces together

Be concise, friendly, and practical. When suggesting items, mention specific furniture 
categories available in the app: Sofa, Bed, Table, Chair, Lamps, Frames, Fan, Lights, 
Curtains, Washbasin, Tap, Windows, Decor, Chandelier.

Keep responses under 200 words unless the user asks for detail.
''';

  static const unavailableMessage =
      'AI assistant is not configured. Please set the GEMINI_API_KEY build parameter.';

  static String placementPrompt(String itemName, String roomType) =>
      'I want to place a $itemName in my $roomType. Where should I put it for the best look and function?';

  static String stylePrompt(String itemName) =>
      'What furniture and décor goes well with a $itemName? Suggest complementary pieces.';

  static String roomAnalysisPrompt =
      'Analyze this room photo. Identify: room type, color palette, current style, '
      'and recommend furniture categories and specific items that would improve the space.';

  static String contextualTip(String itemName) =>
      'The user just placed a $itemName in their room using AR. '
      'Give ONE brief, helpful tip about positioning or complementary items. '
      'Keep it under 30 words.';
}
