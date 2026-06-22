import 'package:flutter/material.dart';
import '../../core/format.dart';
import '../../core/ui.dart';

const trendMetrics = ['疼痛', '乏力', '睡眠', '心情', '食欲', '体温', '体重'];
const _fields = {
  '疼痛': 'painScore',
  '乏力': 'fatigueScore',
  '睡眠': 'sleepScore',
  '心情': 'moodScore',
  '食欲': 'appetiteScore',
  '体温': 'temperature',
  '体重': 'weight',
};
const _measureMetrics = {'体温', '体重'};

class _Point {
  _Point(this.label, this.value);
  final String label;
  final double? value;
}

class TrendChart extends StatelessWidget {
  const TrendChart(
      {super.key,
      required this.records,
      required this.metric,
      required this.days});
  final List<dynamic> records; // body records, newest first
  final String metric;
  final int days;

  List<_Point> _buildPoints() {
    final field = _fields[metric]!;
    final isMeasure = _measureMetrics.contains(metric);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    if (isMeasure) {
      final list = <MapEntry<DateTime, double>>[];
      for (final r in records) {
        final raw = r[field];
        final at =
            tryParse(r['measuredAt'] ?? r['createdAt'] ?? r['recordDate']);
        if (raw == null || raw == '' || at == null || at.isBefore(cutoff)) {
          continue;
        }
        final v = (raw as num).toDouble();
        list.add(MapEntry(at, v));
      }
      list.sort((a, b) => a.key.compareTo(b.key));
      return list
          .map((e) => _Point(
              metric == '体温'
                  ? formatMonthDayTime(e.key.toIso8601String())
                  : formatDateLabel(e.key),
              e.value))
          .toList();
    }
    // score：每天保留最近一次非空值
    final byDay = <String, double>{};
    for (final r in records) {
      final raw = r[field];
      if (raw == null || raw == '') continue;
      final key = (r['recordDate'] ?? dateKeyOf(r['createdAt'])).toString();
      byDay.putIfAbsent(key, () => (raw as num).toDouble());
    }
    final now = DateTime.now();
    final points = <_Point>[];
    for (var offset = days - 1; offset >= 0; offset--) {
      final d = now.subtract(Duration(days: offset));
      final key = dateKey(d);
      points.add(_Point(formatDateLabel(d), byDay[key]));
    }
    return points;
  }

  @override
  Widget build(BuildContext context) {
    final points = _buildPoints();
    final hasData = points.any((p) => p.value != null);
    if (!hasData) {
      return emptyNote('最近$days天还没有$metric记录。');
    }
    final width = (points.length * 34 + 54).clamp(320, 1600).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: 200,
            child: CustomPaint(
                painter: _TrendPainter(points, metric),
                child: const SizedBox.expand()),
          ),
        ),
        const SizedBox(height: 6),
        Text(
            '$metric · ${points.where((p) => p.value != null).length} ${_measureMetrics.contains(metric) ? '次记录' : '天有记录'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: muted)),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.points, this.metric);
  final List<_Point> points;
  final String metric;

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 36.0, padRight = 14.0, padTop = 16.0, padBottom = 44.0;
    final values =
        points.where((p) => p.value != null).map((p) => p.value!).toList();
    double min = 0, max = 10;
    List<double> yTicks = [0, 2, 4, 6, 8, 10];
    if (metric == '体温') {
      min = 34;
      max = 42;
      yTicks = [34, 36, 38, 40, 42];
    } else if (metric == '体重') {
      final low = values.isEmpty
          ? 40.0
          : values.reduce((a, b) => a < b ? a : b).floorToDouble() - 1;
      final high = values.isEmpty
          ? 80.0
          : values.reduce((a, b) => a > b ? a : b).ceilToDouble() + 1;
      min = low == high ? low - 1 : low;
      max = low == high ? high + 1 : high;
      yTicks = List.generate(5,
          (i) => double.parse((min + (max - min) / 4 * i).toStringAsFixed(1)));
    }
    if (max <= min) max = min + 1;

    final plotW = size.width - padLeft - padRight;
    final plotH = size.height - padTop - padBottom;
    final step = points.length > 1 ? plotW / (points.length - 1) : 0.0;
    double px(int i) => padLeft + (points.length > 1 ? i * step : plotW / 2);
    double py(double v) => padTop + (1 - (v - min) / (max - min)) * plotH;
    final baseY = size.height - padBottom;

    final gridPaint = Paint()
      ..color = const Color(0xffeadbca)
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xffd8cabb)
      ..strokeWidth = 1.4;
    final labelStyle = const TextStyle(fontSize: 10, color: muted);

    // Y 网格 + 刻度
    for (final t in yTicks) {
      final y = py(t);
      canvas.drawLine(
          Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
      _text(canvas, _tickLabel(t), Offset(padLeft - 6, y - 6), labelStyle,
          alignRight: true);
    }
    // 坐标轴
    canvas.drawLine(Offset(padLeft, baseY),
        Offset(size.width - padRight, baseY), axisPaint);
    canvas.drawLine(Offset(padLeft, padTop), Offset(padLeft, baseY), axisPaint);

    // 收集有值的点
    final dots = <Offset>[];
    final dotValues = <double>[];
    for (var i = 0; i < points.length; i++) {
      // X 轴标签
      _text(
          canvas, points[i].label, Offset(px(i), size.height - 30), labelStyle,
          center: true);
      final v = points[i].value;
      if (v != null) {
        dots.add(Offset(px(i), py(v)));
        dotValues.add(v);
      }
    }

    // 面积
    if (dots.length > 1) {
      final area = Path()..moveTo(dots.first.dx, baseY);
      for (final d in dots) {
        area.lineTo(d.dx, d.dy);
      }
      area.lineTo(dots.last.dx, baseY);
      area.close();
      canvas.drawPath(
          area,
          Paint()
            ..shader = const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x4d78927c), Color(0x0078927c)])
                .createShader(Rect.fromLTWH(0, padTop, size.width, plotH)));
      // 折线
      final line = Path()..moveTo(dots.first.dx, dots.first.dy);
      for (final d in dots.skip(1)) {
        line.lineTo(d.dx, d.dy);
      }
      canvas.drawPath(
          line,
          Paint()
            ..color = sage
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeJoin = StrokeJoin.round);
    }
    // 点 + 数值
    final dotPaint = Paint()..color = sage;
    for (var i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], 3.4, dotPaint);
      _text(
          canvas,
          _valueLabel(dotValues[i]),
          Offset(dots[i].dx, dots[i].dy - 18),
          const TextStyle(
              fontSize: 10, color: ink, fontWeight: FontWeight.w600),
          center: true);
    }
  }

  String _tickLabel(double v) =>
      v == v.roundToDouble() ? v.round().toString() : trimDecimal(v);
  String _valueLabel(double v) {
    if (metric == '体温') return v.toStringAsFixed(1);
    if (metric == '体重') return trimDecimal(v);
    return v.round().toString();
  }

  void _text(Canvas canvas, String text, Offset at, TextStyle style,
      {bool center = false, bool alignRight = false}) {
    final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr)
      ..layout();
    var dx = at.dx;
    if (center) dx -= tp.width / 2;
    if (alignRight) dx -= tp.width;
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.points != points || old.metric != metric;
}
