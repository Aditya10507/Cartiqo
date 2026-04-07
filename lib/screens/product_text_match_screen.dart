import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/mall_product.dart';
import '../providers/cart_provider.dart';
import '../services/storefront_api_service.dart';

class ProductTextMatchScreen extends StatefulWidget {
  final String mallId;

  const ProductTextMatchScreen({super.key, required this.mallId});

  @override
  State<ProductTextMatchScreen> createState() => _ProductTextMatchScreenState();
}

class _ProductTextMatchScreenState extends State<ProductTextMatchScreen> {
  final _storefrontApiService = StorefrontApiService();
  final _imagePicker = ImagePicker();
  final _textRecognizer = TextRecognizer();

  XFile? _photo;
  Uint8List? _photoBytes;
  bool _loading = false;
  bool _analysisComplete = false;
  bool _cameraOpened = false;
  String? _message;
  String _recognizedText = '';
  List<_ProductMatchCandidate> _matches = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_cameraOpened && mounted) {
        _cameraOpened = true;
        _pickImage();
      }
    });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      setState(() {
        _message =
            'Product image detection is currently available in the mobile app only.';
      });
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 1600,
    );

    if (picked == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    final photoBytes = await picked.readAsBytes();

    setState(() {
      _loading = true;
      _analysisComplete = false;
      _photo = picked;
      _photoBytes = photoBytes;
      _message = null;
      _recognizedText = '';
      _matches = const [];
    });

    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final recognized = await _textRecognizer.processImage(inputImage);
      final extractedText = recognized.text.trim();

      if (extractedText.isEmpty) {
        setState(() {
          _message =
              'We could not read enough text from this image. Try again with a clearer front-facing photo.';
        });
        return;
      }

      final products = await _storefrontApiService.fetchProducts(widget.mallId);
      final matches = _rankMatches(extractedText, products);

      setState(() {
        _recognizedText = extractedText;
        _matches = matches;
        _analysisComplete = true;
        _message = matches.isEmpty
            ? 'No close product matches found. Try again or use barcode search.'
            : 'Recommended products based on the detected pack text.';
      });
    } catch (e) {
      setState(() {
        _message = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_analysisComplete) {
            _photo = null;
            _photoBytes = null;
          }
        });
      }
    }
  }

  List<_ProductMatchCandidate> _rankMatches(
    String recognizedText,
    List<MallProduct> products,
  ) {
    final normalizedText = _normalize(recognizedText);
    final tokens = _tokenize(normalizedText);

    final matches = products
        .map((product) {
          final score = _scoreProduct(product, normalizedText, tokens);
          return _ProductMatchCandidate(product: product, score: score);
        })
        .where((candidate) => candidate.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return matches.take(5).toList();
  }

  int _scoreProduct(
    MallProduct product,
    String normalizedText,
    Set<String> textTokens,
  ) {
    var score = 0;

    final brand = _normalize(product.brand);
    final name = _normalize(product.name);
    final category = _normalize(product.category);
    final unit = _normalize(product.unit);
    final sizeText = _normalize(
      '${_trimTrailingZeros(product.weight)}${product.weightUnit}',
    );

    if (brand.isNotEmpty && normalizedText.contains(brand)) {
      score += 10;
    }

    if (name.isNotEmpty && normalizedText.contains(name)) {
      score += 18;
    }

    final brandTokens = _tokenize(brand);
    final nameTokens = _tokenize(name);
    final categoryTokens = _tokenize(category);
    final unitTokens = _tokenize(unit);
    final sizeTokens = _tokenize(sizeText);

    score += brandTokens.where(textTokens.contains).length * 4;
    score += nameTokens.where(textTokens.contains).length * 3;
    score += categoryTokens.where(textTokens.contains).length;
    score += unitTokens.where(textTokens.contains).length;
    score += sizeTokens.where(textTokens.contains).length * 2;

    if (sizeText.isNotEmpty && normalizedText.contains(sizeText)) {
      score += 6;
    }

    final productKeywords = <String>{
      ...brandTokens,
      ...nameTokens,
      ...sizeTokens,
    };

    final matchedKeywords = productKeywords.where(textTokens.contains).length;
    if (matchedKeywords >= 3) {
      score += 6;
    } else if (matchedKeywords == 2) {
      score += 3;
    }

    return score;
  }

  String _normalize(String value) {
    final lowered = value.toLowerCase();
    return lowered
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Set<String> _tokenize(String value) {
    return value
        .split(' ')
        .where((token) => token.length >= 2 && !_stopWords.contains(token))
        .toSet();
  }

  String _trimTrailingZeros(double value) {
    final text = value.toStringAsFixed(
      value.truncateToDouble() == value ? 0 : 2,
    );
    return text.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Find by Product Image'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _pickImage,
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: 'Retake',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: kIsWeb
                      ? const ColoredBox(
                          color: Color(0xFFEFEFF2),
                          child: Center(child: Text('Preview unavailable on web')),
                        )
                      : (_photoBytes == null
                          ? const ColoredBox(
                              color: Color(0xFFEFEFF2),
                              child: SizedBox.expand(),
                            )
                          : Image.memory(
                              _photoBytes!,
                              fit: BoxFit.cover,
                            )),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_loading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_message != null) ...[
              const SizedBox(height: 20),
              _InfoCard(message: _message!),
            ],
            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Text(_recognizedText),
              ),
            ],
            if (_matches.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Suggested Products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              ..._matches.map(_buildMatchCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(_ProductMatchCandidate candidate) {
    final product = candidate.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: product.imageUrl.trim().isEmpty
            ? const CircleAvatar(child: Icon(Icons.inventory_2_outlined))
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  product.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const CircleAvatar(child: Icon(Icons.broken_image_outlined)),
                ),
              ),
        title: Text(product.name),
        subtitle: Text(
          '${product.brand} • ${product.unit} • score ${candidate.score}',
        ),
        trailing: FilledButton(
          onPressed: () {
            context.read<CartProvider>().addOrIncrement(
                  CartItem(
                    productId: product.productId,
                    name: product.name,
                    barcode: product.barcode,
                    price: product.price.round(),
                    unit: product.unit,
                    imageUrl: product.imageUrl,
                  ),
                );
            if (!mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.name} added to cart'),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pop(context, product);
          },
          child: const Text('Add to Cart'),
        ),
      ),
    );
  }
}

class _ProductMatchCandidate {
  final MallProduct product;
  final int score;

  const _ProductMatchCandidate({
    required this.product,
    required this.score,
  });
}

class _InfoCard extends StatelessWidget {
  final String message;

  const _InfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(message),
    );
  }
}

const Set<String> _stopWords = {
  'and',
  'for',
  'the',
  'with',
  'pack',
  'pcs',
  'piece',
  'pieces',
  'original',
  'fresh',
  'new',
  'best',
  'since',
};
