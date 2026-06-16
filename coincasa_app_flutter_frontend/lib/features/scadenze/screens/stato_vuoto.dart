import 'package:flutter/material.dart';

class StatoVuoto extends StatelessWidget {
	const StatoVuoto({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFF09051F),
			body: SafeArea(
				child: Center(
					child: SingleChildScrollView(
						padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								Text(
									'Scadenze',
									style: TextStyle(
										color: const Color(0xFF956FE7),
										fontSize: 32,
										fontWeight: FontWeight.w700,
										fontFamily: 'Inter',
									),
								),
								const SizedBox(height: 24),
								SizedBox(
									width: 176,
									height: 176,
									child: Image.network(
										'https://placehold.co/176x176',
										fit: BoxFit.cover,
									),
								),
								const SizedBox(height: 24),
								Text(
									'Nessuna scadenza',
									style: TextStyle(
										color: const Color(0xFFF6F6F6),
										fontSize: 20,
										fontWeight: FontWeight.w600,
										fontFamily: 'Inter',
									),
								),
								const SizedBox(height: 12),
								Text(
									'Aggiungi affitto, bollette, e utenze per ricevere reminder automatici prima della scadenza',
									textAlign: TextAlign.center,
									style: TextStyle(
										color: const Color(0xFFD8D5D5),
										fontSize: 18,
										fontWeight: FontWeight.w500,
										fontFamily: 'Inter',
									),
								),
								const SizedBox(height: 24),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										onPressed: () {
											
										},
										style: ElevatedButton.styleFrom(
											backgroundColor: const Color(0xFF5228AD),
											padding: const EdgeInsets.symmetric(vertical: 14),
											shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
										),
										child: Text(
											'Aggiungi scadenza',
											style: TextStyle(
												color: const Color(0xFFF2F2F2),
												fontSize: 20,
												fontWeight: FontWeight.w700,
												fontFamily: 'Inter',
											),
										),
									),
								),
							],
						),
					),
				),
			),
		);
	}
}

