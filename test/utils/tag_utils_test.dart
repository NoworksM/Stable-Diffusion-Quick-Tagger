import 'package:quick_tagger/data/tagfile_type.dart';
import 'package:test/test.dart';

import 'package:quick_tagger/utils/tag_utils.dart' as tutils;

const _spaceAndLineBreakExample = '1girl\nsolo\nhands up\nwaving';
const _spaceAndCarriageReturnedLineBreakExample = '1girl\r\nsolo\r\nhands up\r\nwaving';
const _spaceAndCommaExample = '1girl, solo, hands up, waving';
const _underscoreAndLineBreakExample = '1girl\nsolo\nhands_up\nwaving';
const _underscoreAndCarriageReturnedLineBreakExample = '1girl\r\nsolo\r\nhands_up\r\nwaving';
const _underscoreAndCommaExample = '1girl, solo, hands_up, waving';

void main() {
  group('parseTags', () {
    test('detects spaces and line breaks correctly', () {
      // Hydrus Style

      final tagFile = tutils.parseTags('', _spaceAndLineBreakExample);

      expect(tagFile.path, equals(''));
      expect(tagFile.separator, equals(TagSeparator.lineBreak));
      expect(tagFile.spaceCharacter, equals(TagSpaceCharacter.space));
      expect(tagFile.tags, equals(['1girl', 'solo', 'hands up', 'waving']));
    });

    test('detects spaces and carriage returned line breaks correctly', () {
      // Hydrus Style

      final tagFile = tutils.parseTags('', _spaceAndCarriageReturnedLineBreakExample);

      expect(tagFile.path, equals(''));
      expect(tagFile.separator, equals(TagSeparator.lineBreak));
      expect(tagFile.spaceCharacter, equals(TagSpaceCharacter.space));
      expect(tagFile.tags, equals(['1girl', 'solo', 'hands up', 'waving']));
    });

    test('detects spaces and commas correctly', () {
      // Stable Diffusion style

      final tagFile = tutils.parseTags('', _spaceAndCommaExample);

      expect(tagFile.path, equals(''));
      expect(tagFile.separator, equals(TagSeparator.comma));
      expect(tagFile.spaceCharacter, equals(TagSpaceCharacter.space));
      expect(tagFile.tags, equals(['1girl', 'solo', 'hands up', 'waving']));
    });

    test('detects underscore and line breaks correctly', () {
      // Unknown Style

      final tagFile = tutils.parseTags('', _underscoreAndLineBreakExample);

      expect(tagFile.path, equals(''));
      expect(tagFile.separator, equals(TagSeparator.lineBreak));
      expect(tagFile.spaceCharacter, equals(TagSpaceCharacter.underscore));
      expect(tagFile.tags, equals(['1girl', 'solo', 'hands_up', 'waving']));
    });

    test('detects underscore and carriage returned line breaks correctly', () {
      // Unknown Style

      final tagFile = tutils.parseTags('', _underscoreAndCarriageReturnedLineBreakExample);

      expect(tagFile.path, equals(''));
      expect(tagFile.separator, equals(TagSeparator.lineBreak));
      expect(tagFile.spaceCharacter, equals(TagSpaceCharacter.underscore));
      expect(tagFile.tags, equals(['1girl', 'solo', 'hands_up', 'waving']));
    });

    test('detects underscore and commas correctly', () {
      // Unknown Style, Danbooru?

      final tagFile = tutils.parseTags('', _underscoreAndCommaExample);

      expect(tagFile.path, equals(''));
      expect(tagFile.separator, equals(TagSeparator.comma));
      expect(tagFile.spaceCharacter, equals(TagSpaceCharacter.underscore));
      expect(tagFile.tags, equals(['1girl', 'solo', 'hands_up', 'waving']));
    });
  });
}