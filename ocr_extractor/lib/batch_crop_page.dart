import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'image_preprocessor.dart';

class BatchCropPage extends StatefulWidget {
  const BatchCropPage({Key? key}) : super(key: key);

  @override
  State<BatchCropPage> createState() => _BatchCropPageState();
}

class _BatchCropPageState extends State<BatchCropPage> {
  List<File> _imageFiles = [];
  bool _isProcessing = false;
  String _processingStatus = '';
  List<Map<String, String>> _results = [];
  Rect? _cropRect; // Crop area
  bool _usePreprocessing = true;
  final CropController _cropController = CropController();
  Uint8List? _firstImageBytes;
  bool _showCropper = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickZipFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (result != null) {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Extracting images from ZIP...';
      });
      try {
        await _extractImagesFromZip(result.files.single.path!);
        if (_imageFiles.isNotEmpty) {
          _prepareFirstImageForCropping();
        }
      } catch (e) {
        _showErrorDialog('Error extracting ZIP: $e');
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickImageFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Folder with Images');
    if (selectedDirectory != null) {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Reading images from folder...';
      });
      try {
        await _extractImagesFromFolder(selectedDirectory);
        if (_imageFiles.isNotEmpty) {
          _prepareFirstImageForCropping();
        }
      } catch (e) {
        _showErrorDialog('Error reading folder: $e');
      }
      setState(() {
        _isProcessing = false;
      });
    }
  }
  void _prepareFirstImageForCropping() async {
    final bytes = await _imageFiles.first.readAsBytes();
    setState(() {
      _firstImageBytes = bytes;
      _showCropper = true;
    });
  }

  Future<void> _extractImagesFromZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    List<File> imageFiles = [];
    final tempDir = await getTemporaryDirectory();
    for (final file in archive) {
      if (file.isFile) {
        final filename = file.name.toLowerCase();
        if (_isImageFile(filename)) {
          final data = file.content as List<int>;
          final tempFile = File('${tempDir.path}/${file.name}');
          await tempFile.create(recursive: true);
          await tempFile.writeAsBytes(data);
          imageFiles.add(tempFile);
        }
      }
    }
    setState(() {
      _imageFiles = imageFiles;
    });
  }

  Future<void> _extractImagesFromFolder(String folderPath) async {
    final directory = Directory(folderPath);
    final files = directory.listSync(recursive: false);
    List<File> imageFiles = [];
    for (var entity in files) {
      if (entity is File && _isImageFile(entity.path)) {
        imageFiles.add(entity);
      }
    }
    setState(() {
      _imageFiles = imageFiles;
    });
  }

  bool _isImageFile(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.tiff') ||
        lower.endsWith('.webp');
  }

  Future<File> _cropImage(File file, Rect cropRect) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return file;
    final cropped = img.copyCrop(
      image,
      x: cropRect.left.toInt(),
      y: cropRect.top.toInt(),
      width: cropRect.width.toInt(),
      height: cropRect.height.toInt(),
    );
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}');
    await tempFile.writeAsBytes(img.encodeJpg(cropped, quality: 95));
    return tempFile;
  }

  Future<void> _processAllImages() async {
    if (_imageFiles.isEmpty || _cropRect == null) return;
    setState(() {
      _isProcessing = true;
      _results.clear();
    });
    final textRecognizer = TextRecognizer();
    for (int i = 0; i < _imageFiles.length; i++) {
      setState(() {
        _processingStatus = 'Cropping and processing image ${i + 1} of ${_imageFiles.length}...';
      });
      try {
        final croppedFile = await _cropImage(_imageFiles[i], _cropRect!);
        File fileForOcr = croppedFile;
        File? tempPreprocessed;
        if (_usePreprocessing) {
          tempPreprocessed = await ImagePreprocessor.preprocess(croppedFile);
          fileForOcr = tempPreprocessed;
        }
        final inputImage = InputImage.fromFile(fileForOcr);
        final recognizedText = await textRecognizer.processImage(inputImage);
        String allText = recognizedText.text;
        if (tempPreprocessed != null && tempPreprocessed.path != croppedFile.path) {
          try { await tempPreprocessed.delete(); } catch (_) {}
        }
        try { await croppedFile.delete(); } catch (_) {}
        _results.add({
          'filename': _imageFiles[i].path.split('/').last,
          'extracted': allText.isNotEmpty ? allText : '[No text found]'
        });
      } catch (e) {
        _results.add({
          'filename': _imageFiles[i].path.split('/').last,
          'extracted': '[Error: $e]'
        });
      }
    }
    textRecognizer.close();
    setState(() {
      _isProcessing = false;
      _processingStatus = '';
    });
    _showResultsDialog(_results, "Cropped Extraction Results");
  }

  void _showResultsDialog(List<Map<String, String>> results, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Image Filename')),
                      DataColumn(label: Text('Extracted Text')),
                    ],
                    rows: results.map((row) {
                      return DataRow(
                        cells: [
                          DataCell(Text(row['filename'] ?? '')),
                          DataCell(Text(row['extracted'] ?? '')),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await _saveResultsWithDialog(results);
                    },
                    child: const Text('Save Results'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveResultsWithDialog(List<Map<String, String>> results) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Folder to Save Results');
    if (selectedDirectory == null) return;
    String fileName = await _promptForFileName();
    if (fileName.isEmpty) return;
    final file = File('$selectedDirectory/$fileName');
    String content = 'Image Filename\tExtracted Text\n' +
        results.map((row) => '${row['filename']}\t${row['extracted']}').join('\n');
    await file.writeAsString(content);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Results saved to ${file.path}')),
      );
    }
  }

  Future<String> _promptForFileName() async {
    String fileName = '';
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: 'cropped_ocr_results.txt');
        return AlertDialog(
          title: const Text('Enter Output File Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'File name'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                fileName = controller.text.trim();
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return fileName;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Called when cropping is done
  void _onCropCompleted(Rect area, double scale, int imageWidth, int imageHeight) {
    setState(() {
      _cropRect = Rect.fromLTWH(
        area.left * imageWidth,
        area.top * imageHeight,
        area.width * imageWidth,
        area.height * imageHeight,
      );
      _showCropper = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Crop & OCR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _showCropper && _firstImageBytes != null
            ? Column(
                children: [
                  const Text('Crop the first image. This crop will be applied to all images.'),
                  Expanded(
                    child: Crop(
                      image: _firstImageBytes!,
                      controller: _cropController,
                      onCropped: (croppedData) {}, // Not used, we only need the area
                      onMoved: (area) {},
                      withCircleUi: false,
                      onStatusChanged: (status) {},
                      initialAreaBuilder: (rect) => Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
                      // onAreaChanged removed: not supported in this version
                      onCompleted: (area, scale) {
                        // area is relative (0-1), scale is zoom, get image size
                        final decoded = img.decodeImage(_firstImageBytes!);
                        if (decoded != null) {
                          _onCropCompleted(area, scale, decoded.width, decoded.height);
                        }
                      },
                      baseColor: Colors.black,
                      maskColor: Colors.black.withOpacity(0.5),
                      cornerDotBuilder: (size, index, isActive) => Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.blue : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _cropController.crop();
                    },
                    child: const Text('Apply Crop to All Images'),
                  ),
                ],
              )
            : ListView(
                children: [
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickZipFile,
                        icon: const Icon(Icons.folder_zip),
                        label: const Text('Select ZIP Folder'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _pickImageFolder,
                        icon: const Icon(Icons.folder),
                        label: const Text('Select Images Folder'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_imageFiles.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Loaded ${_imageFiles.length} images'),
                        const SizedBox(height: 8),
                        if (_cropRect != null)
                          Text('Crop area: ${_cropRect!.width.toInt()} x ${_cropRect!.height.toInt()}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Switch(
                              value: _usePreprocessing,
                              onChanged: (v) => setState(() => _usePreprocessing = v),
                            ),
                            const Text('Use Image Preprocessing'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _isProcessing || _cropRect == null ? null : _processAllImages,
                          child: const Text('Crop & Extract Text'),
                        ),
                      ],
                    ),
                  if (_isProcessing)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(_processingStatus),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
