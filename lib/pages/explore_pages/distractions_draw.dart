import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smoking/pages/utils/themes.dart';

import 'package:smoking/extensions/widget_ref_theme.dart';
class DrawDoodlePage extends ConsumerStatefulWidget {
  const DrawDoodlePage({super.key});

  @override
  ConsumerState<DrawDoodlePage> createState() => _DrawDoodlePageState();
}

class _DrawDoodlePageState extends ConsumerState<DrawDoodlePage> {
  List<DrawnLine> lines = [];
  List<List<DrawnLine>> history = [];
  int historyIndex = -1;
  DrawnLine? currentLine;
  Color selectedColor = Colors.black;
  double selectedWidth = 4.0;
  bool isErasing = false;

  void startDrawing(Offset offset, bool isDark) {
    setState(() {
      currentLine = DrawnLine(
        [offset],
        isErasing
            ? (isDark ? AppThemes.darkCardColor : Colors.white)
            : selectedColor,
        isErasing ? selectedWidth * 2 : selectedWidth,
      );
    });
  }

  void draw(Offset offset) {
    setState(() {
      currentLine?.points.add(offset);
    });
  }

  void endDrawing() {
    if (currentLine != null) {
      saveState();
      setState(() {
        lines.add(currentLine!);
        currentLine = null;
      });
    }
  }

  void saveState() {
    if (historyIndex < history.length - 1) {
      history = history.sublist(0, historyIndex + 1);
    }
    history.add(List.from(lines));
    historyIndex = history.length - 1;
  }

  void undo() {
    if (historyIndex > 0) {
      setState(() {
        historyIndex--;
        lines = List.from(history[historyIndex]);
      });
    }
  }

  void redo() {
    if (historyIndex < history.length - 1) {
      setState(() {
        historyIndex++;
        lines = List.from(history[historyIndex]);
      });
    }
  }

  void clearCanvas() {
    saveState();
    setState(() {
      lines.clear();
    });
  }

  Widget buildColorPicker(Color color, bool isDark) {
    return GestureDetector(
      onTap:
          () => setState(() {
            selectedColor = color;
            isErasing = false;
          }),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color:
                color == selectedColor && !isErasing
                    ? (isDark ? AppThemes.darkTextColor : AppThemes.lightTextColor)
                    : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget buildBrushButton(String asset, double width, bool isDark) {
    return IconButton(
      icon: Image.asset(
        'assets/icons/$asset',
        width: width + 16,
        color:
            (selectedWidth == width && !isErasing)
                ? selectedColor
                : (isDark ? Colors.white70 : Colors.black54),
      ),
      onPressed:
          () => setState(() {
            selectedWidth = width;
            isErasing = false;
          }),
    );
  }

  Widget buildEraserButton(String asset, double width, bool isDark) {
    return IconButton(
      icon: Image.asset(
        'assets/icons/$asset',
        width: width + 16,
        color:
            (isErasing && selectedWidth == width)
                ? null
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
      ),
      onPressed:
          () => setState(() {
            selectedWidth = width;
            isErasing = true;
          }),
    );
  }

  Widget buildActionButton(
    String asset,
    VoidCallback onPressed,
    bool isActive,
    bool isDark,
  ) {
    return IconButton(
      icon: Image.asset(
        'assets/icons/$asset',
        width: 28,
        color:
            isActive
                ? (isDark
                    ? AppThemes.activeColor
                    : const Color.fromARGB(221, 29, 48, 218))
                : (isDark ? Colors.grey.shade400 : Colors.grey),
      ),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.isDark;
    final canUndo = historyIndex > 0;
    final canRedo = historyIndex < history.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: AppThemes.motivationGradient(isDark),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                'Get Creative ✨',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppThemes.darkTextColor : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? AppThemes.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart:
                        (details) =>
                            startDrawing(details.localPosition, isDark),
                    onPanUpdate: (details) => draw(details.localPosition),
                    onPanEnd: (_) => endDrawing(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CustomPaint(
                        painter: DoodlePainter(
                          lines: lines,
                          currentLine: currentLine,
                          backgroundColor:
                              isDark ? AppThemes.darkCardColor : Colors.white,
                        ),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          buildActionButton('undo.png', undo, canUndo, isDark),
                          buildActionButton('redo.png', redo, canRedo, isDark),
                          const SizedBox(width: 16),
                        ],
                      ),
                      Row(
                        children: [
                          buildBrushButton('pencil_thin.png', 2, isDark),
                          buildBrushButton('pencil_medium.png', 4, isDark),
                          buildBrushButton('pencil_thick.png', 6, isDark),
                          const SizedBox(width: 16),
                        ],
                      ),
                      Row(
                        children: [
                          buildEraserButton('eraser_thin.png', 4, isDark),
                          buildEraserButton('eraser_medium.png', 6, isDark),
                          buildEraserButton('eraser_thick.png', 8, isDark),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: 28,
                              color:
                                  isDark
                                      ? AppThemes.darkDeleteButtonColor
                                      : Colors.redAccent,
                            ),
                            onPressed: clearCanvas,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildColorPicker(Colors.black, isDark),
                    buildColorPicker(Colors.red, isDark),
                    buildColorPicker(Colors.green, isDark),
                    buildColorPicker(Colors.blue, isDark),
                    buildColorPicker(Colors.orange, isDark),
                    buildColorPicker(Colors.purple, isDark),
                    if (isDark) buildColorPicker(Colors.white, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DrawnLine {
  List<Offset> points;
  Color color;
  double width;

  DrawnLine(this.points, this.color, this.width);
}

class DoodlePainter extends CustomPainter {
  final List<DrawnLine> lines;
  final DrawnLine? currentLine;
  final Color backgroundColor;

  DoodlePainter({
    required this.lines,
    this.currentLine,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    for (final line in [...lines, if (currentLine != null) currentLine!]) {
      final paint =
          Paint()
            ..color = line.color
            ..strokeWidth = line.width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..style = PaintingStyle.stroke;

      if (line.points.length > 1) {
        for (int i = 0; i < line.points.length - 1; i++) {
          canvas.drawLine(line.points[i], line.points[i + 1], paint);
        }
      } else if (line.points.length == 1) {
        canvas.drawCircle(line.points[0], line.width / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DoodlePainter oldDelegate) => true;
}
