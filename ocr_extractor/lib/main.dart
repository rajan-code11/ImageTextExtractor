import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(const OCRNumberExtractorApp());
}

class OCRNumberExtractorApp extends StatelessWidget {
  const OCRNumberExtractorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Number Extractor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const OCRHomePage(),
    );
  }
}

class OCRHomePage extends StatefulWidget {
  const OCRHomePage({Key? key}) : super(key: key);

  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  List<File> _imageFiles = [];
  bool _isProcessing = false;
  String _processingStatus = '';
  List<Map<String, String>> _results = [];

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  Future<void> _pickZipFile() async {
    await _requestPermissions();

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
      } catch (e) {
        _showErrorDialog('Error extracting ZIP: $e');
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _pickImageFolder() async {
    await _requestPermissions();

    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Folder with Images');
    if (selectedDirectory != null) {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Reading images from folder...';
      });

      try {
        await _extractImagesFromFolder(selectedDirectory);
      } catch (e) {
        _showErrorDialog('Error reading folder: $e');
      }

      setState(() {
        _isProcessing = false;
      });
    }
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

    if (imageFiles.isNotEmpty) {
      setState(() {
        _imageFiles = imageFiles;
      });

      _showProcessDialog();
    } else {
      _showErrorDialog('No image files found in ZIP');
    }
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

    if (imageFiles.isNotEmpty) {
      setState(() {
        _imageFiles = imageFiles;
      });
      _showProcessDialog();
    } else {
      _showErrorDialog('No image files found in folder');
    }
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

  void _showProcessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ready to Process'),
        content: Text('Found ${_imageFiles.length} images. Process all images to extract numbers with 5+ digits?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processAllImages();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Process All'),
          ),
        ],
      ),
    );
  }

  Future<void> _processAllImages() async {
    if (_imageFiles.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _results.clear();
    });

    for (int i = 0; i < _imageFiles.length; i++) {
      setState(() {
        _processingStatus = 'Processing image ${i + 1} of ${_imageFiles.length}...';
      });

      try {
        final text = await _extractNumbersFromImage(_imageFiles[i]);
        _results.add({
          'filename': _imageFiles[i].path.split('/').last,
          'extracted': text
        });
      } catch (e) {
        _results.add({
          'filename': _imageFiles[i].path.split('/').last,
          'extracted': '[Error: $e]'
        });
      }
    }

    setState(() {
      _isProcessing = false;
      _processingStatus = '';
    });

    _showResultsDialog();
  }

  Future<String> _extractNumbersFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      String allText = recognizedText.text;

      // Extract numbers with more than 5 digits
      RegExp numberRegex = RegExp(r'\d+');
      Iterable<Match> matches = numberRegex.allMatches(allText);

      List<String> longNumbers = [];
      for (Match match in matches) {
        String number = match.group(0)!;
        if (number.length > 5) {
          longNumbers.add(number);
        }
      }

      if (longNumbers.isNotEmpty) {
        return longNumbers.join(' ');
      } else {
        return '[No numbers with 5+ digits found]';
      }
    } catch (e) {
      return '[Error: $e]';
    }
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'Extraction Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Image Filename')),
                      DataColumn(label: Text('Extracted Text')),
                    ],
                    rows: _results.map((row) {
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
                    onPressed: _saveResults,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
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

  Future<void> _saveResults() async {
    try {
      // Ask for directory path every time
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Folder to Save Results');
      if (selectedDirectory == null) return;

      final file = File('$selectedDirectory/ocr_results_${DateTime.now().millisecondsSinceEpoch}.txt');
      // Write as CSV-like two columns
      String content = 'Image Filename\tExtracted Text\n' +
          _results.map((row) => '${row['filename']}\t${row['extracted']}').join('\n');
      await file.writeAsString(content);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Results saved to ${file.path}')),
      );
    } catch (e) {
      _showErrorDialog('Error saving results: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Number Extractor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OCR Number Extractor',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Extract numbers (5+ digits) from images in ZIP folders or folders using offline OCR',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('1. Select a ZIP file or a folder containing images'),
                    Text('2. Crop the first image to define the area of interest (optional/future)'),
                    Text('3. The same crop area will be applied to all images (future)'),
                    Text('4. Only numbers with 5+ digits will be extracted'),
                    Text('5. Results are saved in two columns: filename and extracted text'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_processingStatus),
                    ],
                  ),
                ),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _pickZipFile,
                icon: const Icon(Icons.folder_zip),
                label: const Text('Select ZIP Folder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickImageFolder,
                icon: const Icon(Icons.folder),
                label: const Text('Select Images Folder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (_imageFiles.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Found ${_imageFiles.length} images',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (_results.isNotEmpty)
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Latest Results:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Image Filename')),
                                DataColumn(label: Text('Extracted Text')),
                              ],
                              rows: _results.map((row) {
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
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}