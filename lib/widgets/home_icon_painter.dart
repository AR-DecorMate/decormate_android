import 'package:flutter/material.dart';

class HomeIconPainter extends CustomPainter {
  final Color color;

  HomeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 175;
    final scaleY = size.height / 155;

    final path = Path();

    // House base rectangle
    path.moveTo(49.4793 * scaleX, 88.5793 * scaleY);
    path.lineTo(52.7811 * scaleX, 88.5793 * scaleY);
    path.lineTo(52.7811 * scaleX, 105.084 * scaleY);
    path.lineTo(49.4793 * scaleX, 105.084 * scaleY);
    path.close();

    // Left wall detail
    path.moveTo(49.4793 * scaleX, 88.5793 * scaleY);
    path.cubicTo(49.4793 * scaleX, 84.3298 * scaleY, 46.1774 * scaleX, 86.444 * scaleY, 46.1774 * scaleX, 88.5793 * scaleY);

    // Couch
    path.moveTo(62.48 * scaleX, 75.655 * scaleY);
    path.lineTo(112.546 * scaleX, 75.655 * scaleY);

    // Right side of couch
    path.moveTo(112.546 * scaleX, 75.655 * scaleY);
    path.cubicTo(116.858 * scaleX, 72.3531 * scaleY, 120.997 * scaleX, 74.0596 * scaleY, 124.051 * scaleX, 77.1011 * scaleY);
    path.lineTo(119.39 * scaleX, 81.7799 * scaleY);

    path.moveTo(125.521 * scaleX, 88.5793 * scaleY);
    path.lineTo(125.521 * scaleX, 105.084 * scaleY);

    // Top couch back
    path.moveTo(135.845 * scaleX, 110.746 * scaleY);
    path.cubicTo(132.543 * scaleX, 110.131 * scaleY, 134.187 * scaleX, 106.76 * scaleY, 136.518 * scaleX, 104.421 * scaleY);

    path.moveTo(130.186 * scaleX, 105.109 * scaleY);
    path.lineTo(120.856 * scaleX, 105.109 * scaleY);

    path.moveTo(115.197 * scaleX, 110.746 * scaleY);
    path.lineTo(115.197 * scaleX, 125.981 * scaleY);
    path.lineTo(59.7779 * scaleX, 125.981 * scaleY);
    path.lineTo(59.7779 * scaleX, 110.746 * scaleY);

    // Left couch arm
    path.moveTo(54.1187 * scaleX, 105.109 * scaleY);
    path.lineTo(44.7888 * scaleX, 105.109 * scaleY);

    // Left wall section
    path.moveTo(39.1297 * scaleX, 110.746 * scaleY);
    path.lineTo(39.1297 * scaleX, 150.789 * scaleY);
    path.lineTo(135.819 * scaleX, 150.789 * scaleY);

    // Right wall
    path.moveTo(160.852 * scaleX, 87.8174 * scaleY);
    path.lineTo(160.852 * scaleX, 150.789 * scaleY);

    // Roof right side
    path.moveTo(160.852 * scaleX, 87.8174 * scaleY);
    path.lineTo(158.15 * scaleX, 81.8758 * scaleY);
    path.lineTo(92.4326 * scaleX, 24.719 * scaleY);

    // Roof peak
    path.moveTo(92.4326 * scaleX, 24.719 * scaleY);
    path.cubicTo(90.2646 * scaleX, 27.2094 * scaleY, 88.3497 * scaleX, 26.0766 * scaleY, 87.2323 * scaleX, 22.7747 * scaleY);
    path.cubicTo(86.115 * scaleX, 26.0766 * scaleY, 84.2 * scaleX, 27.2094 * scaleY, 82.032 * scaleX, 24.719 * scaleY);

    // Roof left side
    path.lineTo(16.3146 * scaleX, 81.8758 * scaleY);
    path.lineTo(13.6125 * scaleX, 87.8174 * scaleY);
    path.lineTo(13.6125 * scaleX, 150.789 * scaleY);

    // Bottom line
    path.moveTo(0 * scaleX, 150.789 * scaleY);
    path.lineTo(175 * scaleX, 150.789 * scaleY);

    // Chimney
    path.moveTo(59.8288 * scaleX, 24.1605 * scaleY);
    path.lineTo(59.8288 * scaleX, 14.0038 * scaleY);
    path.cubicTo(59.8288 * scaleX, 10.1688 * scaleY, 59.2935 * scaleX, 10.1688 * scaleY, 59.2935 * scaleX, 13.4707 * scaleY);
    path.lineTo(39.2571 * scaleX, 13.4707 * scaleY);
    path.lineTo(38.7218 * scaleX, 42.417 * scaleY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}