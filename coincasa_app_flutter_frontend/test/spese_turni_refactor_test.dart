import 'package:flutter_test/flutter_test.dart';

import 'package:coincasa_app/core/models/inquilino.dart';
import 'package:coincasa_app/core/models/quota.dart';
import 'package:coincasa_app/core/models/spesa.dart';
import 'package:coincasa_app/core/models/turno.dart';
import 'package:coincasa_app/domain/viewmodel/spese_viewmodel.dart';
import 'package:coincasa_app/domain/viewmodel/turni_viewmodel.dart';

void main() {
  group('Spese projections', () {
    test('groups expenses and filters paid status', () {
      final paid = Spesa(
        id: 'paid',
        descrizione: 'Internet',
        importo: 30,
        data: DateTime(2026, 6, 10),
        partecipanti: const [
          {'utenteId': 'u1', 'pagato': true},
        ],
      );
      final unpaid = Spesa(
        id: 'unpaid',
        descrizione: 'Luce',
        importo: 50,
        data: DateTime(2026, 5, 10),
        partecipanti: const [
          {'utenteId': 'u1', 'pagato': false},
        ],
      );

      final projection = SpeseListProjection.from(
        [unpaid, paid],
        filter: SpesaStatus.pagata,
        currentUser: null,
      );

      expect(projection.filtered, [paid]);
      expect(projection.sortedMonths, [DateTime(2026, 6)]);
    });

    test('builds quota detail and excluded housemates', () {
      final spesa = Spesa(
        id: 's1',
        descrizione: 'Acqua',
        importo: 60,
        data: DateTime(2026, 6, 1),
      );
      final quote = [
        Quota(
          id: 'q1',
          importo: 30,
          pagata: true,
          raw: const {},
          utenteId: 'u1',
          utenteNome: 'mario',
        ),
      ];
      const inquilini = [
        Inquilino(
          id: 'u1',
          nome: 'Mario',
          email: 'mario@test.it',
          username: 'mario',
        ),
        Inquilino(
          id: 'u2',
          nome: 'Luisa',
          email: 'luisa@test.it',
          username: 'luisa',
        ),
      ];

      final projection = SpesaDetailProjection.from(
        spesa: spesa,
        quote: quote,
        inquilini: inquilini,
        currentUserId: 'u1',
      );

      expect(projection.rows.single.isCurrentUser, isTrue);
      expect(projection.rowsIncludingExcluded.last.isExcluded, isTrue);
      expect(projection.hasAnyPaidQuota, isTrue);
      expect(projection.quotaPerPersona, 60);
    });
  });

  group('Turni projections', () {
    test('separates expired and upcoming turns', () {
      final expired = Turno(
        id: 'old',
        raw: {'dataProssimaPulizia': '2026-06-18T12:00:00.000'},
      );
      final upcoming = Turno(
        id: 'new',
        raw: {'dataProssimaPulizia': '2026-06-21T12:00:00.000'},
      );

      final projection = TurniListProjection.from([
        upcoming,
        expired,
      ], now: DateTime(2026, 6, 19));

      expect(projection.scaduti, [expired]);
      expect(projection.assegnati, [upcoming]);
    });

    test('raw model data is immutable', () {
      final turno = Turno(id: 't1', raw: const {'task': 'Cucina'});
      expect(
        () => turno.raw['task'] = 'Bagno',
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
