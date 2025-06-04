import 'package:flutter/material.dart';
import 'storage_service.dart';
import 'outfit_record.dart';

class WardrobePage extends StatefulWidget {
  final double actualTemp;
  final int uvIndex;
  final double precipitationMm;
  final int precipitationProb;
  final List<String> outfitMorning;
  final List<String> outfitAfternoon;
  final List<String> outfitNight;

  const WardrobePage({
    super.key,
    required this.actualTemp,
    required this.uvIndex,
    required this.precipitationMm,
    required this.precipitationProb,
    required this.outfitMorning,
    required this.outfitAfternoon,
    required this.outfitNight,
  });

  @override
  _WardrobePageState createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  final Map<String, bool> _selected = {};
  Map<String, List<String>> _wardrobe = {
    'tops': [],
    'bottoms': [],
    'shoes': [],
    'outerwear': [],
    'accessories': [],
  };

  final TextEditingController _morningCtrl = TextEditingController();
  final TextEditingController _afternoonCtrl = TextEditingController();
  final TextEditingController _nightCtrl = TextEditingController();

  final Map<String, TextEditingController> _controllers = {
    'tops': TextEditingController(),
    'bottoms': TextEditingController(),
    'shoes': TextEditingController(),
    'outerwear': TextEditingController(),
    'accessories': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _morningCtrl.text = widget.outfitMorning.join(', ');
    _afternoonCtrl.text = widget.outfitAfternoon.join(', ');
    _nightCtrl.text = widget.outfitNight.join(', ');
    _loadWardrobe();
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    _morningCtrl.dispose();
    _afternoonCtrl.dispose();
    _nightCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWardrobe() async {
    final data = await StorageService.loadWardrobe();
    setState(() {
      _wardrobe = data;
      for (var list in _wardrobe.values) {
        for (var item in list) {
          _selected[item] = false;
        }
      }
    });
  }

  Widget _buildSection(String title, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Comma separated items'),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategory(String label, String key) {
    final items = _wardrobe[key] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ...items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Row(
            children: [
              Checkbox(
                value: _selected[item] ?? false,
                onChanged: (val) {
                  setState(() {
                    _selected[item] = val!;
                  });
                },
              ),
              Expanded(child: Text(item)),
              IconButton(
                icon: Icon(Icons.edit, size: 20),
                onPressed: () => _editItem(key, idx),
              ),
              IconButton(
                icon: Icon(Icons.delete, size: 20),
                onPressed: () => _deleteItem(key, idx),
              ),
            ],
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controllers[key],
                decoration: InputDecoration(hintText: 'Add item'),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _addItem(key),
            ),
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  void _addItem(String key) {
    final text = _controllers[key]!.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _wardrobe[key]!.add(text);
      _selected[text] = false;
      _controllers[key]!.clear();
    });
    StorageService.saveWardrobe(_wardrobe);
  }

  void _editItem(String key, int index) async {
    final current = _wardrobe[key]![index];
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Item'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _wardrobe[key]![index] = result;
        _selected.remove(current);
        _selected[result] = false;
      });
      StorageService.saveWardrobe(_wardrobe);
    }
  }

  void _deleteItem(String key, int index) {
    final item = _wardrobe[key]![index];
    setState(() {
      _wardrobe[key]!.removeAt(index);
      _selected.remove(item);
    });
    StorageService.saveWardrobe(_wardrobe);
  }

  Future<void> _saveOutfit() async {
    final chosenItems = _selected.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    List<String> parseManual(TextEditingController c) {
      return c.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final manualItems = [
      ...parseManual(_morningCtrl),
      ...parseManual(_afternoonCtrl),
      ...parseManual(_nightCtrl),
    ];

    final allItems = {...chosenItems, ...manualItems}.toList();

    final record = OutfitRecord(
      date: DateTime.now(),
      temp: widget.actualTemp,
      uvIndex: widget.uvIndex,
      precipitationMm: widget.precipitationMm,
      precipitationProb: widget.precipitationProb,
      items: allItems,
    );

    await StorageService.saveRecord(record);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Outfit saved! 🎉')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record Today’s Outfit')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Temp: ${widget.actualTemp.toStringAsFixed(1)}°F  ·  UV: ${widget.uvIndex}  ·  Rain: ${widget.precipitationMm.toStringAsFixed(1)} mm (${widget.precipitationProb}%)',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              _buildSection('👕 Morning', _morningCtrl),
              _buildSection('🌞 Afternoon', _afternoonCtrl),
              _buildSection('🌙 Night', _nightCtrl),
              Divider(height: 32),
              _buildCategory('Tops', 'tops'),
              _buildCategory('Bottoms', 'bottoms'),
              _buildCategory('Shoes', 'shoes'),
              _buildCategory('Outerwear', 'outerwear'),
              _buildCategory('Accessories', 'accessories'),
              ElevatedButton(
                onPressed: _saveOutfit,
                child: Text('Save Today’s Outfit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
