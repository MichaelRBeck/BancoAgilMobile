import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

final brCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

String money(num v) => brCurrency.format(v);
String dmy(DateTime d) => DateFormat('dd/MM/yyyy', 'pt_BR').format(d);

Future<void> initFormatters() async {
  await initializeDateFormatting('pt_BR', null);
  Intl.defaultLocale = 'pt_BR';
}
