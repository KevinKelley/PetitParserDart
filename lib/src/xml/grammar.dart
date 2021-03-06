// Copyright (c) 2013, Lukas Renggli <renggli@gmail.com>

part of xml;

/**
 * XML grammar definition.
 */
class XmlGrammar extends CompositeParser {

  static final String NAME_START_CHARS = ':A-Z_a-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF'
      '\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001\uD7FF'
      '\uF900-\uFDCF\uFDF0-\uFFFD';
  static final String NAME_CHARS = '-.0-9\u00B7\u0300-\u036F\u203F-\u2040$NAME_START_CHARS';

  void initialize() {
    def('start', ref('document').end());

    def('attribute', ref('qualified')
      .seq(ref('whitespace').optional())
      .seq(char('='))
      .seq(ref('whitespace').optional())
      .seq(ref('attributeValue'))
      .map((list) => [list[0], list[4]]));
    def('attributeValue', ref('attributeValueDouble')
      .or(ref('attributeValueSingle'))
      .map((list) => list[1]));
    def('attributeValueDouble', char('"')
      .seq(char('"').neg().star().flatten())
      .seq(char('"')));
    def('attributeValueSingle', char("'")
      .seq(char("'").neg().star().flatten())
      .seq(char("'")));
    def('attributes', ref('whitespace')
      .seq(ref('attribute'))
      .map((list) => list[1])
      .star());
    def('comment', string('<!--')
      .seq(string('-->').neg().star().flatten())
      .seq(string('-->'))
      .map((list) => list[1]));
    def('content', ref('characterData')
      .or(ref('element'))
      .or(ref('processing'))
      .or(ref('comment'))
      .star());
    def('doctype', string('<!DOCTYPE')
      .seq(ref('whitespace').optional())
      .seq(char('[').neg().star()
        .seq(char('['))
        .seq(char(']').neg().star())
        .seq(char(']'))
        .flatten())
      .seq(ref('whitespace').optional())
      .seq(char('>'))
      .map((list) => list[2]));
    def('document', ref('processing').optional()
      .seq(ref('misc'))
      .seq(ref('doctype').optional())
      .seq(ref('misc'))
      .seq(ref('element'))
      .seq(ref('misc'))
      .map((list) => [list[0], list[2], list[4]].where((each) => each != null)));
    def('element', char('<')
      .seq(ref('qualified'))
      .seq(ref('attributes'))
      .seq(ref('whitespace').optional())
      .seq(string('/>')
        .or(char('>')
          .seq(ref('content'))
          .seq(string('</'))
          .seq(ref('qualified'))
          .seq(ref('whitespace').optional())
          .seq(char('>'))))
      .map((list) {
        if (list[4] == '/>') {
          return [list[1], list[2], []];
        } else {
          if (list[1] == list[4][3]) {
            return [list[1], list[2], list[4][1]];
          } else {
            throw new ArgumentError('Expected </${list[1]}>');
          }
        }
      }));
    def('processing', string('<?')
      .seq(ref('nameToken'))
      .seq(ref('whitespace')
        .seq(string('?>').neg().star())
        .optional()
        .flatten())
      .seq(string('?>'))
      .map((list) => [list[1], list[2]]));
    def('qualified', ref('nameToken'));

    def('characterData', char('<').neg().plus().flatten());
    def('misc', ref('whitespace')
      .or(ref('comment'))
      .or(ref('processing'))
      .star());
    def('whitespace', whitespace().plus());

    def('nameToken', ref('nameStartChar')
      .seq(ref('nameStartChar').star())
      .flatten());
    def('nameStartChar', pattern(NAME_START_CHARS));
    def('nameChar', pattern(NAME_CHARS));
  }

}
