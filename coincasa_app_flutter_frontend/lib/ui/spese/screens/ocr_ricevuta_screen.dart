import 'package:flutter/material.dart';

import 'package:coincasa_app/core/theme/app_theme.dart';
import 'package:coincasa_app/core/widgets/common/common_widgets.dart';

class OcrMockDati {
  const OcrMockDati({
    required this.importo,
    required this.descrizione,
    required this.data,
  });

  final String importo;
  final String descrizione;
  final DateTime data;
}

class OcrRicevutaScreen extends StatefulWidget {
  const OcrRicevutaScreen({super.key});

  static const String routeName = '/spese/ocr-ricevuta';

  @override
  State<OcrRicevutaScreen> createState() => _OcrRicevutaScreenState();
}

class _OcrRicevutaScreenState extends State<OcrRicevutaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;
  bool _scanCompleted = false;

  static const _receiptHeight = 260.0;
  static const _mockImporto = '18.40';
  static const _mockDescrizione = 'Spesa condivisa – Supermercato';

  @override
  void initState() {
    super.initState();
    _scanCtrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut),
    );
    _scanCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _scanCompleted = true);
      }
    });
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _scanCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    super.dispose();
  }

  void _useData() {
    Navigator.of(context).pop(
      OcrMockDati(
        importo: _mockImporto,
        descrizione: _mockDescrizione,
        data: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppSizes.p24),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.p32,
                      ),
                      child: SizedBox(
                        height: _receiptHeight,
                        child: Stack(
                          children: [
                            const _ReceiptMockWidget(height: _receiptHeight),
                            AnimatedBuilder(
                              animation: _scanAnim,
                              builder: (context, _) {
                                if (_scanCompleted) {
                                  return const SizedBox.shrink();
                                }
                                final top =
                                    _scanAnim.value * (_receiptHeight - 3);
                                return Positioned(
                                  top: top,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.brandAccent.withValues(
                                            alpha: 0,
                                          ),
                                          AppColors.brandAccent,
                                          AppColors.brandAccent.withValues(
                                            alpha: 0,
                                          ),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brandAccent
                                              .withValues(alpha: 0.55),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.p20),
                    if (_scanCompleted)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.p24,
                        ),
                        child: _DatiRiconosciutiCard(
                          importo: _mockImporto,
                          descrizione: _mockDescrizione,
                          data: DateTime.now(),
                        ),
                      )
                    else
                      Text(
                        'Analisi in corso...',
                        style: AppTextStyles.screenTitleStrong.copyWith(
                          color: AppColors.textMuted,
                          fontSize: AppSizes.p14,
                        ),
                      ),
                    const SizedBox(height: AppSizes.p80),
                  ],
                ),
              ),
            ),
            if (_scanCompleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.p16,
                  AppSizes.p8,
                  AppSizes.p16,
                  AppSizes.p16,
                ),
                child: MainCtaButton(
                  label: 'Usa questi dati',
                  onPressed: _useData,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.p16,
        AppSizes.p16,
        AppSizes.p16,
        AppSizes.p8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.brandAccent,
              size: AppSizes.p20,
            ),
          ),
          const SizedBox(width: AppSizes.p12),
          Text(
            'Scansiona ricevuta',
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Receipt mock — paper-style card built entirely with Flutter widgets
// ---------------------------------------------------------------------------

class _ReceiptMockWidget extends StatelessWidget {
  const _ReceiptMockWidget({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radius8),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.p14,
            AppSizes.p14,
            AppSizes.p14,
            AppSizes.p10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ESSELUNGA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF1E1B2E),
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              SizedBox(height: AppSizes.p2),
              Text(
                'Via Roma, 15 – Milano',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8D889C), fontSize: 9),
              ),
              Divider(height: 18, color: Color(0xFFD6D2E6)),
              _ReceiptLine(label: 'Pasta 500g', value: '€ 1,59'),
              _ReceiptLine(label: 'Latte intero', value: '€ 2,10'),
              _ReceiptLine(label: 'Pane casereccio', value: '€ 2,80'),
              _ReceiptLine(label: 'Verdura mista', value: '€ 5,30'),
              _ReceiptLine(label: 'Succo di frutta', value: '€ 4,20'),
              _ReceiptLine(label: 'Biscotti assortiti', value: '€ 2,41'),
              Divider(height: 16, color: Color(0xFFD6D2E6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTALE',
                    style: TextStyle(
                      color: Color(0xFF1E1B2E),
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    '€ 18,40',
                    style: TextStyle(
                      color: Color(0xFF1E1B2E),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  const _ReceiptLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.p2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF5B5668), fontSize: 10),
          ),
          Text(
            value,
            style: const TextStyle(color: Color(0xFF5B5668), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Results card shown after scan completes
// ---------------------------------------------------------------------------

class _DatiRiconosciutiCard extends StatelessWidget {
  const _DatiRiconosciutiCard({
    required this.importo,
    required this.descrizione,
    required this.data,
  });

  final String importo;
  final String descrizione;
  final DateTime data;

  @override
  Widget build(BuildContext context) {
    final dataLabel =
        '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';

    return Container(
      decoration: ShapeDecoration(
        color: AppColors.surfaceDarkElevated,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.brandAccent),
          borderRadius: BorderRadius.circular(AppSizes.radius12),
        ),
        shadows: const [
          BoxShadow(
            color: AppColors.shadowOverlay,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.statusPositive,
                size: AppSizes.p16,
              ),
              const SizedBox(width: AppSizes.p8),
              Text(
                'Dati riconosciuti',
                style: AppTextStyles.screenTitleStrong.copyWith(
                  color: AppColors.textOnDark,
                  fontSize: AppSizes.p14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.p12),
          _DataRow(
            icon: Icons.euro_rounded,
            label: 'Importo',
            value: importo,
          ),
          const SizedBox(height: AppSizes.p6),
          _DataRow(
            icon: Icons.receipt_long_rounded,
            label: 'Descrizione',
            value: descrizione,
          ),
          const SizedBox(height: AppSizes.p6),
          _DataRow(
            icon: Icons.calendar_today_rounded,
            label: 'Data',
            value: dataLabel,
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: AppSizes.p14, color: AppColors.brandAccent),
        const SizedBox(width: AppSizes.p8),
        Text(
          '$label: ',
          style: AppTextStyles.screenTitleStrong.copyWith(
            color: AppColors.textMuted,
            fontSize: AppSizes.p13,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.screenTitleStrong.copyWith(
              color: AppColors.textOnDark,
              fontSize: AppSizes.p13,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
