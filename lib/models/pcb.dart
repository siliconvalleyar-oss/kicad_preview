import 'pcb_element.dart';

class PCB {
  final String fileName;
  final String version;
  final String generator;
  final double thickness;
  final String paper;
  final List<PCBLayer> layers;
  final List<PCBFootprint> footprints;
  final List<PCBTrack> tracks;
  final List<PCBVia> vias;
  final List<PCBGraphicalLine> graphicalLines;
  final List<PCBGraphicalText> graphicalTexts;

  const PCB({
    required this.fileName,
    this.version = '',
    this.generator = '',
    this.thickness = 1.6,
    this.paper = 'A4',
    this.layers = const [],
    this.footprints = const [],
    this.tracks = const [],
    this.vias = const [],
    this.graphicalLines = const [],
    this.graphicalTexts = const [],
  });

  PCBLayer? getLayerById(int id) {
    try {
      return layers.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  List<PCBLayer> get visibleLayers =>
      layers.where((l) => l.visible).toList();
}
