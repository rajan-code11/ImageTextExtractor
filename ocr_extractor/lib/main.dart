import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;
import 'image_preprocessor.dart';
import 'dart:io';

void main() {
  runApp(const OCRNumberExtractorApp());
}

enum ExtractionMode {
  words,
  numbers,
  everything,
  numbers5Plus,
}

class OCRNumberExtractorApp extends StatelessWidget {
  const OCRNumberExtractorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCR Extractor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        cardTheme: CardTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 6,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            elevation: 4,
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: OCRHomePage(),
    );
  }
}

class OCRHomePage extends StatefulWidget {
  @override
  State<OCRHomePage> createState() => _OCRHomePageState();
}

class _OCRHomePageState extends State<OCRHomePage> {
  final TextRecognizer _textRecognizer = TextRecognizer();
  List<File> _imageFiles = [];
  bool _isProcessing = false;
  String _processingStatus = '';
  List<Map<String, String>> _results = [];
  ExtractionMode _extractionMode = ExtractionMode.words;
  bool _expandExtraction = false; // for ExpansionTile
  List<Map<String, String>> _txtResults = [];
  bool _usePreprocessing = true; // Toggle for preprocessing

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
        content: Text('Found ${_imageFiles.length} images. Process all images?'),
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
        final text = await _extractTextFromImage(_imageFiles[i]);
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
    // Sort by filename
    _results.sort((a, b) => a['filename']!.compareTo(b['filename']!));
    setState(() {
      _isProcessing = false;
      _processingStatus = '';
    });
    _showResultsDialog(_results, "Extraction Results");
  }

  Future<String> _extractTextFromImage(File imageFile) async {
    try {
      File fileForOcr = imageFile;
      File? tempPreprocessed;
      if (_usePreprocessing) {
        tempPreprocessed = await ImagePreprocessor.preprocess(imageFile);
        fileForOcr = tempPreprocessed;
      }
      final inputImage = InputImage.fromFile(fileForOcr);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      String allText = recognizedText.text;
      debugPrint('Recognized text: ' + allText);
      // Clean up temp file if used
      if (tempPreprocessed != null && tempPreprocessed.path != imageFile.path) {
        try { await tempPreprocessed.delete(); } catch (_) {}
      }
      switch (_extractionMode) {
        case ExtractionMode.words:
          RegExp wordRegex = RegExp(r'\b([A-Za-z]+)\b');
          Iterable<Match> matches = wordRegex.allMatches(allText);
          List<String> words = matches.map((m) => m.group(0)!).toList();
          return words.isNotEmpty ? words.join(' ') : '[No words found]';
        case ExtractionMode.numbers:
          RegExp numRegex = RegExp(r'\d+');
          Iterable<Match> matches = numRegex.allMatches(allText);
          List<String> numbers = matches.map((m) => m.group(0)!).toList();
          return numbers.isNotEmpty ? numbers.join(' ') : '[No numbers found]';
        case ExtractionMode.everything:
          return allText.isNotEmpty ? allText : '[No text found]';
        case ExtractionMode.numbers5Plus:
          RegExp num5Regex = RegExp(r'\d{6,}');
          Iterable<Match> matches = num5Regex.allMatches(allText);
          List<String> longNumbers = matches.map((m) => m.group(0)!).toList();
          return longNumbers.isNotEmpty ? longNumbers.join(' ') : '[No numbers with 6+ digits found]';
      }
    } catch (e) {
      return '[Error: $e]';
    }
  }

  Future<void> _pickTxtFileAndExtractNumbers() async {
    await _requestPermissions();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    if (result != null) {
      setState(() {
        _isProcessing = true;
        _processingStatus = 'Processing TXT file...';
        _txtResults.clear();
      });
      File txtFile = File(result.files.single.path!);
      String content = await txtFile.readAsString();
      RegExp num6Regex = RegExp(r'\d{7,}');
      Iterable<Match> matches = num6Regex.allMatches(content);
      List<String> foundNumbers =
          matches.map((m) => m.group(0)!).toSet().toList(); // Unique numbers
      foundNumbers.sort();
      for (String number in foundNumbers) {
        _txtResults.add({'filename': txtFile.path.split('/').last, 'extracted': number});
      }
      setState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
      _showResultsDialog(_txtResults, "TXT Fix (7+ digit numbers)");
    }
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
                    onPressed: () => _saveResults(results),
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

  Future<void> _saveResults(List<Map<String, String>> results) async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select Folder to Save Results');
      if (selectedDirectory == null) return;
      final file = File('$selectedDirectory/ocr_results_${DateTime.now().millisecondsSinceEpoch}.txt');
      String content = 'Image Filename\tExtracted Text\n' +
          results.map((row) => '${row['filename']}\t${row['extracted']}').join('\n');
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

  Widget _buildExpandableExtractionModeSelector() {
    return Card(
      child: ExpansionTile(
        initiallyExpanded: _expandExtraction,
        onExpansionChanged: (expanded) {
          setState(() {
            _expandExtraction = expanded;
          });
        },
        title: Text(
          'Extraction Mode (${_getExtractionModeName(_extractionMode)})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          RadioListTile<ExtractionMode>(
            title: const Text('Only Words (No numbers)'),
            value: ExtractionMode.words,
            groupValue: _extractionMode,
            onChanged: (ExtractionMode? value) {
              setState(() {
                _extractionMode = value!;
              });
            },
          ),
          RadioListTile<ExtractionMode>(
            title: const Text('Only Numbers'),
            value: ExtractionMode.numbers,
            groupValue: _extractionMode,
            onChanged: (ExtractionMode? value) {
              setState(() {
                _extractionMode = value!;
              });
            },
          ),
          RadioListTile<ExtractionMode>(
            title: const Text('Everything (Words & Numbers)'),
            value: ExtractionMode.everything,
            groupValue: _extractionMode,
            onChanged: (ExtractionMode? value) {
              setState(() {
                _extractionMode = value!;
              });
            },
          ),
          RadioListTile<ExtractionMode>(
            title: const Text('6+ Digit Numbers Only'),
            value: ExtractionMode.numbers5Plus,
            groupValue: _extractionMode,
            onChanged: (ExtractionMode? value) {
              setState(() {
                _extractionMode = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  String _getExtractionModeName(ExtractionMode mode) {
    switch (mode) {
      case ExtractionMode.words:
        return "Only Words";
      case ExtractionMode.numbers:
        return "Only Numbers";
      case ExtractionMode.everything:
        return "Everything";
      case ExtractionMode.numbers5Plus:
        return "6+ Digit Numbers Only";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.text_fields_rounded, color: Colors.deepPurple, size: 32),
            const SizedBox(width: 10),
            const Text('OCR Extractor'),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.deepPurple,
        shadowColor: Colors.transparent,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFe0c3fc), Color(0xFF8ec5fc)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Card(
                color: Colors.white.withOpacity(0.95),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 32),
                          const SizedBox(width: 10),
                          Text(
                            'OCR Extractor',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Extract text or numbers from images in ZIP folders or image folders using offline OCR.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: _buildExpandableExtractionModeSelector(),
              ),
              const SizedBox(height: 20),
              if (_isProcessing)
                Card(
                  color: Colors.deepPurple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        AnimatedRotation(
                          turns: _isProcessing ? 1 : 0,
                          duration: const Duration(seconds: 2),
                          child: const Icon(Icons.autorenew_rounded, size: 48, color: Colors.deepPurple),
                        ),
                        const SizedBox(height: 16),
                        Text(_processingStatus, style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    ),
                  ),
                )
              else ...[
                AnimatedButton(
                  onPressed: _pickZipFile,
                  icon: Icons.folder_zip_rounded,
                  label: 'Select ZIP Folder',
                  color: Colors.deepPurple,
                ),
                const SizedBox(height: 16),
                AnimatedButton(
                  onPressed: _pickImageFolder,
                  icon: Icons.folder_open_rounded,
                  label: 'Select Images Folder',
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                AnimatedButton(
                  onPressed: _pickTxtFileAndExtractNumbers,
                  icon: Icons.text_snippet_rounded,
                  label: 'Fix TXT File (Find 7+ digit numbers)',
                  color: Colors.green,
                ),
              ],
              const SizedBox(height: 20),
              if (_imageFiles.isNotEmpty)
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.image_rounded, color: Colors.green, size: 28),
                        const SizedBox(width: 10),
                        Text(
                          'Found _imageFiles.length} images',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              Row(
                children: [
                  Switch(
                    value: _usePreprocessing,
                    onChanged: (v) => setState(() => _usePreprocessing = v),
                  ),
                  const Text('Use Image Preprocessing'),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this widget at the end of the file:
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  const AnimatedButton({super.key, required this.onPressed, required this.icon, required this.label, required this.color});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.0, upperBound: 0.08);
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
