import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const _useFashn = false;
  static const _fashnApiKey = 'YOUR_FASHN_API_KEY_HERE';
  static const _geminiApiKey = 'AIzaSyDeQ9VqpH_GTSPEI8h3Xar0uKQZraLVx3M';

  /// Returns a map with either 'imageUrl' or 'description'
  static Future<Map<String, String>> tryOn({
    required File personPhoto,
    required String dressImageUrl,
  }) async {
    if (_useFashn) {
      final url = await _tryOnWithFashn(
        personPhoto: personPhoto,
        dressImageUrl: dressImageUrl,
      );
      return {'imageUrl': url};
    } else {
      final description = await _tryOnWithGemini(
        personPhoto: personPhoto,
        dressImageUrl: dressImageUrl,
      );
      return {'description': description};
    }
  }

  // Gemini: returns a styling description (free, works now)
  static Future<String> _tryOnWithGemini({
    required File personPhoto,
    required String dressImageUrl,
  }) async {
    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _geminiApiKey,
      );
      final personBytes = await personPhoto.readAsBytes();
      final dressRes = await http.get(Uri.parse(dressImageUrl));
      final dressBytes = dressRes.bodyBytes;

      final response = await model.generateContent([
        Content.multi([
          DataPart('image/jpeg', personBytes),
          DataPart('image/jpeg', dressBytes),
          TextPart(
            'Look at the person in the first image and the dress/outfit in the second image. '
            'Give a fun, personalized, detailed style report describing exactly how this dress would look on this specific person. '
            'Include: how the fit would look, which features it would complement, suggested colors if not shown, '
            'accessories that would match, and an overall style rating out of 10. '
            'Be encouraging, specific, and fashion-forward. Keep it under 150 words.',
          ),
        ]),
      ]);

      return response.text ?? 'Could not generate style report.';
    } catch (e) {
      throw Exception('Style analysis failed: $e');
    }
  }

  // Fashn.ai: returns actual try-on image URL (paid — ready when subscribed)
  static Future<String> _tryOnWithFashn({
    required File personPhoto,
    required String dressImageUrl,
  }) async {
    try {
      final personBytes = await personPhoto.readAsBytes();
      final b64Person = base64Encode(personBytes);
      final startRes = await http.post(
        Uri.parse('https://api.fashn.ai/v1/run'),
        headers: {
          'Authorization': 'Bearer $_fashnApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model_image': 'data:image/jpeg;base64,$b64Person',
          'garment_image': dressImageUrl,
          'category': 'dresses',
        }),
      );
      final startData = jsonDecode(startRes.body);
      final predictionId = startData['id'];
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(seconds: 2));
        final pollRes = await http.get(
          Uri.parse('https://api.fashn.ai/v1/status/$predictionId'),
          headers: {'Authorization': 'Bearer $_fashnApiKey'},
        );
        final pollData = jsonDecode(pollRes.body);
        if (pollData['status'] == 'completed') return pollData['output'][0];
        if (pollData['status'] == 'failed') throw Exception('Fashn.ai job failed');
      }
      throw Exception('Fashn.ai timed out');
    } catch (e) {
      throw Exception('Fashn.ai try-on failed: $e');
    }
  }
}
