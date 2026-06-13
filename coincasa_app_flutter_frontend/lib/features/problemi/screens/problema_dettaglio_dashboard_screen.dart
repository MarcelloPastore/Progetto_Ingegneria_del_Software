import 'package:flutter/material.dart';

import 'package:coincasa_app/core/models/problema.dart';
import 'package:coincasa_app/features/problemi/screens/problema_dettaglio_screen.dart'
    as dettaglio;

Future<void> showProblemaDettaglio(BuildContext context, Problema problema) {
  return dettaglio.showProblemaDettaglio(context, problema);
}
