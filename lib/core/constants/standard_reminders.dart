import 'package:flutter/material.dart';

/// Modèles de rappels récurrents standards à proposer aux propriétaires.
class StandardReminder {
  final String label;
  final String message;
  final IconData icon;
  final int recurrenceDays;
  final String type;

  const StandardReminder({
    required this.label,
    required this.message,
    required this.icon,
    required this.recurrenceDays,
    required this.type,
  });
}

class StandardReminders {
  StandardReminders._();

  static const List<StandardReminder> all = [
    StandardReminder(
      label: 'Pesée mensuelle',
      message: 'C\'est l\'heure de peser ton animal !',
      icon: Icons.monitor_weight_outlined,
      recurrenceDays: 30,
      type: 'pesee',
    ),
    StandardReminder(
      label: 'Donner médicament',
      message: 'N\'oublie pas de donner le médicament à ton animal',
      icon: Icons.medication_outlined,
      recurrenceDays: 1,
      type: 'medicament',
    ),
    StandardReminder(
      label: 'Nettoyage (bain / oreilles)',
      message: 'C\'est l\'heure du nettoyage de ton animal !',
      icon: Icons.cleaning_services_outlined,
      recurrenceDays: 14,
      type: 'nettoyage',
    ),
    StandardReminder(
      label: 'Vermifuge trimestriel',
      message: 'Pense à donner un vermifuge à ton animal',
      icon: Icons.vaccines_outlined,
      recurrenceDays: 90,
      type: 'vermifuge',
    ),
    StandardReminder(
      label: 'Anti-puces mensuel',
      message: 'Application anti-puces et anti-tiques recommandée',
      icon: Icons.bug_report_outlined,
      recurrenceDays: 30,
      type: 'antiparasite',
    ),
    StandardReminder(
      label: 'Brossage hebdomadaire',
      message: 'Pense à brosser ton animal pour son pelage',
      icon: Icons.brush_outlined,
      recurrenceDays: 7,
      type: 'brossage',
    ),
    StandardReminder(
      label: 'Détartrage annuel',
      message: 'Pense à prendre rendez-vous pour un détartrage dentaire',
      icon: Icons.medical_information_outlined,
      recurrenceDays: 365,
      type: 'detartrage',
    ),
    StandardReminder(
      label: 'Bilan vétérinaire annuel',
      message: 'Visite annuelle de contrôle recommandée',
      icon: Icons.health_and_safety_outlined,
      recurrenceDays: 365,
      type: 'bilan',
    ),
  ];
}
