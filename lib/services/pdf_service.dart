import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../models/signalement.dart' as model;

class PdfService {
  static Future<File> genererDevisPdf({
    required String titre,
    required String description,
    required int duree,
    required double montant,
    String? commentaireOuvrier,
    required model.Signalement signalement,
    required User ouvrier,
    required List<File> photos,
  }) async {
    final pdf = pw.Document();

    // Ajouter les pages du PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build:
            (context) => [
              // Page 1: En-tête et informations principales
              _buildHeader(titre, signalement),
              pw.SizedBox(height: 20),
              _buildSignalementInfo(signalement),
              pw.SizedBox(height: 20),
              _buildOuvrierInfo(ouvrier),
              pw.SizedBox(height: 20),
              _buildDevisDetails(
                description,
                duree,
                montant,
                commentaireOuvrier,
              ),

              // Page 2: Photos (si il y en a)
              if (photos.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                _buildPhotosSection(photos),
              ],
            ],
      ),
    );

    // Sauvegarder le PDF
    final output = await getTemporaryDirectory();
    final file = File(
      '${output.path}/devis_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeader(String titre, model.Signalement signalement) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête avec logo/titre
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue900,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Text(
                'DEVIS',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Gestion de Communauté Locale',
                style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),

        // Titre du devis
        pw.Text(
          titre,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildSignalementInfo(model.Signalement signalement) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SIGNALEMENT CONCERNÉ',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Code', signalement.code ?? 'N/A'),
          _buildInfoRow('Titre', signalement.titre),
          _buildInfoRow('Description', signalement.description),
          _buildInfoRow('Type de service', signalement.typeService ?? 'N/A'),
          _buildInfoRow('Statut', signalement.statut),
          if (signalement.priorite != null)
            _buildInfoRow('Priorité', signalement.priorite!.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildOuvrierInfo(User ouvrier) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DE L\'OUVRIER',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Nom complet', '${ouvrier.nom} ${ouvrier.prenom}'),
          _buildInfoRow('Email', ouvrier.email),
          _buildInfoRow('Téléphone', ouvrier.numero.toString()),
        ],
      ),
    );
  }

  static pw.Widget _buildDevisDetails(
    String description,
    int duree,
    double montant,
    String? commentaireOuvrier,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DÉTAILS DU DEVIS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Description des travaux', description),
          _buildInfoRow('Durée estimée', '$duree jour${duree > 1 ? 's' : ''}'),
          _buildInfoRow('Montant total', '${montant.toStringAsFixed(0)} FCFA'),
          if (commentaireOuvrier != null && commentaireOuvrier.isNotEmpty)
            _buildInfoRow('Commentaire', commentaireOuvrier),
        ],
      ),
    );
  }

  static pw.Widget _buildPhotosSection(List<File> photos) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PHOTOS DU DEVIS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              photos.map((photo) {
                return pw.Container(
                  width: 200,
                  height: 150,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Image(
                    pw.MemoryImage(photo.readAsBytesSync()),
                    fit: pw.BoxFit.cover,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
 