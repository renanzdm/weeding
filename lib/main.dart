import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'services/photo_upload_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/config.env', isOptional: true);

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  }

  runApp(const CasamentoApp());
}

class CasamentoApp extends StatelessWidget {
  const CasamentoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF2F2925);
    const terracotta = Color(0xFFB96E54);

    return MaterialApp(
      title: 'Nossas memórias',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F4EE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: terracotta,
          brightness: Brightness.light,
          surface: const Color(0xFFFFFCF8),
        ),
        fontFamily: 'Arial',
        textTheme: const TextTheme(
          displaySmall: TextStyle(
            color: ink,
            fontSize: 42,
            fontWeight: FontWeight.w400,
            height: 1.08,
          ),
          titleLarge: TextStyle(
            color: ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF665E58),
            fontSize: 16,
            height: 1.5,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF665E58),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
      home: const MemoriesPage(),
    );
  }
}

class PhotoDraft {
  const PhotoDraft({required this.file, required this.bytes});

  final XFile file;
  final Uint8List bytes;
}

class MemoriesPage extends StatefulWidget {
  const MemoriesPage({super.key});

  @override
  State<MemoriesPage> createState() => _MemoriesPageState();
}

class _MemoriesPageState extends State<MemoriesPage> {
  final _picker = ImagePicker();
  final _guestController = TextEditingController();
  final _uploadService = const PhotoUploadService();
  final List<PhotoDraft> _photos = <PhotoDraft>[];

  bool _isUploading = false;
  bool _hasUploaded = false;
  double _uploadProgress = 0;
  String? _errorMessage;

  @override
  void dispose() {
    _guestController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final files = await _picker.pickMultiImage(imageQuality: 88);
    if (files.isEmpty) return;

    final drafts = <PhotoDraft>[];
    for (final file in files) {
      drafts.add(PhotoDraft(file: file, bytes: await file.readAsBytes()));
    }

    if (!mounted) return;
    setState(() {
      _photos.addAll(drafts);
      _hasUploaded = false;
      _errorMessage = null;
    });
  }

  Future<void> _takePhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
    );
    if (file == null) return;

    final draft = PhotoDraft(file: file, bytes: await file.readAsBytes());
    if (!mounted) return;
    setState(() {
      _photos.add(draft);
      _hasUploaded = false;
      _errorMessage = null;
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      _hasUploaded = false;
      _errorMessage = null;
    });
  }

  Future<void> _uploadPhotos() async {
    if (_photos.isEmpty || _isUploading) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    try {
      for (var index = 0; index < _photos.length; index++) {
        final photo = _photos[index];
        await _uploadService.upload(
          fileName: photo.file.name,
          bytes: photo.bytes,
          contentType: _contentTypeFor(photo.file.name),
        );
        if (!mounted) return;
        setState(() => _uploadProgress = (index + 1) / _photos.length);
      }
    } on StorageException catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = 'Supabase: ${error.message}';
      });
      return;
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage = 'Erro ao enviar: $error';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _hasUploaded = true;
    });
  }

  String _contentTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'heic' => 'image/heic',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 760;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 20 : 56,
                vertical: isCompact ? 22 : 34,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(isCompact),
                      const SizedBox(height: 54),
                      _buildHero(isCompact),
                      const SizedBox(height: 34),
                      _buildContentCard(isCompact),
                      const SizedBox(height: 42),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isCompact) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE9D7C8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFF9A5E48),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'NOSSAS MEMÓRIAS',
          style: TextStyle(
            color: Color(0xFF473A33),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.2,
          ),
        ),
        const Spacer(),
        if (!isCompact)
          const Text(
            'CASAMENTO • NOSSO DIA',
            style: TextStyle(
              color: Color(0xFF967F71),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),
      ],
    );
  }

  Widget _buildHero(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEEDDD1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'UM PEDACINHO DESSE DIA PARA SEMPRE',
            style: TextStyle(
              color: Color(0xFF9A5E48),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Ajude a contar\na nossa história.',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: isCompact ? 38 : 52,
              ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 570),
          child: Text(
            'Você fez parte de um dos dias mais importantes das nossas vidas. Compartilhe aqui os momentos que só você conseguiu registrar.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 20 : 30),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEADFD5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D6D5548),
            blurRadius: 28,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Compartilhe suas fotos',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Pode enviar várias de uma vez. Não precisa criar conta.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _guestController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Como podemos te chamar? (opcional)',
              hintText: 'Ex.: Ana e João',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              filled: true,
              fillColor: const Color(0xFFFAF6F1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE9DED4)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE9DED4)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_photos.isEmpty)
            _buildEmptyUploader(isCompact)
          else
            _buildPhotoGrid(isCompact),
          const SizedBox(height: 24),
          if (_isUploading) _buildProgress(),
          if (_hasUploaded) _buildSuccess(),
          if (_errorMessage != null) _buildError(),
          if (!_isUploading && !_hasUploaded) _buildActionRow(isCompact),
        ],
      ),
    );
  }

  Widget _buildEmptyUploader(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          vertical: isCompact ? 31 : 46, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4D5C9), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF0DFD3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.photo_camera_back_outlined,
                color: Color(0xFF9A5E48), size: 27),
          ),
          const SizedBox(height: 16),
          const Text(
            'Suas fotos ficam lindas aqui',
            style: TextStyle(
              color: Color(0xFF473A33),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Escolha da galeria ou abra a câmera',
            style: TextStyle(color: Color(0xFF89776C), fontSize: 13),
          ),
          const SizedBox(height: 20),
          _buildPickerButtons(isCompact),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_photos.length} ${_photos.length == 1 ? 'foto selecionada' : 'fotos selecionadas'}',
              style: const TextStyle(
                color: Color(0xFF5B4A40),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isUploading ? null : _pickFromGallery,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Adicionar mais'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isCompact ? 3 : 5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _photos.length,
          itemBuilder: (context, index) {
            final photo = _photos[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(photo.bytes, fit: BoxFit.cover),
                ),
                if (!_isUploading)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xCC2F2925),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 15),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPickerButtons(bool isCompact) {
    final galleryButton = FilledButton.icon(
      onPressed: _pickFromGallery,
      icon: const Icon(Icons.collections_outlined, size: 19),
      label: const Text('Escolher fotos'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFB96E54),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    final cameraButton = OutlinedButton.icon(
      onPressed: _takePhoto,
      icon: const Icon(Icons.camera_alt_outlined, size: 19),
      label: const Text('Abrir câmera'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF965B46),
        side: const BorderSide(color: Color(0xFFD8B8A7)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return isCompact
        ? Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [galleryButton, cameraButton],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [galleryButton, const SizedBox(width: 10), cameraButton],
          );
  }

  Widget _buildActionRow(bool isCompact) {
    final button = FilledButton.icon(
      onPressed: _photos.isEmpty ? null : _uploadPhotos,
      icon: const Icon(Icons.cloud_upload_outlined, size: 19),
      label: Text(_photos.isEmpty ? 'Selecione uma foto' : 'Enviar fotos'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFB96E54),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE6D8CE),
        disabledForegroundColor: const Color(0xFF9C8A7E),
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (isCompact) {
      return SizedBox(width: double.infinity, child: button);
    }

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 18,
      runSpacing: 14,
      children: [button, _buildPrivacyNote()],
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFB96E54)),
            ),
            const SizedBox(width: 10),
            Text(
              'Guardando suas memórias… ${(_uploadProgress * 100).round()}%',
              style: const TextStyle(
                  color: Color(0xFF6A574D), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 11),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: _uploadProgress,
            minHeight: 7,
            backgroundColor: const Color(0xFFEFE4DB),
            color: const Color(0xFFB96E54),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1E6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Color(0xFF5F855E)),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Tudo certo! Obrigado por guardar esse momento com a gente.',
              style: TextStyle(
                  color: Color(0xFF4E704D), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBEAE5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFAC5A47)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                  color: Color(0xFF92503F), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF9D887B)),
        SizedBox(width: 6),
        Text('Somente os noivos terão acesso',
            style: TextStyle(color: Color(0xFF9D887B), fontSize: 12)),
      ],
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Text(
        'Feito com carinho para celebrar o amor',
        style: TextStyle(
          color: Color(0xFFB6A399),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
