import 'package:flutter/material.dart';

import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/ui/problemi/screens/dettaglio_problema_screen.dart'
    as dettaglio;

Future<void> showProblemaDettaglio(BuildContext context, Problema problema) {
  return dettaglio.showProblemaDettaglio(context, problema);
}
