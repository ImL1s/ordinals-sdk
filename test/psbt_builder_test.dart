import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:ordinals_sdk/ordinals_sdk.dart';

void main() {
  group('PSBTBuilder', () {
    group('createTextInscriptionScript', () {
      test('should create valid text inscription envelope', () {
        final script =
            PSBTBuilder.createTextInscriptionScript('Hello, Ordinals!');

        expect(script, isNotNull);
        expect(script.length, greaterThan(0));

        // Check envelope format: OP_FALSE (0x00), OP_IF (0x63)
        expect(script[0], equals(0x00));
        expect(script[1], equals(0x63));

        // Check "ord" marker (0x03 = push 3 bytes, then 'o', 'r', 'd')
        expect(script[2], equals(0x03));
        expect(script[3], equals('o'.codeUnitAt(0)));
        expect(script[4], equals('r'.codeUnitAt(0)));
        expect(script[5], equals('d'.codeUnitAt(0)));

        // Check OP_ENDIF (0x68) at end
        expect(script.last, equals(0x68));
      });

      test('should include content type in envelope', () {
        final script = PSBTBuilder.createTextInscriptionScript('Test');

        // Find "text/plain" in the script
        final textPlain = 'text/plain'.codeUnits;
        var found = false;
        for (var i = 0; i < script.length - textPlain.length; i++) {
          var match = true;
          for (var j = 0; j < textPlain.length; j++) {
            if (script[i + j] != textPlain[j]) {
              match = false;
              break;
            }
          }
          if (match) {
            found = true;
            break;
          }
        }
        expect(found, isTrue,
            reason: 'Content type "text/plain" not found in script');
      });
    });

    group('createImageInscriptionScript', () {
      test('should create valid image inscription envelope', () {
        final imageData =
            Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
        final script =
            PSBTBuilder.createImageInscriptionScript(imageData, 'image/png');

        expect(script, isNotNull);
        expect(script[0], equals(0x00)); // OP_FALSE
        expect(script[1], equals(0x63)); // OP_IF
        expect(script.last, equals(0x68)); // OP_ENDIF
      });
    });

    group('createJsonInscriptionScript', () {
      test('should create valid BRC-20 inscription', () {
        final json = {
          'p': 'brc-20',
          'op': 'deploy',
          'tick': 'test',
          'max': '21000000',
          'lim': '1000',
        };

        final script = PSBTBuilder.createJsonInscriptionScript(json);

        expect(script, isNotNull);
        expect(script[0], equals(0x00)); // OP_FALSE
        expect(script[1], equals(0x63)); // OP_IF
        expect(script.last, equals(0x68)); // OP_ENDIF

        // Check for "application/json" content type
        final contentType = 'application/json'.codeUnits;
        var found = false;
        for (var i = 0; i < script.length - contentType.length; i++) {
          var match = true;
          for (var j = 0; j < contentType.length; j++) {
            if (script[i + j] != contentType[j]) {
              match = false;
              break;
            }
          }
          if (match) {
            found = true;
            break;
          }
        }
        expect(found, isTrue);
      });

      test('should include BRC-20 data in envelope', () {
        final json = {
          'p': 'brc-20',
          'op': 'mint',
          'tick': 'ordi',
          'amt': '1000',
        };

        final script = PSBTBuilder.createJsonInscriptionScript(json);
        final scriptStr = String.fromCharCodes(script);

        // Check that the JSON content is embedded
        expect(scriptStr, contains('brc-20'));
        expect(scriptStr, contains('mint'));
        expect(scriptStr, contains('ordi'));
      });
    });

    group('dustAmount', () {
      test('should be 546 satoshis', () {
        expect(PSBTBuilder.dustAmount, equals(546));
      });
    });
  });
}
