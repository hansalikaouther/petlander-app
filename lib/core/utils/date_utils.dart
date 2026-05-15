import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _shortDate = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final DateFormat _longDate = DateFormat('dd MMMM yyyy', 'fr_FR');
  static final DateFormat _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final DateFormat _time = DateFormat('HH:mm', 'fr_FR');

  static String shortDate(DateTime date) => _shortDate.format(date);
  static String longDate(DateTime date) => _longDate.format(date);
  static String dateTime(DateTime date) => _dateTime.format(date);
  static String time(DateTime date) => _time.format(date);

  /// Calcule l'âge à partir de la date de naissance.
  static String ageFromBirthDate(DateTime birth) {
    final now = DateTime.now();
    int years = now.year - birth.year;
    int months = now.month - birth.month;
    if (now.day < birth.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }
    if (years == 0) return '$months mois';
    if (months == 0) return '$years an${years > 1 ? "s" : ""}';
    return '$years an${years > 1 ? "s" : ""} et $months mois';
  }

  /// Indique si une date est dépassée.
  static bool isPast(DateTime date) => date.isBefore(DateTime.now());

  /// Nombre de jours restants jusqu'à une date (négatif si passé).
  static int daysUntil(DateTime date) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }
}
