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

  @override
  void initState() {
    super.initState();
    // Initialize selection map for all outfit items
    for (var item in widget.outfitMorning + widget.outfitAfternoon + widget.outfitNight) {
      _selected[item] = false;
    }
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        ...items.map((item) {
          return CheckboxListTile(
            title: Text(item),
            value: _selected[item],
            onChanged: (val) {
              setState(() {
                _selected[item] = val!;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          );
        }),
        SizedBox(height: 16),
      ],
    );
  }

  Future<void> _saveOutfit() async {
    final chosenItems = _selected.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    final record = OutfitRecord(
      date: DateTime.now(),
      temp: widget.actualTemp,
      uvIndex: widget.uvIndex,
      precipitationMm: widget.precipitationMm,
      precipitationProb: widget.precipitationProb,
      items: chosenItems,
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
              _buildSection('👕 Morning', widget.outfitMorning),
              _buildSection('🌞 Afternoon', widget.outfitAfternoon),
              _buildSection('🌙 Night', widget.outfitNight),
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
