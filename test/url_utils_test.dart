// mmuraker – a community derivative app inspired by mobileraker.
// mmuraker is Copyright (c) 2025 mmuraker contributors (same non-commercial license).
// See LICENSE and NOTICE for full attribution and terms.

import 'package:flutter_test/flutter_test.dart';
import 'package:mmuraker/util/url_utils.dart';

void main() {
  group('coerceHttpUrl', () {
    test('passes through a fully-qualified http URL unchanged', () {
      expect(coerceHttpUrl('http://192.168.1.100'), 'http://192.168.1.100');
    });

    test('passes through a fully-qualified https URL unchanged', () {
      expect(
        coerceHttpUrl('https://myprinter.local:7125'),
        'https://myprinter.local:7125',
      );
    });

    test('passes through a ws URL unchanged (non-http scheme)', () {
      expect(
        coerceHttpUrl('ws://192.168.1.100/websocket'),
        'ws://192.168.1.100/websocket',
      );
    });

    test('prepends http:// to a bare IP address', () {
      expect(coerceHttpUrl('192.168.1.100'), 'http://192.168.1.100');
    });

    test('prepends http:// to a bare IP with port', () {
      expect(coerceHttpUrl('192.168.1.100:7125'), 'http://192.168.1.100:7125');
    });

    test('prepends http:// to a bare hostname', () {
      expect(coerceHttpUrl('myprinter.local'), 'http://myprinter.local');
    });

    test('prepends http:// to a hostname with port', () {
      expect(
        coerceHttpUrl('myprinter.local:7125'),
        'http://myprinter.local:7125',
      );
    });

    test('trims surrounding whitespace before coercing', () {
      expect(coerceHttpUrl('  192.168.1.100  '), 'http://192.168.1.100');
    });

    test('returns empty string for blank input', () {
      expect(coerceHttpUrl(''), '');
      expect(coerceHttpUrl('   '), '');
    });
  });

  group('extractMoonrakerWebcamUrl', () {
    test('prefers snapshot urls when both snapshot and stream are present', () {
      final url = extractMoonrakerWebcamUrl('http://printer.local:7125', {
        'webcams': [
          {
            'stream_url': '/webcam/?action=stream',
            'snapshot_url': '/webcam/?action=snapshot',
          },
        ],
      });

      expect(url, 'http://printer.local:7125/webcam/?action=snapshot');
    });

    test('resolves relative stream urls from webcam list responses', () {
      final url = extractMoonrakerWebcamUrl('http://printer.local:7125', {
        'webcams': [
          {'stream_url': '/webcam/?action=stream'},
        ],
      });

      expect(url, 'http://printer.local:7125/webcam/?action=stream');
    });

    test('supports database-style webcam payloads', () {
      final url = extractMoonrakerWebcamUrl('http://192.168.1.50:7125', {
        'result': {
          'value': {
            'cam1': {'snapshotUrl': '/webcam/?action=snapshot'},
          },
        },
      });

      expect(url, 'http://192.168.1.50:7125/webcam/?action=snapshot');
    });

    test('supports nested database payloads with webcams key', () {
      final url = extractMoonrakerWebcamUrl('http://printer.local:7125', {
        'result': {
          'value': {
            'webcams': {
              'cam1': {'stream_url': '/webcam/?action=stream'},
            },
          },
        },
      });

      expect(url, 'http://printer.local:7125/webcam/?action=stream');
    });
  });
}
