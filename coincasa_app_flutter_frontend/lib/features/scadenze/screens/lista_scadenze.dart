import 'package:flutter/material.dart';
import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/house_quick_nav.dart';
import 'dettaglio_scadenza_admin.dart';

class ScadenzaItem {
	final String title;
	final String subtitle;
	final String date;
	final String badgeText;
	final Color badgeColor;

	ScadenzaItem(this.title, this.subtitle, this.date, this.badgeText, this.badgeColor);
}

class ListaScadenze extends StatelessWidget {
	const ListaScadenze({super.key});

	@override
	Widget build(BuildContext context) {
		final inScadenza = [
			ScadenzaItem('Affitto', 'Pagamento mensile', '31/05/2026', 'Oggi', const Color(0xFFFF2525)),
			ScadenzaItem('Bolletta gas', 'Rata mensile', '3/06/2026', '3 giorni', const Color(0xFFD98842)),
		];

		final prossime = [
			ScadenzaItem('Revisione Caldaia', 'Rata mensile', '20/06/2026', '25 gg', const Color(0xFF79FF31)),
		];

		return Scaffold(
			backgroundColor: const Color(0xFF09051F),
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
					child: Column(
						children: [
							const SizedBox(height: 8),
							Text(
								'Scadenze',
								textAlign: TextAlign.center,
								style: AppTextStyles.screenTitleStrong.copyWith(
									color: AppColors.brandAccent,
									fontSize: 40,
									fontWeight: FontWeight.w800,
								),
							),
							const SizedBox(height: 16),
							Expanded(
								child: ListView(
									children: [
										const Text('IN SCADENZA', style: TextStyle(color: Color(0xFFD8D5D5), fontWeight: FontWeight.w700)),
										const SizedBox(height: 8),
										...inScadenza.map((s) => _buildCard(context, s, borderColorForBadge(s.badgeColor))),
										const SizedBox(height: 12),
										const Text('PROSSIME', style: TextStyle(color: Color(0xFFD8D5D5), fontWeight: FontWeight.w700)),
										const SizedBox(height: 8),
										...prossime.map((s) => _buildCard(context, s, borderColorForBadge(s.badgeColor))),
										const SizedBox(height: 20),
										SizedBox(
											width: double.infinity,
											height: 48,
											child: ElevatedButton(
												onPressed: () {
													// TODO: collegare la navigazione per aggiungere una scadenza
												},
												style: ElevatedButton.styleFrom(
													backgroundColor: const Color(0xFF5228AD),
													shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
												),
												child: const Text('Aggiungi scadenza', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
											),
										),
										const SizedBox(height: 24),
									],
								),
							),
						],
					),
				),
			),
			bottomNavigationBar: const HouseQuickNav(currentRoute: '/scadenze'),
		);
	}

	Widget _buildCard(BuildContext context, ScadenzaItem s, Color borderColor) {
		return InkWell(
			onTap: () {
				// Naviga alla schermata di dettaglio passando i dati della scadenza
				Navigator.of(context).push(MaterialPageRoute(
					builder: (_) => DettaglioScadenzaAdminScreen(
						titolo: s.title,
						descrizione: s.subtitle,
						dataScadenza: _parseDate(s.date),
						stato: s.badgeText,
						frequenza: 'Annuale',
						isAdmin: true,
					),
				));
			},
			child: Container(
				margin: const EdgeInsets.symmetric(vertical: 8),
				decoration: BoxDecoration(
					color: const Color(0xFF16203C),
					borderRadius: BorderRadius.circular(10),
					border: Border(left: BorderSide(width: 6, color: borderColor)),
					boxShadow: const [BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 4))],
				),
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
					child: Row(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(s.title, style: const TextStyle(color: Color(0xFFD8D5D5), fontSize: 20, fontWeight: FontWeight.w700)),
										const SizedBox(height: 4),
										Text(s.subtitle, style: const TextStyle(color: Color(0xFFD8D5D5), fontSize: 16, fontWeight: FontWeight.w500)),
										const SizedBox(height: 8),
										Text(s.date, style: const TextStyle(color: Color(0xFFD8D5D5), fontSize: 16, fontWeight: FontWeight.w500)),
									],
								),
							),
							const SizedBox(width: 8),
							Column(
								crossAxisAlignment: CrossAxisAlignment.end,
								children: [
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
										decoration: BoxDecoration(color: s.badgeColor.withValues(alpha: 0.95), borderRadius: BorderRadius.circular(6)),
										child: Text(s.badgeText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
									),
									const SizedBox(height: 8),
									Container(
										padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
										decoration: BoxDecoration(color: const Color(0xFF31166F), borderRadius: BorderRadius.circular(6)),
										child: const Text('Ricorrente', style: TextStyle(color: Color(0xFFB29BFE), fontWeight: FontWeight.w700)),
									),
								],
							),
						],
					),
				),
			),
		);
	}

	Color borderColorForBadge(Color badge) => badge;

	DateTime _parseDate(String s) {
		try {
			final parts = s.split('/');
			if (parts.length == 3) {
				final d = int.parse(parts[0]);
				final m = int.parse(parts[1]);
				final y = int.parse(parts[2]);
				return DateTime(y, m, d);
			}
		} catch (_) {}
		return DateTime.now();
	}
}

