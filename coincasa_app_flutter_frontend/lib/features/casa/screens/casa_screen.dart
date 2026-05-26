// import 'package:flutter/material.dart';

// import 'package:coincasa_app/core/api/api_provider.dart';
// import 'package:coincasa_app/core/models/casa.dart';

// class CasaScreen extends StatefulWidget {
//   const CasaScreen({super.key});

//   @override
//   State<CasaScreen> createState() => _CasaScreenState();
// }

// class _CasaScreenState extends State<CasaScreen> {
//   late final Future<List<Casa>> _future;

//   @override
//   void initState() {
//     super.initState();
//     _future = ApiProvider.casa.list();
//   }

//   Future<void> _showInviteLink(Casa casa) async {
//     try {
//       final link = await ApiProvider.casa.getInviteLink(casa.id);
//       if (!mounted) {
//         return;
//       }

//       showDialog<void>(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text('Invite link'),
//           content: Text(link),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Chiudi'),
//             ),
//           ],
//         ),
//       );
//     } catch (error) {
//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Errore: $error')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Casa')),
//       body: FutureBuilder<List<Casa>>(
//         future: _future,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState != ConnectionState.done) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           if (snapshot.hasError) {
//             return Center(child: Text('Errore: ${snapshot.error}'));
//           }

//           final caseList = snapshot.data ?? const [];
//           if (caseList.isEmpty) {
//             return const Center(child: Text('Nessuna casa trovata.'));
//           }

//           return ListView.separated(
//             padding: const EdgeInsets.all(16),
//             itemBuilder: (context, index) {
//               final casa = caseList[index];
//               return ListTile(
//                 title: Text(casa.nome),
//                 subtitle: Text(casa.indirizzo),
//                 trailing: TextButton(
//                   onPressed: () => _showInviteLink(casa),
//                   child: const Text('Invita'),
//                 ),
//               );
//             },
//             separatorBuilder: (_, __) => const Divider(),
//             itemCount: caseList.length,
//           );
//         },
//       ),
//     );
//   }
// }
