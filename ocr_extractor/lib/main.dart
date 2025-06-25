import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(const OCRApp());
}

class OCRApp extends StatelessWidget {
  const OCRApp({super.key});

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
  const OCRHomePage({super.key});

  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  List<File> _imageFiles = [];
  bool _isProcessing = false;
  String _status = '';
  List<String> _results = [];

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.storage.request();
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<void> _pickZipFile() async {
    await _requestPermissions();
    
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _isProcessing = true;
        _status = 'Extracting images...';
      });

      try {
        await _extractImages(result.files.single.path!);
        await _processImages();
      } catch (e) {
        _showError('Error: $e');
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _extractImages(String zipPath) async {
    final bytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final tempDir = await getTemporaryDirectory();
    
    List<File> imageFiles = [];
    
    for (final file in archive) {
      if (file.isFile) {
        final name = file.name.toLowerCase();
        if (name.endsWith('.jpg') || name.endsWith('.jpeg') || 
            name.endsWith('.png') || name.endsWith('.bmp') || 
            name.endsWith('.tiff') || name.endsWith('.webp')) {
          
          final data = file.content as List<int>;
          final imageFile = File('${tempDir.path}/${file.name}');
          await imageFile.create(recursive: true);
          await imageFile.writeAsBytes(data);
          imageFiles.add(imageFile);
        }
      }
    }
    
    setState(() {
      _imageFiles = imageFiles;
    });
  }

  Future<void> _processImages() async {
    if (_imageFiles.isEmpty) return;
    
    List<String> results = [];
    
    for (int i = 0; i < _imageFiles.length; i++) {
      setState(() {
        _status = 'Processing ${i + 1}/${_imageFiles.length}...';
      });
      
      try {
        final filename = _imageFiles[i].path.split('/').last;
        final numbers = await _extractNumbers(_imageFiles[i]);
        results.add('$filename, $numbers');
      } catch (e) {
        final filename = _imageFiles[i].path.split('/').last;
        results.add('$filename [Error]');
      }
    }
    
    setState(() {
      _results = results;
    });
    
    _showResults();
  }

  Future<String> _extractNumbers(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    
    final RegExp numberRegex = RegExp(r'\d+');
    final matches = numberRegex.allMatches(recognizedText.text);
    
    List<String> longNumbers = [];
    for (final match in matches) {
      final number = match.group(0)!;
      if (number.length > 5) {
        longNumbers.add(number);
      }
    }
    
    return longNumbers.isNotEmpty ? longNumbers.join(' ') : '[No numbers]';
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: SingleChildScrollView(
            child: Text(_results.join('     ')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: _saveResults,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveResults() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final file = File('${directory.path}/ocr_results.txt');
        await file.writeAsString(_results.join('     '));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to ${file.path}')),
          );
        }
      }
    } catch (e) {
      _showError('Save error: $e');
    }
  }

  void _showError(String message) {
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OCR Number Extractor',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Extract numbers (5+ digits) from images in ZIP folders',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text('How it works:'),
                    const Text('1. Select ZIP file with images'),
                    const Text('2. Extract numbers with 5+ digits'),
                    const Text('3. Save results in specified format'),
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
                      Text(_status),
                    ],
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _pickZipFile,
                icon: const Icon(Icons.folder_zip),
                label: const Text('Select ZIP File'),
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
                    'Found ${_imageFiles.length} images',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (_results.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Processing Complete!',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Processed ${_results.length} images'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _showResults,
                        child: const Text('View Results'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}