import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'result_screen.dart';

class SegmentationScreen extends StatefulWidget {
  const SegmentationScreen({super.key});

  @override
  State<SegmentationScreen> createState() => _SegmentationScreenState();
}

class _SegmentationScreenState extends State<SegmentationScreen> {
  File? _image;
  final picker = ImagePicker();
  late final Future<List<String>> _sampleImagesFuture;

  static const String _samplesPrefix = 'lib/src/assets/samples/';

  @override
  void initState() {
    super.initState();
    _sampleImagesFuture = _loadSampleImages();
  }

  Future<List<String>> _loadSampleImages() async {
    final manifestJson = await rootBundle.loadString('AssetManifest.json');
    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;

    final samples = manifest.keys
        .where((assetPath) => assetPath.startsWith(_samplesPrefix))
        .where((assetPath) {
          final lower = assetPath.toLowerCase();
          return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
        })
        .toList()
      ..sort();

    return samples;
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _navigateToResult(dynamic source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(imageSource: source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Segmentação de Pets'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Importar Sua Imagem',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: _image == null
                  ? Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        width: 220,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Galeria'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Câmera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            if (_image != null) ...[
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _navigateToResult(_image),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Segmentar Esta Foto', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 25.0),
              child: Divider(height: 1, thickness: 1, indent: 30, endIndent: 30),
            ),
            
            const Text(
              'Sugestões do Dataset (Oxford Pet)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              'Deslize para o lado para ver mais',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: FutureBuilder<List<String>>(
                future: _sampleImagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('Não foi possível carregar os exemplos.'));
                  }

                  final sampleImages = snapshot.data ?? const <String>[];
                  if (sampleImages.isEmpty) {
                    return const Center(child: Text('Nenhuma imagem de exemplo encontrada.'));
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sampleImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _navigateToResult(sampleImages[index]),
                        child: Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 15),
                          child: Column(
                            children: [
                              Expanded(
                                child: Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.asset(
                                        sampleImages[index],
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Exemplo ${index + 1}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
