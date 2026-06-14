import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';

class HouseHealthBadgeData {
  const HouseHealthBadgeData({
    required this.caption,
    this.giorniRimanenti,
  });

  final String caption;
  // null = nessuna pulizia registrata (grigio)
  final int? giorniRimanenti;
}

class HouseHealthSection extends StatelessWidget {
  const HouseHealthSection({
    super.key,
    required this.badges,
    this.routeName = '/turni',
  });

  final List<HouseHealthBadgeData> badges;
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CenteredSectionTitle('SALUTE DELLA CASA'),
        const SizedBox(height: AppSizes.p14),
        InkWell(
          onTap: routeName == null
              ? null
              : () => Navigator.of(context).pushNamed(routeName!),
          borderRadius: BorderRadius.circular(AppSizes.radius24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceDarkElevated,
              borderRadius: BorderRadius.circular(AppSizes.radius24),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowStrong,
                  blurRadius: AppSizes.p25,
                  offset: Offset(0, AppSizes.p10),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.p20,
              vertical: AppSizes.p18,
            ),
            child: badges.isEmpty
                ? const Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            'Nessun turno disponibile',
                            style: AppTextStyles.dashboardBadgeCaption,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )
                : badges.length > 4
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(badges.length, (index) {
                            final badge = badges[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index == badges.length - 1
                                    ? 0
                                    : AppSizes.p18,
                              ),
                              child: _HealthBadge(data: badge),
                            );
                          }),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(badges.length, (index) {
                          final badge = badges[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == badges.length - 1
                                  ? 0
                                  : AppSizes.p18,
                            ),
                            child: _HealthBadge(data: badge),
                          );
                        }),
                      ),
          ),
        ),
      ],
    );
  }
}

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.data});

  final HouseHealthBadgeData data;

  static const double _badgeSize = AppSizes.p68;

  String get _label {
    final giorni = data.giorniRimanenti;
    if (giorni == null) return '--';
    if (giorni == 0) return 'Oggi';
    // Per i turni scaduti (giorni < 0) mostra il modulo senza segno
    return '${giorni.abs()}gg';
  }

  Color get _color {
    final giorni = data.giorniRimanenti;
    if (giorni == null) return const Color(0xFF9EA5B8); // grigio: nessuna pulizia
    if (giorni < -3) return const Color(0xFF9EA5B8); // grigio: scaduto da più di 3gg
    if (giorni <= 0) return const Color(0xFFFF4D4D); // rosso: scaduto (entro 3gg) o oggi
    if (giorni <= 2) return const Color(0xFFFFA62B); // arancione: quasi in scadenza
    return const Color(0xFF38C85A); // verde: abbondante margine
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _badgeSize,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: _badgeSize,
            width: _badgeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withValues(alpha: 0.16),
              border: Border.all(
                color: _color.withValues(alpha: 0.95),
                width: AppSizes.p5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              _label,
              style: AppTextStyles.dashboardBadgeLabel.copyWith(color: _color),
            ),
          ),
          const SizedBox(height: AppSizes.p8),
          Text(
            data.caption,
            textAlign: TextAlign.center,
            style: AppTextStyles.dashboardBadgeCaption,
          ),
        ],
      ),
    );
  }
}

class _CenteredSectionTitle extends StatelessWidget {
  const _CenteredSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.dashboardSectionTitle.copyWith(
        color: AppColors.textMuted,
        fontSize: 18,
        letterSpacing: 0,
      ),
      textAlign: TextAlign.center,
    );
  }
}
