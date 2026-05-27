import 'package:flutter/material.dart';
import 'package:coincasa_app/features/casa/screens/casa_creata_successo.dart';
import 'package:coincasa_app/features/casa/screens/compilazione_form_crea_casa.dart'; // ← aggiunto
import 'package:coincasa_app/core/theme/app_theme.dart';

class RiepilogoCasaScreen extends StatefulWidget {
  final String name;
  final String city;
  final String address;
  final String type;
  final String role;

  const RiepilogoCasaScreen({
    super.key,
    required this.name,
    required this.city,
    required this.address,
    required this.type,
    this.role = 'Amministratore',
  });

  @override
  State<RiepilogoCasaScreen> createState() => _RiepilogoCasaScreenState();
}

class _RiepilogoCasaScreenState extends State<RiepilogoCasaScreen> {
  late String name;
  late String city;
  late String address;
  late String type;
  late String role;

  @override
  void initState() {
    super.initState();
    name = widget.name;
    city = widget.city;
    address = widget.address;
    type = widget.type;
    role = widget.role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: Navigator.of(context).pop,
        ),
        title: const Text('Riepilogo casa', style: AppTextStyles.screenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.p16,
            vertical: AppSizes.p12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conferma i dati della casa',
                style: AppTextStyles.bodyMuted.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSizes.p10),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSizes.radius24),
                  border: Border.all(color: AppColors.dividerDark, width: 1),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Nome', name),
                    _buildDivider(),
                    _buildDetailRow('Città', city.isEmpty ? '-' : city),
                    _buildDivider(),
                    _buildDetailRow(
                      'Indirizzo',
                      address.isEmpty ? '-' : address,
                    ),
                    _buildDivider(),
                    _buildDetailRow('Tipo', type),
                    _buildDivider(),
                    _buildDetailRow(
                      'Ruolo',
                      role,
                      valueColor: AppColors.brandAccent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p16),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(AppSizes.radius16),
                  border: Border.all(color: AppColors.dividerDark, width: 1),
                ),
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.brandPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: AppSizes.p12),
                    Expanded(
                      child: Text(
                        'Dopo la creazione diventerai automaticamente amministratore della casa con tutti i permessi.',
                        style: AppTextStyles.bodyMuted.copyWith(
                          color: AppColors.textMutedLight,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.p18),

              // ── Bottone Crea casa ────────────────────────────────────────
              FilledButton(
                onPressed: () => _createCasa(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.p56),
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.textOnDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                  ),
                ),
                child: Text(
                  'Crea casa',
                  style: AppTextStyles.buttonCompact.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'oppure',
                  style: AppTextStyles.divider.copyWith(
                    color: AppColors.textOnDark.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Bottone Modifica → ModificaCasaScreen ────────────────────
              OutlinedButton(
                onPressed: () async {
                  final result = await Navigator.of(context)
                      .push<Map<String, String>>(
                        MaterialPageRoute<Map<String, String>>(
                          builder: (_) => CompilazioneFormCreaCasaScreen(
                            name: name,
                            city: city,
                            address: address,
                            type: type,
                            fromSummary: true,
                          ),
                        ),
                      );

                  if (result != null) {
                    setState(() {
                      name = result['name'] ?? name;
                      city = result['city'] ?? city;
                      address = result['address'] ?? address;
                      type = result['type'] ?? type;
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.p56),
                  side: const BorderSide(color: AppColors.brandPrimary),
                  foregroundColor: AppColors.textOnDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radius16),
                  ),
                ),
                child: Text(
                  'Modifica',
                  style: AppTextStyles.buttonCompact.copyWith(fontSize: 16),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildProgressDot(active: false),
                    const SizedBox(width: 8),
                    _buildProgressDot(active: true),
                    const SizedBox(width: 8),
                    _buildProgressDot(active: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCasa() async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            CasaCreataSuccessoScreen(name: name, inviteCode: 'CX-4821'),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B8ABC),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFF3B3A5E),
      indent: 18,
      endIndent: 18,
    );
  }

  Widget _buildProgressDot({required bool active}) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppColors.brandPrimary : const Color(0xFF4B4A78),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
