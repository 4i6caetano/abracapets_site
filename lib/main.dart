import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_widget.dart';
import 'app/di/locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  await setupLocator();
  runApp(const AbracaPetsApp());
}
