import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../segmentation/services/tflite_service.dart';

class ResultScreen extends StatefulWidget {
  final dynamic imageSource; // Can be File or String (asset path)

  const ResultScreen({super.key, required this.imageSource});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TFLiteService _tfliteService = TFLiteService();
  Uint8List? _maskBytes;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mask = await _tfliteService.predict(widget.imageSource);

      if (mounted) {
        setState(() {
          _maskBytes = mask;
          _isLoading = false;
          if (mask == null) {
            _errorMessage = "A inferência retornou vazio. Verifique os logs do sistema.";
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro técnico: $e";
        });
      }
    }
  }

  @override
  void dispose() {
    _tfliteService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: const Text('Análise de Segmentação'),
        backgroundColor: Colors.amber,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            const Text(
              'Resultado do Modelo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ORIGINAL IMAGE (LEFT)
                    Column(
                      children: [
                        const Text(
                          'Original',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.amber.withAlpha(100), width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: widget.imageSource is File
                                ? Image.file(widget.imageSource as File, fit: BoxFit.cover)
                                : Image.asset(widget.imageSource as String, fit: BoxFit.cover),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(width: 30),

                    // SEGMENTATION MASK (RIGHT)
                    Column(
                      children: [
                        const Text(
                          'Máscara',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.amber.withAlpha(100), width: 2),
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(color: Colors.amber),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: _maskBytes != null
                                      ? Image.memory(
                                          _maskBytes!,
                                          fit: BoxFit.cover,
                                          gaplessPlayback: true,
                                        )
                                      : Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(Icons.error, color: Colors.red),
                                          ),
                                        ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Legend
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📋 Legenda de Cores da Segmentação', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _legendItem(const Color(0xFF00FF00), 'Pet (Animal)'),
                  _legendItem(const Color(0xFFFF0000), 'Contorno/Bordas'),
                  _legendItem(const Color(0xFF000000), 'Fundo'),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('Tentar Outra', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 25, height: 25, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5))),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
