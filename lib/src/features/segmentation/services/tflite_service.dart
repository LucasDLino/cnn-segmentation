import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class TFLiteService {
  Interpreter? _interpreter;
  List<int>? _inputShape;
  List<int>? _outputShape;

  // ImageNet normalization constants (used during model training)
  static const List<double> imagenetMean = [0.485, 0.456, 0.406];
  static const List<double> imagenetStd = [0.229, 0.224, 0.225];

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('lib/src/assets/pet_segmentation_unet_float32.tflite');
      _inputShape = _interpreter!.getInputTensors()[0].shape;
      _outputShape = _interpreter!.getOutputTensors()[0].shape;
      developer.log('Model loaded. Input: $_inputShape, Output: $_outputShape');
    } catch (e) {
      developer.log('Error loading model: $e');
    }
  }

  Future<Uint8List?> predict(dynamic inputSource) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) return null;

    final h = _inputShape![1];
    final w = _inputShape![2];
    final c = _inputShape![3];

    Uint8List imageBytes;
    if (inputSource is File) {
      imageBytes = await inputSource.readAsBytes();
    } else if (inputSource is String) {
      final byteData = await rootBundle.load(inputSource);
      imageBytes = byteData.buffer.asUint8List();
    } else {
      return null;
    }

    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) return null;

    img.Image resizedImage = img.copyResize(originalImage, width: w, height: h);

    var input = Float32List(1 * h * w * c);
    var buffer = Float32List.view(input.buffer);
    int pixelIndex = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // Apply ImageNet normalization: (pixel / 255.0 - mean) / std
        buffer[pixelIndex++] = ((pixel.r / 255.0) - imagenetMean[0]) / imagenetStd[0];
        buffer[pixelIndex++] = ((pixel.g / 255.0) - imagenetMean[1]) / imagenetStd[1];
        buffer[pixelIndex++] = ((pixel.b / 255.0) - imagenetMean[2]) / imagenetStd[2];
      }
    }

    var inputReshaped = input.reshape([1, h, w, c]);

    final isChannelsFirst = _outputShape![1] == 3 || _outputShape![1] == 1;
    final outC = isChannelsFirst ? _outputShape![1] : _outputShape![3];
    final outH = isChannelsFirst ? _outputShape![2] : _outputShape![1];
    final outW = isChannelsFirst ? _outputShape![3] : _outputShape![2];
    
    var outputFlat = Float32List(1 * outH * outW * outC);
    var outputBuffer = outputFlat.reshape(_outputShape!);

    try {
      _interpreter!.run(inputReshaped, outputBuffer);
      developer.log('Inference completed. Output shape: $_outputShape');
      developer.log('Channels first: $isChannelsFirst, outC: $outC, outH: $outH, outW: $outW');
    } catch (e) {
      developer.log('Inference error: $e');
      return null;
    }

    // Ensure 4 channels for transparency
    img.Image maskImage = img.Image(width: outW, height: outH, numChannels: 4);

    // Debug: Count label distribution and check output values
    Map<int, int> labelCounts = {};
    List<double> sampleValues = [];
    for (int y = 0; y < outH; y++) {
      for (int x = 0; x < outW; x++) {
        int label = 0;
        
        if (outC == 1) {
          double val = isChannelsFirst ? outputBuffer[0][0][y][x] : outputBuffer[0][y][x][0];
          label = val.round();
          if (sampleValues.length < 5) sampleValues.add(val);
        } else {
          double maxVal = -double.infinity;
          for(int i = 0; i < outC; i++) {
            double val = isChannelsFirst ? outputBuffer[0][i][y][x] : outputBuffer[0][y][x][i];
            if(val > maxVal) {
              maxVal = val;
              label = i;
            }
            if (sampleValues.length < 5 && i == 0) sampleValues.add(val);
          }
        }

        // Track label distribution for debugging
        labelCounts[label] = (labelCounts[label] ?? 0) + 1;

        // Class mapping observed in the model output:
        // 0: Pet/Animal (green)
        // 1: Background (black)
        // 2: Boundary/Edges (red)
        if (label == 0) { // Pet interior
           maskImage.setPixel(x, y, img.ColorRgba8(0, 255, 0, 255));
        } else if (label == 2) { // Boundary/Edges
           maskImage.setPixel(x, y, img.ColorRgba8(255, 0, 0, 255));
        } else { // Background (label 1)
           maskImage.setPixel(x, y, img.ColorRgba8(0, 0, 0, 255));
        }
      }
    }

    developer.log('Label distribution: $labelCounts');
    developer.log('Sample output values: $sampleValues');

    return Uint8List.fromList(img.encodePng(maskImage));
  }

  void close() {
    _interpreter?.close();
  }
}
