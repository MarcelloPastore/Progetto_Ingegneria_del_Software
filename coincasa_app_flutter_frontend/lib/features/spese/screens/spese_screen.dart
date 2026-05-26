// import 'package:flutter/material.dart';

// import 'package:coincasa_app/core/api/api_provider.dart';
// import 'package:coincasa_app/core/models/casa.dart';
// import 'package:coincasa_app/core/models/spesa.dart';

// class SpeseScreen extends StatefulWidget {
//   const SpeseScreen({super.key, this.casaId});

//   final String? casaId;

//   @override
//   State<SpeseScreen> createState() => _SpeseScreenState();
// }

// class _SpeseScreenState extends State<SpeseScreen> {
//   late final Future<_SpeseData> _future;

//   @override
//   void initState() {
//     super.initState();
//     _future = _loadSpese();
//   }

//   Future<_SpeseData> _loadSpese() async {
//     final caseList = await ApiProvider.casa.list();
//     if (caseList.isEmpty) {
//       return const _SpeseData.empty();
//     }

//     Casa casa;
//     if (widget.casaId == null) {
//       casa = caseList.first;
//     } else {
//       casa = await ApiProvider.casa.getById(widget.casaId!);
//     }

//     final spese = await ApiProvider.spese.list(casa.id);
//     return _SpeseData(casa: casa, spese: spese);
//   }

//   String _formatAmount(double value) => value.toStringAsFixed(2);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Spese')),
//       body: FutureBuilder<_SpeseData>(
//         future: _future,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState != ConnectionState.done) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Errore: ${snapshot.error}'));
//           }

//           final data = snapshot.data ?? const _SpeseData.empty();
//           if (data.casa == null) {
//             return const Center(child: Text('Nessuna casa trovata.'));
//           }

//           if (data.spese.isEmpty) {
//             return Center(child: Text('Nessuna spesa per ${data.casa!.nome}.'));
//           }

//           return ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemBuilder: (context, index) {
//               final spesa = data.spese[index];
//               return ListTile(
//                 title: Text(spesa.descrizione),
//                 subtitle: Text(spesa.data.toIso8601String()),
//                 trailing: Text('${_formatAmount(spesa.importo)} EUR'),
//               );
//             },
//             separatorBuilder: (_, __) => const Divider(),
//             itemCount: data.spese.length,
//           );
//         },
//       ),
//     );
//   }
// }

// class _SpeseData {
//   const _SpeseData({required this.casa, required this.spese});

//   const _SpeseData.empty() : casa = null, spese = const [];

//   final Casa? casa;
//   final List<Spesa> spese;
// }
