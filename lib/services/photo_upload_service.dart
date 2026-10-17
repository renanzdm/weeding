import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class PhotoUploadService {
  const PhotoUploadService();

  bool get isConfigured => SupabaseConfig.isConfigured;

  Future<void> upload({
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (!isConfigured) {
      throw StateError(
        'Supabase não está configurado. Verifique os Secrets do deploy.',
      );
    }

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final extension = _extensionFor(fileName);
    final path = 'fotos/${timestamp}_$extension';

    await Supabase.instance.client.storage.from('casamento').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            contentType: contentType,
            upsert: false,
          ),
        );
  }

  String _extensionFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    const allowed = <String>{'jpg', 'jpeg', 'png', 'webp', 'heic'};
    return allowed.contains(extension) ? extension : 'jpg';
  }
}
