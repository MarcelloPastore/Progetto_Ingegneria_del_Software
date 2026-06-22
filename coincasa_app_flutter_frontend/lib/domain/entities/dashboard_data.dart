import 'package:coincasa_app/data/models/casa.dart';
import 'package:coincasa_app/data/models/scadenza.dart';
import 'package:coincasa_app/data/models/salute_casa_item.dart';
import 'package:coincasa_app/data/models/spesa.dart';
import 'package:coincasa_app/data/models/turno.dart';

class DashboardData {
  const DashboardData({
    required this.nomeCasa,
    required this.caseUtente,
    this.casaSelezionataId,
    this.saldo,
    this.credito,
    this.debito,
    this.turni = const [],
    this.turniOggi = const [],
    this.spese = const [],
    this.scadenze = const [],
    this.saluteCasa = const [],
  });

  final String nomeCasa;
  final List<Casa> caseUtente;
  final String? casaSelezionataId;
  final double? saldo;
  final double? credito;
  final double? debito;
  final List<Turno> turni;
  final List<Turno> turniOggi;
  final List<Spesa> spese;
  final List<Scadenza> scadenze;
  final List<SaluteCasaItem> saluteCasa;

  DashboardData copyWith({
    String? nomeCasa,
    List<Casa>? caseUtente,
    String? casaSelezionataId,
    double? saldo,
    double? credito,
    double? debito,
    List<Turno>? turni,
    List<Turno>? turniOggi,
    List<Spesa>? spese,
    List<Scadenza>? scadenze,
    List<SaluteCasaItem>? saluteCasa,
  }) {
    return DashboardData(
      nomeCasa: nomeCasa ?? this.nomeCasa,
      caseUtente: caseUtente ?? this.caseUtente,
      casaSelezionataId: casaSelezionataId ?? this.casaSelezionataId,
      saldo: saldo ?? this.saldo,
      credito: credito ?? this.credito,
      debito: debito ?? this.debito,
      turni: turni ?? this.turni,
      turniOggi: turniOggi ?? this.turniOggi,
      spese: spese ?? this.spese,
      scadenze: scadenze ?? this.scadenze,
      saluteCasa: saluteCasa ?? this.saluteCasa,
    );
  }
}
