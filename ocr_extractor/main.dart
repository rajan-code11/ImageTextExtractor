import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';

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
  List<String> _results = [];

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

  Future<void> _extractImagesFromZip(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    
    List<File> imageFiles = [];
    final tempDir = await getTemporaryDirectory();
    
    for (final file in archive) {
      if (file.isFile) {
        final filename = file.name.toLowerCase();
        if (filename.endsWith('.jpg') || 
            filename.endsWith('.jpeg') || 
            filename.endsWith('.png') || 
            filename.endsWith('.bmp') || 
            filename.endsWith('.tiff') || 
            filename.endsWith('.webp')) {
          
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
      
      // Show confirmation dialog instead of cropping for now
      _showProcessDialog();
    } else {
      _showErrorDialog('No image files found in ZIP');
    }
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
        final result = await _extractNumbersFromImage(_imageFiles[i]);
        _results.add('${_imageFiles[i].path.split('/').last} $result');
      } catch (e) {
        _results.add('${_imageFiles[i].path.split('/').last} [Error: $e]');
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
                  child: Text(
                    _results.join('     '),
                    style: const TextStyle(fontSize: 14),
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
      final directory = await getExternalStorageDirectory();
      final file = File('${directory!.path}/ocr_results_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(_results.join('     '));
      
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
                      'Extract numbers (5+ digits) from images in ZIP folders using offline OCR',
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
                    Text('1. Select a ZIP file containing images'),
                    Text('2. Crop the first image to define the area of interest'),
                    Text('3. The same crop area will be applied to all images'),
                    Text('4. Only numbers with 5+ digits will be extracted'),
                    Text('5. Results are saved in the specified format'),
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
            else
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
            const SizedBox(height: 20),
            if (_imageFiles.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Found ${_imageFiles.length} images in ZIP file',
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
                            child: Text(
                              _results.join('     '),
                              style: const TextStyle(fontSize: 14),
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