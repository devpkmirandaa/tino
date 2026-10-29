import 'package:flutter/material.dart';

import '../theme/tino_theme.dart';
import 'tino_wordmark.dart';

/// Superfície inicial compartilhada; não representa dados de compras.
class AreaPage extends StatelessWidget {
  const AreaPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.message,
    required this.detail,
    this.footer,
  });
  final String title;
  final String description;
  final IconData icon;
  final String message;
  final String detail;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const TinoWordmark(),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(title, style: text.headlineLarge),
              ),
              const SizedBox(height: 12),
              Text(description, style: text.bodyLarge),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: TinoColors.softWhite,
                  border: Border.all(color: TinoColors.lightJade),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon),
                    const SizedBox(height: 24),
                    Text(message, style: text.titleLarge),
                    const SizedBox(height: 12),
                    Text(detail, style: text.bodyLarge),
                  ],
                ),
              ),
              if (footer != null) ...[const SizedBox(height: 32), footer!],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
