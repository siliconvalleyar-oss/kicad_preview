import 'package:flutter_test/flutter_test.dart';
import 'package:kicad_preview/models/pcb.dart';
import 'package:kicad_preview/models/pcb_element.dart';
import 'package:flutter/material.dart' show Color;

void main() {
  group('PCBLayer', () {
    test('creates a layer with required fields', () {
      final layer = PCBLayer(id: 0, name: 'F.Cu', type: 'signal');
      expect(layer.id, 0);
      expect(layer.name, 'F.Cu');
      expect(layer.type, 'signal');
      expect(layer.visible, true);
      expect(layer.defaultColor, const Color(0xFF000000));
    });

    test('color returns correct KiCad color for known layers', () {
      final fcu = PCBLayer(id: 0, name: 'F.Cu', type: 'signal');
      expect(fcu.color, const Color(0xFFFF0000));

      final bcu = PCBLayer(id: 2, name: 'B.Cu', type: 'signal');
      expect(bcu.color, const Color(0xFF0000FF));

      final edgeCuts = PCBLayer(id: 25, name: 'Edge.Cuts', type: 'user');
      expect(edgeCuts.color, const Color(0xFFFFA500));
    });

    test('color returns black for unknown layer ids', () {
      final unknown = PCBLayer(id: 999, name: 'Unknown', type: 'user');
      expect(unknown.color, const Color(0xFF000000));
    });

    test('visible can be toggled', () {
      final layer = PCBLayer(id: 0, name: 'F.Cu', type: 'signal');
      expect(layer.visible, true);
      layer.visible = false;
      expect(layer.visible, false);
    });

    test('kicadLayerColors contains standard KiCad colors', () {
      expect(PCBLayer.kicadLayerColors[0], const Color(0xFFFF0000)); // F.Cu
      expect(PCBLayer.kicadLayerColors[2], const Color(0xFF0000FF)); // B.Cu
      expect(PCBLayer.kicadLayerColors[5], const Color(0xFFFFFF00)); // F.SilkS
      expect(PCBLayer.kicadLayerColors[7], const Color(0xFF00FFFF)); // B.SilkS
    });
  });

  group('PCBFootprint', () {
    test('creates a footprint with required fields', () {
      final fp = const PCBFootprint(reference: 'R1', value: '10K');
      expect(fp.reference, 'R1');
      expect(fp.value, '10K');
      expect(fp.x, 0);
      expect(fp.y, 0);
      expect(fp.rotation, 0);
      expect(fp.pads, []);
      expect(fp.lines, []);
      expect(fp.texts, []);
    });

    test('creates a footprint with position', () {
      const fp = PCBFootprint(
        reference: 'U1',
        value: 'ATmega328',
        x: 100.5,
        y: 200.3,
        rotation: 90,
      );
      expect(fp.x, 100.5);
      expect(fp.y, 200.3);
      expect(fp.rotation, 90);
    });

    test('creates a footprint with pads', () {
      final fp = PCBFootprint(
        reference: 'C1',
        value: '100nF',
        pads: [
          const PCBPad(number: '1', net: 'GND'),
          const PCBPad(number: '2', net: 'VCC'),
        ],
      );
      expect(fp.pads.length, 2);
      expect(fp.pads[0].net, 'GND');
      expect(fp.pads[1].number, '2');
    });
  });

  group('PCBPad', () {
    test('creates a pad with defaults', () {
      const pad = PCBPad(number: '1');
      expect(pad.number, '1');
      expect(pad.x, 0);
      expect(pad.y, 0);
      expect(pad.sizeX, 1);
      expect(pad.sizeY, 1);
      expect(pad.type, 'smd');
      expect(pad.shape, 'rect');
      expect(pad.layers, ['F.Cu']);
      expect(pad.net, isNull);
      expect(pad.drill, isNull);
    });

    test('creates a through-hole pad', () {
      const pad = PCBPad(
        number: '1',
        x: 10,
        y: 20,
        sizeX: 1.7,
        sizeY: 1.7,
        drill: 1.0,
        type: 'thru_hole',
        shape: 'circle',
        layers: ['*.Cu', '*.Mask'],
        net: 'GND',
      );
      expect(pad.drill, 1.0);
      expect(pad.type, 'thru_hole');
      expect(pad.shape, 'circle');
      expect(pad.layers.length, 2);
      expect(pad.net, 'GND');
    });
  });

  group('PCBGraphicalLine', () {
    test('creates a graphical line', () {
      const line = PCBGraphicalLine(
        x1: 0, y1: 0,
        x2: 100, y2: 50,
        layer: 'F.SilkS',
      );
      expect(line.x1, 0);
      expect(line.y1, 0);
      expect(line.x2, 100);
      expect(line.y2, 50);
      expect(line.width, 0.12);
      expect(line.layer, 'F.SilkS');
    });

    test('creates with custom width and uuid', () {
      const line = PCBGraphicalLine(
        x1: 10, y1: 20,
        x2: 30, y2: 40,
        width: 0.5,
        layer: 'Edge.Cuts',
        uuid: 'line-uuid',
      );
      expect(line.width, 0.5);
      expect(line.uuid, 'line-uuid');
    });
  });

  group('PCBGraphicalText', () {
    test('creates a graphical text', () {
      const text = PCBGraphicalText(
        text: 'R1',
        x: 50, y: 60,
        layer: 'F.SilkS',
      );
      expect(text.text, 'R1');
      expect(text.x, 50);
      expect(text.y, 60);
      expect(text.size, 1);
      expect(text.rotation, 0);
      expect(text.layer, 'F.SilkS');
    });

    test('creates text with rotation', () {
      const text = PCBGraphicalText(
        text: 'REF**',
        x: 100, y: 200,
        rotation: 90,
        layer: 'F.Fab',
      );
      expect(text.rotation, 90);
    });
  });

  group('PCBTrack', () {
    test('creates a track with defaults', () {
      const track = PCBTrack(
        x1: 0, y1: 0,
        x2: 100, y2: 0,
        layer: 'F.Cu',
      );
      expect(track.width, 0.25);
      expect(track.net, isNull);
    });

    test('creates a track with net', () {
      const track = PCBTrack(
        x1: 50, y1: 50,
        x2: 150, y2: 50,
        width: 0.5,
        layer: 'F.Cu',
        net: 'GND',
        uuid: 'track-uuid',
      );
      expect(track.width, 0.5);
      expect(track.net, 'GND');
      expect(track.uuid, 'track-uuid');
    });
  });

  group('PCBVia', () {
    test('creates a via with defaults', () {
      const via = PCBVia(x: 100, y: 100);
      expect(via.x, 100);
      expect(via.y, 100);
      expect(via.diameter, 0.8);
      expect(via.drill, 0.4);
      expect(via.layers, ['F.Cu', 'B.Cu']);
      expect(via.net, isNull);
    });

    test('creates a via with custom values', () {
      const via = PCBVia(
        x: 200, y: 300,
        diameter: 1.2,
        drill: 0.7,
        layers: ['F.Cu', 'In1.Cu', 'B.Cu'],
        net: '+3.3V',
      );
      expect(via.diameter, 1.2);
      expect(via.drill, 0.7);
      expect(via.layers.length, 3);
      expect(via.net, '+3.3V');
    });
  });

  group('PCB', () {
    test('creates a PCB with required fileName', () {
      const pcb = PCB(fileName: 'test.kicad_pcb');
      expect(pcb.fileName, 'test.kicad_pcb');
      expect(pcb.version, '');
      expect(pcb.generator, '');
      expect(pcb.thickness, 1.6);
      expect(pcb.paper, 'A4');
      expect(pcb.layers, []);
      expect(pcb.footprints, []);
      expect(pcb.tracks, []);
      expect(pcb.vias, []);
    });

    test('creates a PCB with all fields', () {
      final pcb = PCB(
        fileName: 'board.kicad_pcb',
        version: '20260206',
        generator: 'pcbnew',
        thickness: 1.6,
        paper: 'A4',
        layers: [
          PCBLayer(id: 0, name: 'F.Cu', type: 'signal'),
          PCBLayer(id: 2, name: 'B.Cu', type: 'signal'),
        ],
        footprints: [
          const PCBFootprint(reference: 'R1', value: '10K'),
        ],
        tracks: [
          const PCBTrack(x1: 0, y1: 0, x2: 10, y2: 0, layer: 'F.Cu'),
        ],
        vias: [
          const PCBVia(x: 5, y: 5),
        ],
      );
      expect(pcb.version, '20260206');
      expect(pcb.generator, 'pcbnew');
      expect(pcb.footprints.length, 1);
      expect(pcb.tracks.length, 1);
      expect(pcb.vias.length, 1);
    });

    test('getLayerById returns correct layer', () {
      final pcb = PCB(
        fileName: 'test.kicad_pcb',
        layers: [
          PCBLayer(id: 0, name: 'F.Cu', type: 'signal'),
          PCBLayer(id: 2, name: 'B.Cu', type: 'signal'),
          PCBLayer(id: 5, name: 'F.SilkS', type: 'user'),
        ],
      );
      final layer = pcb.getLayerById(5);
      expect(layer, isNotNull);
      expect(layer!.name, 'F.SilkS');
    });

    test('getLayerById returns null for unknown id', () {
      final pcb = PCB(
        fileName: 'test.kicad_pcb',
        layers: [
          PCBLayer(id: 0, name: 'F.Cu', type: 'signal'),
        ],
      );
      expect(pcb.getLayerById(999), isNull);
    });

    test('visibleLayers returns only visible layers', () {
      final pcb = PCB(
        fileName: 'test.kicad_pcb',
        layers: [
          PCBLayer(id: 0, name: 'F.Cu', type: 'signal')..visible = true,
          PCBLayer(id: 2, name: 'B.Cu', type: 'signal')..visible = false,
          PCBLayer(id: 5, name: 'F.SilkS', type: 'user')..visible = true,
        ],
      );
      expect(pcb.visibleLayers.length, 2);
      expect(pcb.visibleLayers[0].name, 'F.Cu');
      expect(pcb.visibleLayers[1].name, 'F.SilkS');
    });
  });
}
