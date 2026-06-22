import 'package:flutter/material.dart';

import 'package:coincasa_app/data/models/problema.dart';
import 'package:coincasa_app/ui/problemi/screens/problema_dettaglio_screen.dart'
    as dettaglio;

Future<void> showProblemaDettaglio(BuildContext context, Problema problema) {
  return dettaglio.showProblemaDettaglio(context, problema);
}
