import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Shared pieces for the web layout of the create/add forms: a centred
/// scrolling page, white section cards, two-column rows, the field outline and
/// a right-aligned action bar.
class WebForm {
  WebForm._();

  static const line = Color(0xFFE2E8E3);
  static const fieldBorder = Color(0xFFD9E2DB);
  static const gap = 18.0;

  /// Field outline: a soft bordered rectangle on web, the pill on mobile.
  static ShapeBorder fieldShape(double radius) => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kIsWeb ? 12 : radius),
        side: kIsWeb ? const BorderSide(color: fieldBorder) : BorderSide.none,
      );

  /// Corner radius for a field: 12 on web, [mobile] otherwise.
  static double radius(double mobile) => kIsWeb ? 12 : mobile;

  /// Upload drop-zone styling on web (tinted, bordered, flat).
  static BoxDecoration uploadDecoration() => BoxDecoration(
        color: const Color(0xFFF3F8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB9D5BF), width: 1.2),
      );

  /// Scrolling page with the form centred, at most [maxWidth] wide.
  static Widget page(List<Widget> children, {double maxWidth = 860}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  /// White section card. With [title], it opens with the icon badge, title
  /// and [subtitle] on the left and a divider below.
  static Widget section({
    IconData? icon,
    String? title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEBDD),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: const Color(0xFF278245), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14201A),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: line),
            const SizedBox(height: 22),
          ],
          ...children,
        ],
      ),
    );
  }

  /// Two fields side by side, stacked when the form is narrow.
  static Widget row(Widget a, Widget b) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 560) {
          return Column(children: [a, const SizedBox(height: gap), b]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: gap),
            Expanded(child: b),
          ],
        );
      },
    );
  }

  /// [left] and [right] side by side on wide pages, stacked otherwise.
  static Widget split(
    Widget left,
    Widget right, {
    int leftFlex = 1,
    int rightFlex = 1,
  }) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 20), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            const SizedBox(width: 22),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }

  /// Lays [fields] out two per row, with a gap between rows.
  static List<Widget> pairs(List<Widget> fields) {
    final out = <Widget>[];
    for (var i = 0; i < fields.length; i += 2) {
      if (i > 0) out.add(const SizedBox(height: gap));
      out.add(
        i + 1 < fields.length ? row(fields[i], fields[i + 1]) : fields[i],
      );
    }
    return out;
  }

  /// Bottom action bar styling on web: white with a top hairline.
  static const barDecoration = BoxDecoration(
    color: Colors.white,
    border: Border(top: BorderSide(color: line)),
  );

  static const barPadding = EdgeInsets.fromLTRB(24, 14, 24, 14);

  /// The action buttons grouped at the right of the bar on web.
  static Widget actions(Widget row) => kIsWeb
      ? Align(
          alignment: Alignment.centerRight,
          child: SizedBox(width: 380, child: row),
        )
      : row;
}
