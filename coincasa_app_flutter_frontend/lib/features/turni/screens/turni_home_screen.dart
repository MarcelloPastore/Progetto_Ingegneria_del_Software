// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// // ---------------------------------------------------------------------------
// // MODELLI LOCALI (da sostituire con quelli in lib/core/models/turno.dart)
// // ---------------------------------------------------------------------------

// enum FrequenzaTurno { ogniGiorno, ogniSettimana, ogniMese }

// class Turno {
//   final String id;
//   final String nomeTask;
//   final String responsabileId;
//   final String responsabileNome;
//   final FrequenzaTurno frequenza;
//   final Color colore;
//   final bool completatoQuestaSettimana;

//   const Turno({
//     required this.id,
//     required this.nomeTask,
//     required this.responsabileId,
//     required this.responsabileNome,
//     required this.frequenza,
//     required this.colore,
//     this.completatoQuestaSettimana = false,
//   });
// }

// // ---------------------------------------------------------------------------
// // COSTANTI DI DESIGN (allineate al tema scuro delle schermate Figma)
// // ---------------------------------------------------------------------------

// class _AppColors {
//   static const background = Color(0xFF0F1021);
//   static const surface = Color(0xFF1A1B2E);
//   static const surfaceVariant = Color(0xFF252640);
//   static const primary = Color(0xFF6C63FF);
//   static const primaryLight = Color(0xFF8B85FF);
//   static const accent = Color(0xFF00D4AA);
//   static const textPrimary = Color(0xFFEEEEFF);
//   static const textSecondary = Color(0xFF9090B0);
//   static const divider = Color(0xFF2A2B45);
//   static const error = Color(0xFFFF5370);
//   static const success = Color(0xFF4CAF82);
//   static const warning = Color(0xFFFFB347);

//   static const chipColors = [
//     Color(0xFF6C63FF),
//     Color(0xFF00D4AA),
//     Color(0xFFFF6B9D),
//     Color(0xFFFFB347),
//     Color(0xFF4FC3F7),
//   ];
// }

// // ---------------------------------------------------------------------------
// // DATI MOCK (sostituire con chiamate a turni_api.dart)
// // ---------------------------------------------------------------------------

// final List<Turno> _mockTurni = [
//   Turno(
//     id: '1',
//     nomeTask: 'Pulizie bagno',
//     responsabileId: 'mario',
//     responsabileNome: 'Mario',
//     frequenza: FrequenzaTurno.ogniSettimana,
//     colore: _AppColors.chipColors[0],
//   ),
//   Turno(
//     id: '2',
//     nomeTask: 'Spazzatura',
//     responsabileId: 'luigi',
//     responsabileNome: 'Luigi',
//     frequenza: FrequenzaTurno.ogniGiorno,
//     colore: _AppColors.chipColors[1],
//   ),
//   Turno(
//     id: '3',
//     nomeTask: 'Lavare i piatti',
//     responsabileId: 'sofia',
//     responsabileNome: 'Sofia',
//     frequenza: FrequenzaTurno.ogniSettimana,
//     colore: _AppColors.chipColors[2],
//   ),
//   Turno(
//     id: '4',
//     nomeTask: 'Pulizie cucina',
//     responsabileId: 'mario',
//     responsabileNome: 'Mario',
//     frequenza: FrequenzaTurno.ogniMese,
//     colore: _AppColors.chipColors[3],
//   ),
// ];

// // ---------------------------------------------------------------------------
// // SCHERMATA PRINCIPALE
// // ---------------------------------------------------------------------------

// class TurniHomeScreen extends StatefulWidget {
//   /// ID dell'utente corrente (passato dal routing)
//   final String currentUserId;

//   /// true se l'utente e admin della casa
//   final bool isAdmin;

//   const TurniHomeScreen({
//     super.key,
//     required this.currentUserId,
//     this.isAdmin = false,
//   });

//   @override
//   State<TurniHomeScreen> createState() => _TurniHomeScreenState();
// }

// class _TurniHomeScreenState extends State<TurniHomeScreen>
//     with TickerProviderStateMixin {
//   // Stato calendario
//   late DateTime _focusedMonth;
//   DateTime? _selectedDay;

//   // Stato dati
//   List<Turno> _turni = [];
//   bool _isLoading = true;
//   String? _errorMessage;

//   // Animazione
//   late AnimationController _fadeCtrl;
//   late Animation<double> _fadeAnim;

//   @override
//   void initState() {
//     super.initState();
//     _focusedMonth = DateTime.now();
//     _selectedDay = DateTime.now();

//     _fadeCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );
//     _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

//     _loadTurni();
//   }

//   @override
//   void dispose() {
//     _fadeCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _loadTurni() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//     // TODO: sostituire con chiamata reale a TurniApi
//     await Future.delayed(const Duration(milliseconds: 600));
//     setState(() {
//       _turni = _mockTurni;
//       _isLoading = false;
//     });
//     _fadeCtrl.forward(from: 0);
//   }

//   // Restituisce i turni del giorno selezionato (mock: tutti i giorni hanno turni)
//   List<Turno> get _turniDelGiorno => _turni;

//   String _frequenzaLabel(FrequenzaTurno f) {
//     switch (f) {
//       case FrequenzaTurno.ogniGiorno:
//         return 'Ogni giorno';
//       case FrequenzaTurno.ogniSettimana:
//         return 'Ogni settimana';
//       case FrequenzaTurno.ogniMese:
//         return 'Ogni mese';
//     }
//   }

//   // ---------------------------------------------------------------------------
//   // BUILD
//   // ---------------------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _AppColors.background,
//       body: SafeArea(
//         child: Column(
//           children: [
//             _buildTopBar(),
//             Expanded(
//               child: _isLoading
//                   ? _buildLoader()
//                   : _errorMessage != null
//                   ? _buildErrorState()
//                   : FadeTransition(opacity: _fadeAnim, child: _buildContent()),
//             ),
//             _buildBottomButton(),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // TOP BAR
//   // ---------------------------------------------------------------------------

//   Widget _buildTopBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: const BoxDecoration(
//         color: _AppColors.surface,
//         border: Border(bottom: BorderSide(color: _AppColors.divider, width: 1)),
//       ),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () => Navigator.of(context).maybePop(),
//             child: Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: _AppColors.surfaceVariant,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(
//                 Icons.arrow_back_ios_new_rounded,
//                 color: _AppColors.textSecondary,
//                 size: 16,
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           // House icon + name
//           Container(
//             width: 32,
//             height: 32,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 colors: [_AppColors.primary, _AppColors.primaryLight],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(
//               Icons.house_rounded,
//               color: Colors.white,
//               size: 18,
//             ),
//           ),
//           const SizedBox(width: 10),
//           const Text(
//             'Casa Verdi',
//             style: TextStyle(
//               color: _AppColors.textPrimary,
//               fontSize: 17,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 0.2,
//             ),
//           ),
//           const Spacer(),
//           if (widget.isAdmin)
//             GestureDetector(
//               onTap: _navigateToNuovoTurno,
//               child: Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: _AppColors.primary.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: const Icon(
//                   Icons.add_rounded,
//                   color: _AppColors.primaryLight,
//                   size: 20,
//                 ),
//               ),
//             ),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: () {
//               /* TODO: impostazioni */
//             },
//             child: Container(
//               width: 36,
//               height: 36,
//               decoration: BoxDecoration(
//                 color: _AppColors.surfaceVariant,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(
//                 Icons.settings_rounded,
//                 color: _AppColors.textSecondary,
//                 size: 18,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // CONTENT
//   // ---------------------------------------------------------------------------

//   Widget _buildContent() {
//     return CustomScrollView(
//       physics: const BouncingScrollPhysics(),
//       slivers: [
//         SliverToBoxAdapter(child: _buildCalendarSection()),
//         SliverToBoxAdapter(child: _buildSectionHeader()),
//         SliverList(
//           delegate: SliverChildBuilderDelegate(
//             (context, index) => _buildTurnoCard(_turniDelGiorno[index], index),
//             childCount: _turniDelGiorno.length,
//           ),
//         ),
//         const SliverToBoxAdapter(child: SizedBox(height: 16)),
//       ],
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // CALENDARIO
//   // ---------------------------------------------------------------------------

//   Widget _buildCalendarSection() {
//     return Container(
//       margin: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: _AppColors.surface,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _AppColors.divider),
//       ),
//       child: Column(
//         children: [
//           _buildCalendarHeader(),
//           _buildCalendarGrid(),
//           const SizedBox(height: 12),
//         ],
//       ),
//     );
//   }

//   Widget _buildCalendarHeader() {
//     final monthName = DateFormat('MMMM yyyy', 'it_IT').format(_focusedMonth);
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
//       child: Row(
//         children: [
//           Text(
//             monthName[0].toUpperCase() + monthName.substring(1),
//             style: const TextStyle(
//               color: _AppColors.textPrimary,
//               fontSize: 15,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const Spacer(),
//           _calNavBtn(Icons.chevron_left_rounded, () {
//             setState(() {
//               _focusedMonth = DateTime(
//                 _focusedMonth.year,
//                 _focusedMonth.month - 1,
//               );
//             });
//           }),
//           const SizedBox(width: 4),
//           _calNavBtn(Icons.chevron_right_rounded, () {
//             setState(() {
//               _focusedMonth = DateTime(
//                 _focusedMonth.year,
//                 _focusedMonth.month + 1,
//               );
//             });
//           }),
//         ],
//       ),
//     );
//   }

//   Widget _calNavBtn(IconData icon, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: 30,
//         height: 30,
//         decoration: BoxDecoration(
//           color: _AppColors.surfaceVariant,
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Icon(icon, color: _AppColors.textSecondary, size: 18),
//       ),
//     );
//   }

//   Widget _buildCalendarGrid() {
//     const weekdays = ['Lu', 'Ma', 'Me', 'Gi', 'Ve', 'Sa', 'Do'];
//     final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
//     final daysInMonth = DateTime(
//       _focusedMonth.year,
//       _focusedMonth.month + 1,
//       0,
//     ).day;
//     // weekday: 1=Mon ... 7=Sun -> offset 0-based
//     final startOffset = (firstDay.weekday - 1) % 7;

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       child: Column(
//         children: [
//           // Intestazione giorni
//           Row(
//             children: weekdays
//                 .map(
//                   (d) => Expanded(
//                     child: Center(
//                       child: Text(
//                         d,
//                         style: const TextStyle(
//                           color: _AppColors.textSecondary,
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 )
//                 .toList(),
//           ),
//           const SizedBox(height: 6),
//           // Griglia giorni
//           GridView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//               crossAxisCount: 7,
//               childAspectRatio: 1,
//               mainAxisSpacing: 4,
//               crossAxisSpacing: 2,
//             ),
//             itemCount: startOffset + daysInMonth,
//             itemBuilder: (context, index) {
//               if (index < startOffset) return const SizedBox.shrink();
//               final day = index - startOffset + 1;
//               final date = DateTime(
//                 _focusedMonth.year,
//                 _focusedMonth.month,
//                 day,
//               );
//               final isToday = _isSameDay(date, DateTime.now());
//               final isSelected =
//                   _selectedDay != null && _isSameDay(date, _selectedDay!);
//               // Mock: giorni con turni = ogni 3 giorni
//               final hasTurno = day % 3 == 0;

//               return GestureDetector(
//                 onTap: () => setState(() => _selectedDay = date),
//                 child: _CalendarDay(
//                   day: day,
//                   isToday: isToday,
//                   isSelected: isSelected,
//                   hasTurno: hasTurno,
//                   turnoColor: hasTurno
//                       ? _AppColors.chipColors[day %
//                             _AppColors.chipColors.length]
//                       : null,
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   bool _isSameDay(DateTime a, DateTime b) =>
//       a.year == b.year && a.month == b.month && a.day == b.day;

//   // ---------------------------------------------------------------------------
//   // SEZIONE TURNI ASSEGNATI
//   // ---------------------------------------------------------------------------

//   Widget _buildSectionHeader() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
//       child: Row(
//         children: [
//           const Text(
//             'Turni assegnati',
//             style: TextStyle(
//               color: _AppColors.textPrimary,
//               fontSize: 16,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const Spacer(),
//           if (_selectedDay != null)
//             Text(
//               DateFormat('d MMM', 'it_IT').format(_selectedDay!),
//               style: const TextStyle(
//                 color: _AppColors.textSecondary,
//                 fontSize: 13,
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTurnoCard(Turno turno, int index) {
//     final isMine = turno.responsabileId == widget.currentUserId;

//     return GestureDetector(
//       onTap: () => _showTurnoDetail(turno),
//       child: Container(
//         margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
//         decoration: BoxDecoration(
//           color: _AppColors.surface,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isMine ? turno.colore.withOpacity(0.5) : _AppColors.divider,
//           ),
//         ),
//         child: Row(
//           children: [
//             // Bordo sinistro colorato
//             Container(
//               width: 4,
//               height: 64,
//               decoration: BoxDecoration(
//                 color: turno.colore,
//                 borderRadius: const BorderRadius.only(
//                   topLeft: Radius.circular(14),
//                   bottomLeft: Radius.circular(14),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 14),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             turno.nomeTask,
//                             style: const TextStyle(
//                               color: _AppColors.textPrimary,
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ),
//                         if (isMine)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 8,
//                               vertical: 3,
//                             ),
//                             decoration: BoxDecoration(
//                               color: _AppColors.accent.withOpacity(0.15),
//                               borderRadius: BorderRadius.circular(20),
//                             ),
//                             child: const Text(
//                               'Il tuo',
//                               style: TextStyle(
//                                 color: _AppColors.accent,
//                                 fontSize: 11,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         _InfoChip(
//                           icon: Icons.person_outline_rounded,
//                           label: turno.responsabileNome,
//                           color: turno.colore,
//                         ),
//                         const SizedBox(width: 8),
//                         _InfoChip(
//                           icon: Icons.repeat_rounded,
//                           label: _frequenzaLabel(turno.frequenza),
//                           color: _AppColors.textSecondary,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.only(right: 14),
//               child: Icon(
//                 Icons.chevron_right_rounded,
//                 color: _AppColors.textSecondary,
//                 size: 20,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // BOTTONE INFERIORE
//   // ---------------------------------------------------------------------------

//   Widget _buildBottomButton() {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
//       decoration: const BoxDecoration(
//         color: _AppColors.surface,
//         border: Border(top: BorderSide(color: _AppColors.divider)),
//       ),
//       child: SizedBox(
//         width: double.infinity,
//         height: 52,
//         child: ElevatedButton.icon(
//           onPressed: _navigateToInserisciTurno,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: _AppColors.primary,
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(14),
//             ),
//             elevation: 0,
//           ),
//           icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
//           label: const Text(
//             'Inserisci turno',
//             style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
//           ),
//         ),
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // STATI: LOADER / ERRORE
//   // ---------------------------------------------------------------------------

//   Widget _buildLoader() {
//     return const Center(
//       child: CircularProgressIndicator(
//         valueColor: AlwaysStoppedAnimation(_AppColors.primary),
//         strokeWidth: 2.5,
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 72,
//               height: 72,
//               decoration: BoxDecoration(
//                 color: _AppColors.surfaceVariant,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.wifi_off_rounded,
//                 color: _AppColors.textSecondary,
//                 size: 32,
//               ),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Nessuna connessione',
//               style: TextStyle(
//                 color: _AppColors.textPrimary,
//                 fontSize: 18,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _errorMessage ??
//                   'Non e possibile completare la richiesta.\nControlla la connessione e riprova.',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 color: _AppColors.textSecondary,
//                 fontSize: 14,
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 28),
//             SizedBox(
//               width: 180,
//               height: 46,
//               child: ElevatedButton(
//                 onPressed: _loadTurni,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _AppColors.primary,
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: const Text(
//                   'Riprova',
//                   style: TextStyle(fontWeight: FontWeight.w700),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // BOTTOM SHEET DETTAGLIO TURNO
//   // ---------------------------------------------------------------------------

//   void _showTurnoDetail(Turno turno) {
//     final isMine = turno.responsabileId == widget.currentUserId;
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _TurnoDetailSheet(
//         turno: turno,
//         isMine: isMine,
//         isAdmin: widget.isAdmin,
//         frequenzaLabel: _frequenzaLabel(turno.frequenza),
//         onRemove: widget.isAdmin
//             ? () {
//                 Navigator.pop(context);
//                 setState(() => _turni.removeWhere((t) => t.id == turno.id));
//                 _showSnack('Turno rimosso');
//               }
//             : null,
//       ),
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // NAVIGAZIONE
//   // ---------------------------------------------------------------------------

//   void _navigateToNuovoTurno() {
//     Navigator.of(context).pushNamed('/turni/nuovo');
//   }

//   void _navigateToInserisciTurno() {
//     Navigator.of(context).pushNamed('/turni/inserisci');
//   }

//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: _AppColors.surfaceVariant,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }
// }

// // ---------------------------------------------------------------------------
// // WIDGET GIORNO CALENDARIO
// // ---------------------------------------------------------------------------

// class _CalendarDay extends StatelessWidget {
//   final int day;
//   final bool isToday;
//   final bool isSelected;
//   final bool hasTurno;
//   final Color? turnoColor;

//   const _CalendarDay({
//     required this.day,
//     required this.isToday,
//     required this.isSelected,
//     required this.hasTurno,
//     this.turnoColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     Color bg = Colors.transparent;
//     Color textColor = _AppColors.textPrimary;

//     if (isSelected) {
//       bg = _AppColors.primary;
//       textColor = Colors.white;
//     } else if (isToday) {
//       bg = _AppColors.primary.withOpacity(0.2);
//       textColor = _AppColors.primaryLight;
//     }

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 32,
//           height: 32,
//           decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
//           alignment: Alignment.center,
//           child: Text(
//             '$day',
//             style: TextStyle(
//               color: textColor,
//               fontSize: 12,
//               fontWeight: isToday || isSelected
//                   ? FontWeight.w700
//                   : FontWeight.w400,
//             ),
//           ),
//         ),
//         const SizedBox(height: 2),
//         if (hasTurno && turnoColor != null)
//           Container(
//             width: 5,
//             height: 5,
//             decoration: BoxDecoration(
//               color: isSelected ? Colors.white : turnoColor,
//               shape: BoxShape.circle,
//             ),
//           )
//         else
//           const SizedBox(height: 5),
//       ],
//     );
//   }
// }

// // ---------------------------------------------------------------------------
// // WIDGET CHIP INFO
// // ---------------------------------------------------------------------------

// class _InfoChip extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;

//   const _InfoChip({
//     required this.icon,
//     required this.label,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 12, color: color),
//         const SizedBox(width: 3),
//         Text(
//           label,
//           style: TextStyle(
//             color: color,
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ---------------------------------------------------------------------------
// // BOTTOM SHEET DETTAGLIO TURNO
// // ---------------------------------------------------------------------------

// class _TurnoDetailSheet extends StatefulWidget {
//   final Turno turno;
//   final bool isMine;
//   final bool isAdmin;
//   final String frequenzaLabel;
//   final VoidCallback? onRemove;

//   const _TurnoDetailSheet({
//     required this.turno,
//     required this.isMine,
//     required this.isAdmin,
//     required this.frequenzaLabel,
//     this.onRemove,
//   });

//   @override
//   State<_TurnoDetailSheet> createState() => _TurnoDetailSheetState();
// }

// class _TurnoDetailSheetState extends State<_TurnoDetailSheet> {
//   bool _completato = false;
//   bool _showRemoveConfirm = false;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: const BoxDecoration(
//         color: _AppColors.surface,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//       ),
//       padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Handle
//           Center(
//             child: Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: _AppColors.divider,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Titolo
//           Row(
//             children: [
//               Container(
//                 width: 10,
//                 height: 10,
//                 decoration: BoxDecoration(
//                   color: widget.turno.colore,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               const Text(
//                 'Dettagli turno',
//                 style: TextStyle(
//                   color: _AppColors.textSecondary,
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             widget.turno.nomeTask,
//             style: const TextStyle(
//               color: _AppColors.textPrimary,
//               fontSize: 22,
//               fontWeight: FontWeight.w800,
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Info rows
//           _DetailRow(
//             icon: Icons.person_outline_rounded,
//             label: 'Responsabile',
//             value: widget.turno.responsabileNome,
//             color: widget.turno.colore,
//           ),
//           const SizedBox(height: 12),
//           _DetailRow(
//             icon: Icons.repeat_rounded,
//             label: 'Frequenza',
//             value: widget.frequenzaLabel,
//             color: _AppColors.textSecondary,
//           ),
//           const SizedBox(height: 20),

//           // Toggle completato (solo per il responsabile)
//           if (widget.isMine) ...[
//             Container(
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: _AppColors.surfaceVariant,
//                 borderRadius: BorderRadius.circular(14),
//                 border: Border.all(color: _AppColors.divider),
//               ),
//               child: Row(
//                 children: [
//                   const Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Turno completato questa settimana?',
//                           style: TextStyle(
//                             color: _AppColors.textPrimary,
//                             fontSize: 13,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         SizedBox(height: 2),
//                         Text(
//                           'Aggiorna lo stato del turno',
//                           style: TextStyle(
//                             color: _AppColors.textSecondary,
//                             fontSize: 11,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   Switch(
//                     value: _completato,
//                     onChanged: (v) => setState(() => _completato = v),
//                     activeColor: _AppColors.accent,
//                     inactiveTrackColor: _AppColors.divider,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],

//           // Bottone admin: rimuovi turno
//           if (widget.isAdmin) ...[
//             if (_showRemoveConfirm) ...[
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: _AppColors.error.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(14),
//                   border: Border.all(color: _AppColors.error.withOpacity(0.3)),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Rimozione turno',
//                       style: TextStyle(
//                         color: _AppColors.error,
//                         fontWeight: FontWeight.w700,
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       'Il turno verra rimosso definitivamente. L\'azione non puo essere annullata.',
//                       style: TextStyle(
//                         color: _AppColors.textSecondary,
//                         fontSize: 13,
//                         height: 1.4,
//                       ),
//                     ),
//                     const SizedBox(height: 14),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: () =>
//                                 setState(() => _showRemoveConfirm = false),
//                             style: OutlinedButton.styleFrom(
//                               foregroundColor: _AppColors.textSecondary,
//                               side: const BorderSide(color: _AppColors.divider),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: const Text('Annulla'),
//                           ),
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: widget.onRemove,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: _AppColors.error,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: const Text('Elimina turno'),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ] else
//               SizedBox(
//                 width: double.infinity,
//                 height: 46,
//                 child: OutlinedButton.icon(
//                   onPressed: () => setState(() => _showRemoveConfirm = true),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: _AppColors.error,
//                     side: BorderSide(color: _AppColors.error.withOpacity(0.5)),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   icon: const Icon(Icons.delete_outline_rounded, size: 18),
//                   label: const Text(
//                     'Rimuovi turno',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//             const SizedBox(height: 12),
//           ],

//           // Bottone torna ai turni
//           SizedBox(
//             width: double.infinity,
//             height: 50,
//             child: ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _AppColors.primary,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 elevation: 0,
//               ),
//               child: const Text(
//                 'Vai ai turni',
//                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _DetailRow extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final String value;
//   final Color color;

//   const _DetailRow({
//     required this.icon,
//     required this.label,
//     required this.value,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.12),
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Icon(icon, color: color, size: 18),
//         ),
//         const SizedBox(width: 12),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: const TextStyle(
//                 color: _AppColors.textSecondary,
//                 fontSize: 11,
//               ),
//             ),
//             Text(
//               value,
//               style: const TextStyle(
//                 color: _AppColors.textPrimary,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }
