import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../shared/models/animal.dart';
import '../../../shared/models/consultation.dart';
import '../../../shared/models/operation.dart';
import '../../../shared/models/vaccination.dart';

/// Génère le carnet de santé complet d'un animal en PDF.
class HealthBookPdf {
  HealthBookPdf._();

  static Future<Uint8List> build({
    required Animal animal,
    required List<Vaccination> vaccinations,
    required List<Consultation> consultations,
    required List<Operation> operations,
  }) async {
    final pdf = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) => [
          // En-tête
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFB5D5F5),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              children: [
                pw.Text('🐾',
                    style: const pw.TextStyle(fontSize: 32)),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PETLANDER',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        )),
                    pw.Text('Carnet de santé numérique'),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          // Profil animal
          _section('Profil de l\'animal'),
          _kv('Nom', animal.nom),
          _kv('Type', animal.type.label),
          if (animal.race != null) _kv('Race', animal.race!),
          _kv('Sexe', animal.sexe.label),
          if (animal.dateNaissance != null)
            _kv('Né(e) le', dateFmt.format(animal.dateNaissance!)),
          if (animal.couleur != null) _kv('Couleur', animal.couleur!),
          if (animal.poidsActuel != null)
            _kv('Poids actuel', '${animal.poidsActuel!.toStringAsFixed(1)} kg'),
          if (animal.numeroPuce != null)
            _kv('N° puce', animal.numeroPuce!),
          _kv('Stérilisé(e)', animal.sterilise ? 'Oui' : 'Non'),
          pw.SizedBox(height: 16),

          // Vaccinations
          _section('Vaccinations'),
          if (vaccinations.isEmpty)
            pw.Text('Aucune vaccination enregistrée.')
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFC8E6C9),
              ),
              data: <List<String>>[
                ['Vaccin', 'Date', 'Rappel', 'Lot'],
                ...vaccinations.map((v) => [
                      v.nomVaccin ?? '—',
                      dateFmt.format(v.dateVaccination),
                      v.dateRappel != null ? dateFmt.format(v.dateRappel!) : '—',
                      v.lotVaccin ?? '—',
                    ]),
              ],
            ),
          pw.SizedBox(height: 16),

          // Consultations
          _section('Consultations'),
          if (consultations.isEmpty)
            pw.Text('Aucune consultation enregistrée.')
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFB5D5F5),
              ),
              data: <List<String>>[
                ['Date', 'Motif', 'Vétérinaire', 'Diagnostic'],
                ...consultations.map((c) => [
                      dateFmt.format(c.dateConsultation),
                      c.motif ?? '—',
                      c.veterinaireNom != null ? 'Dr ${c.veterinaireNom}' : '—',
                      c.diagnostic ?? '—',
                    ]),
              ],
            ),
          pw.SizedBox(height: 16),

          // Opérations
          _section('Opérations chirurgicales'),
          if (operations.isEmpty)
            pw.Text('Aucune opération enregistrée.')
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFFFB74D),
              ),
              data: <List<String>>[
                ['Date', 'Type', 'Vétérinaire', 'Durée'],
                ...operations.map((o) => [
                      dateFmt.format(o.dateOperation),
                      o.typeOperation,
                      o.veterinaireNom != null ? 'Dr ${o.veterinaireNom}' : '—',
                      o.duree ?? '—',
                    ]),
              ],
            ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text(
              'Document généré par Petlander le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _section(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 12),
      child: pw.Container(
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(width: 2)),
        ),
        child: pw.Text(title.toUpperCase(),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ),
    );
  }

  static pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(k,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
          ),
          pw.Expanded(child: pw.Text(v)),
        ],
      ),
    );
  }
}
