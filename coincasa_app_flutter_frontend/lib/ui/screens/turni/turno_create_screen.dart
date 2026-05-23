// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// import 'package:coincasa_app/app.dart';

// class TurnoCreateScreen extends StatefulWidget {
//   const TurnoCreateScreen({super.key});

//   @override
//   State<TurnoCreateScreen> createState() => _TurnoCreateScreenState();
// }

// class _TurnoCreateScreenState extends State<TurnoCreateScreen> {
//   int _selectedSection = 2;
//   bool _rotationEnabled = true;
//   int _navIndex = 0;

//   void _toggleRotation() {
//     setState(() => _rotationEnabled = !_rotationEnabled);
//   }

//   void _onSectionSelected(int index) {
//     setState(() => _selectedSection = index);
//   }

//   void _onNavTap(int index) {
//     if (index == _navIndex) {
//       return;
//     }

//     final route = _routeForIndex(index);
//     if (route == null) {
//       _showNotAvailable();
//       return;
//     }

//     setState(() => _navIndex = index);
//     Navigator.of(context).pushReplacementNamed(route);
//   }

//   String? _routeForIndex(int index) {
//     switch (index) {
//       case 0:
//         return AppRoutes.dashboard;
//       case 1:
//         return AppRoutes.spese;
//       case 2:
//         return AppRoutes.turni;
//     }
//     return null;
//   }

//   void _showNotAvailable() {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('Sezione non disponibile.')));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final baseTheme = Theme.of(context);
//     final textTheme = GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
//       bodyColor: _TurnoFormPalette.textPrimary,
//       displayColor: _TurnoFormPalette.textPrimary,
//     );

//     return Theme(
//       data: baseTheme.copyWith(textTheme: textTheme),
//       child: Scaffold(
//         backgroundColor: _TurnoFormPalette.pageBackground,
//         bottomNavigationBar: _TurnoBottomNav(
//           selectedIndex: _navIndex,
//           onSelected: _onNavTap,
//         ),
//         body: SafeArea(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 14),
//                   child: Row(
//                     children: [
//                       const _HeaderAvatar(icon: Icons.person),
//                       Expanded(
//                         child: Center(
//                           child: Text(
//                             'Casa Verdi',
//                             style: textTheme.titleLarge?.copyWith(
//                               color: _TurnoFormPalette.title,
//                               fontWeight: FontWeight.w800,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const _HeaderAvatar(icon: Icons.group),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 11),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       color: _TurnoFormPalette.surface,
//                       borderRadius: BorderRadius.circular(15),
//                       border: Border.all(
//                         color: _TurnoFormPalette.accent,
//                         width: 3,
//                       ),
//                       boxShadow: const [
//                         BoxShadow(
//                           color: _TurnoFormPalette.shadow,
//                           blurRadius: 4,
//                           offset: Offset(0, 4),
//                         ),
//                       ],
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           _ContentSwitcher(
//                             selectedIndex: _selectedSection,
//                             onSelected: _onSectionSelected,
//                           ),
//                           const SizedBox(height: 18),
//                           Text(
//                             'Nuovo Turno',
//                             style: textTheme.titleLarge?.copyWith(
//                               color: _TurnoFormPalette.title,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           const SizedBox(height: 14),
//                           _TextFieldBox(
//                             hintText: 'Nome task...',
//                             borderColor: _TurnoFormPalette.fieldBorder,
//                           ),
//                           const SizedBox(height: 18),
//                           _DateFieldBox(textTheme: textTheme),
//                           const SizedBox(height: 18),
//                           Text(
//                             'Frequenza',
//                             style: textTheme.titleMedium?.copyWith(
//                               color: _TurnoFormPalette.title,
//                               fontWeight: FontWeight.w700,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           _DropdownBox(textTheme: textTheme),
//                           const SizedBox(height: 16),
//                           _AssigneeCard(
//                             rotationEnabled: _rotationEnabled,
//                             onToggleRotation: _toggleRotation,
//                           ),
//                           const SizedBox(height: 18),
//                           _PrimaryActionButton(
//                             label: 'Salva Turno',
//                             onPressed: () {},
//                           ),
//                           const SizedBox(height: 10),
//                           _SecondaryActionButton(
//                             label: 'Annulla',
//                             onPressed: () {},
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _ContentSwitcher extends StatelessWidget {
//   const _ContentSwitcher({
//     required this.selectedIndex,
//     required this.onSelected,
//   });

//   final int selectedIndex;
//   final ValueChanged<int> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     final labels = const ['Spesa', 'Problema', 'Turno', 'Scadenza'];

//     return Container(
//       padding: const EdgeInsets.all(4),
//       decoration: BoxDecoration(
//         color: _TurnoFormPalette.switcherBackground,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: _TurnoFormPalette.accent),
//         boxShadow: const [
//           BoxShadow(
//             color: _TurnoFormPalette.shadow,
//             blurRadius: 4,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: List.generate(labels.length * 2 - 1, (index) {
//           if (index.isOdd) {
//             return Container(
//               width: 1,
//               height: 12,
//               color: _TurnoFormPalette.switcherDivider,
//             );
//           }

//           final itemIndex = index ~/ 2;
//           final isSelected = itemIndex == selectedIndex;
//           return Expanded(
//             child: GestureDetector(
//               onTap: () => onSelected(itemIndex),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 decoration: BoxDecoration(
//                   color: isSelected ? _TurnoFormPalette.accent : null,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   labels[itemIndex],
//                   textAlign: TextAlign.center,
//                   style: Theme.of(context).textTheme.labelLarge?.copyWith(
//                     fontWeight: FontWeight.w700,
//                     color: isSelected
//                         ? Colors.white
//                         : _TurnoFormPalette.switcherText,
//                   ),
//                 ),
//               ),
//             ),
//           );
//         }),
//       ),
//     );
//   }
// }

// class _HeaderAvatar extends StatelessWidget {
//   const _HeaderAvatar({required this.icon});

//   final IconData icon;

//   @override
//   Widget build(BuildContext context) {
//     return Opacity(
//       opacity: 0.5,
//       child: CircleAvatar(
//         radius: 24,
//         backgroundColor: _TurnoFormPalette.avatarBackground,
//         child: Icon(icon, size: 26, color: _TurnoFormPalette.avatarIcon),
//       ),
//     );
//   }
// }

// class _TextFieldBox extends StatelessWidget {
//   const _TextFieldBox({required this.hintText, this.borderColor});

//   final String hintText;
//   final Color? borderColor;

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return TextField(
//       style: textTheme.bodyLarge?.copyWith(
//         color: _TurnoFormPalette.textLight,
//         fontWeight: FontWeight.w500,
//       ),
//       decoration: InputDecoration(
//         hintText: hintText,
//         hintStyle: textTheme.bodyLarge?.copyWith(
//           color: _TurnoFormPalette.textMuted,
//           fontWeight: FontWeight.w500,
//         ),
//         filled: true,
//         fillColor: _TurnoFormPalette.fieldBackground,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 12,
//           vertical: 12,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(
//             color: borderColor ?? Colors.transparent,
//             width: borderColor == null ? 1 : 2,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide(
//             color: borderColor ?? _TurnoFormPalette.accent,
//             width: borderColor == null ? 1.5 : 2,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _DateFieldBox extends StatelessWidget {
//   const _DateFieldBox({required this.textTheme});

//   final TextTheme textTheme;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: _TurnoFormPalette.fieldBackground,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(
//             color: _TurnoFormPalette.shadow,
//             blurRadius: 4,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           _MiniSelect(label: 'gg...'),
//           const SizedBox(width: 8),
//           _MiniSelect(label: 'MM...'),
//           const Spacer(),
//           Text(
//             'Data turno',
//             style: textTheme.titleMedium?.copyWith(
//               color: _TurnoFormPalette.textMuted,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MiniSelect extends StatelessWidget {
//   const _MiniSelect({required this.label});

//   final String label;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: _TurnoFormPalette.accent,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: _TurnoFormPalette.selectBorder),
//       ),
//       child: Text(
//         label,
//         style: Theme.of(
//           context,
//         ).textTheme.bodyMedium?.copyWith(color: _TurnoFormPalette.textMuted),
//       ),
//     );
//   }
// }

// class _DropdownBox extends StatelessWidget {
//   const _DropdownBox({required this.textTheme});

//   final TextTheme textTheme;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: _TurnoFormPalette.dropdownBackground,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: _TurnoFormPalette.dropdownBorder),
//         boxShadow: const [
//           BoxShadow(
//             color: _TurnoFormPalette.shadow,
//             blurRadius: 4,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Text(
//             'Ogni settimana',
//             style: textTheme.titleMedium?.copyWith(
//               color: _TurnoFormPalette.textMuted,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           const Spacer(),
//           Container(
//             padding: const EdgeInsets.all(2),
//             decoration: BoxDecoration(
//               color: _TurnoFormPalette.fieldBackground.withOpacity(0.7),
//               borderRadius: BorderRadius.circular(4),
//             ),
//             child: const Icon(
//               Icons.keyboard_arrow_down,
//               size: 18,
//               color: _TurnoFormPalette.textMuted,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _AssigneeCard extends StatelessWidget {
//   const _AssigneeCard({
//     required this.rotationEnabled,
//     required this.onToggleRotation,
//   });

//   final bool rotationEnabled;
//   final VoidCallback onToggleRotation;

//   @override
//   Widget build(BuildContext context) {
//     final textTheme = Theme.of(context).textTheme;

//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: _TurnoFormPalette.fieldBackground,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: const [
//           BoxShadow(
//             color: _TurnoFormPalette.shadow,
//             blurRadius: 4,
//             offset: Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Assegnatario',
//             style: textTheme.labelLarge?.copyWith(
//               color: _TurnoFormPalette.textHint,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//           const SizedBox(height: 10),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             decoration: BoxDecoration(
//               color: _TurnoFormPalette.assignBackground,
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(
//                 color: _TurnoFormPalette.assignBorder,
//                 width: 2,
//               ),
//               boxShadow: const [
//                 BoxShadow(
//                   color: _TurnoFormPalette.shadow,
//                   blurRadius: 4,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.back_hand,
//                   size: 22,
//                   color: _TurnoFormPalette.assignText,
//                 ),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Assegna a me',
//                   style: textTheme.bodyLarge?.copyWith(
//                     color: _TurnoFormPalette.assignText,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               Text(
//                 'Rotazione automatica',
//                 style: textTheme.bodyMedium?.copyWith(
//                   color: _TurnoFormPalette.textMuted,
//                   fontStyle: FontStyle.italic,
//                   decoration: TextDecoration.underline,
//                 ),
//               ),
//               const Spacer(),
//               _RotationToggle(value: rotationEnabled, onTap: onToggleRotation),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _RotationToggle extends StatelessWidget {
//   const _RotationToggle({required this.value, required this.onTap});

//   final bool value;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         width: 63,
//         height: 30,
//         padding: const EdgeInsets.all(2),
//         decoration: BoxDecoration(
//           color: _TurnoFormPalette.toggleTrack,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: const [
//             BoxShadow(
//               color: _TurnoFormPalette.shadow,
//               blurRadius: 4,
//               offset: Offset(0, 4),
//             ),
//           ],
//         ),
//         child: AnimatedAlign(
//           duration: const Duration(milliseconds: 200),
//           alignment: value ? Alignment.centerRight : Alignment.centerLeft,
//           child: Container(
//             width: 30,
//             height: 30,
//             decoration: BoxDecoration(
//               color: _TurnoFormPalette.toggleKnob,
//               shape: BoxShape.circle,
//               boxShadow: const [
//                 BoxShadow(
//                   color: _TurnoFormPalette.toggleShadow,
//                   blurRadius: 3,
//                   offset: Offset(0, 1),
//                 ),
//                 BoxShadow(
//                   color: _TurnoFormPalette.toggleShadowStrong,
//                   blurRadius: 2,
//                   offset: Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Icon(
//               Icons.check,
//               size: 16,
//               color: value ? _TurnoFormPalette.accent : Colors.transparent,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _PrimaryActionButton extends StatelessWidget {
//   const _PrimaryActionButton({required this.label, required this.onPressed});

//   final String label;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         onPressed: onPressed,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _TurnoFormPalette.accent,
//           foregroundColor: Colors.white,
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           textStyle: Theme.of(
//             context,
//           ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//         ),
//         child: Text(label),
//       ),
//     );
//   }
// }

// class _SecondaryActionButton extends StatelessWidget {
//   const _SecondaryActionButton({required this.label, required this.onPressed});

//   final String label;
//   final VoidCallback onPressed;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: OutlinedButton(
//         onPressed: onPressed,
//         style: OutlinedButton.styleFrom(
//           foregroundColor: _TurnoFormPalette.danger,
//           backgroundColor: _TurnoFormPalette.dangerBackground,
//           side: const BorderSide(color: _TurnoFormPalette.danger, width: 2),
//           padding: const EdgeInsets.symmetric(vertical: 14),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20),
//           ),
//           textStyle: Theme.of(
//             context,
//           ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
//         ),
//         child: Text(label),
//       ),
//     );
//   }
// }

// class _TurnoBottomNav extends StatelessWidget {
//   const _TurnoBottomNav({
//     required this.selectedIndex,
//     required this.onSelected,
//   });

//   final int selectedIndex;
//   final ValueChanged<int> onSelected;

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Container(
//         height: 88,
//         margin: const EdgeInsets.fromLTRB(0, 6, 0, 0),
//         decoration: BoxDecoration(
//           color: _TurnoFormPalette.navBackground,
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             _NavItem(
//               label: 'Home',
//               assetPath: 'lib/ui/Icons/home.png',
//               isActive: selectedIndex == 0,
//               onTap: () => onSelected(0),
//             ),
//             _NavItem(
//               label: 'Spese',
//               assetPath: 'lib/ui/Icons/spese.png',
//               isActive: selectedIndex == 1,
//               onTap: () => onSelected(1),
//             ),
//             _NavItem(
//               label: 'Turni',
//               assetPath: 'lib/ui/Icons/turni.png',
//               isActive: selectedIndex == 2,
//               onTap: () => onSelected(2),
//             ),
//             _NavItem(
//               label: 'Scadenze',
//               assetPath: 'lib/ui/Icons/reminder.png',
//               isActive: selectedIndex == 3,
//               onTap: () => onSelected(3),
//             ),
//             _NavItem(
//               label: 'Problemi',
//               assetPath: 'lib/ui/Icons/problemi.png',
//               isActive: selectedIndex == 4,
//               onTap: () => onSelected(4),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _NavItem extends StatelessWidget {
//   const _NavItem({
//     required this.label,
//     required this.assetPath,
//     required this.isActive,
//     required this.onTap,
//   });

//   final String label;
//   final String assetPath;
//   final bool isActive;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     final color = isActive
//         ? _TurnoFormPalette.navActive
//         : _TurnoFormPalette.navInactive;

//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Image.asset(assetPath, width: 30, height: 30, fit: BoxFit.contain),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             style: Theme.of(context).textTheme.labelMedium?.copyWith(
//               color: color,
//               fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _TurnoFormPalette {
//   static const pageBackground = Color(0xFFF3EEFB);
//   static const surface = Color(0xFFFFFFFF);
//   static const accent = Color(0xFF996CFA);
//   static const title = Color(0xFF5228AD);
//   static const textPrimary = Color(0xFF2B2340);
//   static const textLight = Color(0xFFC9C9C9);
//   static const textMuted = Color(0xFFC9C9C9);
//   static const textHint = Color(0xFFA9A9A9);
//   static const fieldBackground = Color(0xFF2C2846);
//   static const fieldBorder = Color(0xFF9B9B9B);
//   static const selectBorder = Color(0xFFD9D9D9);
//   static const dropdownBackground = Color(0xFF29263E);
//   static const dropdownBorder = Color(0x19000000);
//   static const assignBackground = Color(0xFF32422E);
//   static const assignBorder = Color(0xFF56961D);
//   static const assignText = Color(0xFF78DE6B);
//   static const toggleTrack = Color(0xFF797979);
//   static const toggleKnob = Color(0xFFFCFCFD);
//   static const toggleShadow = Color(0x1A101828);
//   static const toggleShadowStrong = Color(0x0F101828);
//   static const switcherBackground = Color(0xFFCFCFCF);
//   static const switcherText = Color(0xFF797979);
//   static const switcherDivider = Color(0xFFBDBDBD);
//   static const navBackground = Color(0xFF16223D);
//   static const navActive = Color(0xFF4796EA);
//   static const navInactive = Color(0xFFC9C9C9);
//   static const danger = Color(0xFFFF203B);
//   static const dangerBackground = Color(0xFF431F24);
//   static const avatarBackground = Color(0xFFE6DFF6);
//   static const avatarIcon = Color(0xFF6C5CF6);
//   static const shadow = Color(0x40000000);
// }
