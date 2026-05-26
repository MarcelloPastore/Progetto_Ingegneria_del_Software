import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.dashboardSectionTitle);
  }
}
