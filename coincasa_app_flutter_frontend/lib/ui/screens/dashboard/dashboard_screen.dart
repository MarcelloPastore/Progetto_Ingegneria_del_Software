// import 'package:flutter/material.dart';

// import 'package:coincasa_app/core/api/api_provider.dart';
// import 'package:coincasa_app/core/models/casa.dart';
// import 'package:coincasa_app/core/models/turno.dart';
// import 'package:coincasa_app/ui/widgets/common/info_card.dart';

// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({super.key});

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   late final Future<_DashboardData> _future;

//   @override
//   void initState() {
//     super.initState();
//     _future = _loadDashboard();
//   }

//   Future<_DashboardData> _loadDashboard() async {
//     final caseList = await ApiProvider.casa.list();
//     if (caseList.isEmpty) {
//       return const _DashboardData.empty();
//     }

//     final casa = caseList.first;
//     final results = await Future.wait<dynamic>([
//       ApiProvider.spese.getSaldo(casa.id),
//       ApiProvider.spese.getCreditoTot(casa.id),
//       ApiProvider.spese.getDebitoTot(casa.id),
//       ApiProvider.turni.listOggi(casa.id),
//     ]);

//     return _DashboardData(
//       casa: casa,
//       saldo: results[0] as double,
//       credito: results[1] as double,
//       debito: results[2] as double,
//       turni: results[3] as List<Turno>,
//     );
//   }

//   String _formatAmount(double value) => value.toStringAsFixed(2);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Dashboard')),
//       body: FutureBuilder<_DashboardData>(
//         future: _future,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState != ConnectionState.done) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Errore: ${snapshot.error}'));
//           }

//           final data = snapshot.data ?? const _DashboardData.empty();
//           if (data.casa == null) {
//             return const Center(child: Text('Nessuna casa trovata.'));
//           }

//           return ListView(
//             padding: const EdgeInsets.all(16),
//             children: [
//               Text(
//                 'Casa: ${data.casa!.nome}',
//                 style: Theme.of(context).textTheme.titleLarge,
//               ),
//               const SizedBox(height: 12),
//               InfoCard(
//                 title: 'Saldo',
//                 subtitle: '${_formatAmount(data.saldo)} EUR',
//               ),
//               InfoCard(
//                 title: 'Credito',
//                 subtitle: '${_formatAmount(data.credito)} EUR',
//               ),
//               InfoCard(
//                 title: 'Debito',
//                 subtitle: '${_formatAmount(data.debito)} EUR',
//               ),
//               const SizedBox(height: 16),
//               Text(
//                 'Turni di oggi',
//                 style: Theme.of(context).textTheme.titleMedium,
//               ),
//               const SizedBox(height: 8),
//               if (data.turni.isEmpty)
//                 const Text('Nessun turno per oggi.')
//               else
//                 ...data.turni.map(
//                   (turno) => ListTile(
//                     title: Text(turno.titolo),
//                     subtitle: Text(turno.data?.toIso8601String() ?? ''),
//                   ),
//                 ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }

// class _DashboardData {
//   const _DashboardData({
//     required this.casa,
//     required this.saldo,
//     required this.credito,
//     required this.debito,
//     required this.turni,
//   });

//   const _DashboardData.empty()
//     : casa = null,
//       saldo = 0,
//       credito = 0,
//       debito = 0,
//       turni = const [];

//   final Casa? casa;
//   final double saldo;
//   final double credito;
//   final double debito;
//   final List<Turno> turni;
// }
