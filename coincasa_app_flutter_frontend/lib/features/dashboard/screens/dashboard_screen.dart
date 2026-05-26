import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/dashboard/dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.p16,
                vertical: AppSizes.p18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  DashboardHeader(),
                  SizedBox(height: AppSizes.p24),
                  BalanceSection(),
                  SizedBox(height: AppSizes.p20),
                  HouseHealthSection(),
                  SizedBox(height: AppSizes.p20),
                  UpcomingDeadlinesSection(),
                  SizedBox(height: AppSizes.p20),
                  OpenProblemsSection(),
                  SizedBox(height: AppSizes.p20),
                  TodayTurnSection(),
                  SizedBox(height: AppSizes.p20),
                  CalendarSection(),
                  SizedBox(height: AppSizes.p90),
                ],
              ),
            ),
            Positioned(
              right: AppSizes.p24,
              bottom: AppSizes.p24,
              child: FloatingActionButton(
                onPressed: () {},
                backgroundColor: AppColors.brandSecondary,
                child: const Icon(
                  Icons.add,
                  size: AppSizes.p35,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
