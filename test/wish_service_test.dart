import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:cosmic_wish/models/wish_category.dart';
import 'package:cosmic_wish/services/wish_service.dart';

void main() {
  group('WishService', () {
    group('proxy contract', () {
      test('first turn exposes a reflection question', () async {
        final mock = MockClient(
          (req) async => http.Response.bytes(
            utf8.encode('{"type":"question","text":"Ngươi đang sợ điều gì?"}'),
            200,
          ),
        );
        final result = await WishService(client: mock).beginWish(
          category: WishCategory.other,
          transcript: 'Tôi muốn thay đổi',
        );

        expect(result.needsReflection, isTrue);
        expect(result.question, 'Ngươi đang sợ điều gì?');
        expect(result.prophecy, isNull);
      });

      test('second turn sends question and reflection', () async {
        late Map<String, dynamic> requestBody;
        final mock = MockClient((req) async {
          requestBody = jsonDecode(utf8.decode(req.bodyBytes));
          return http.Response.bytes(
            utf8.encode('{"type":"prophecy","text":"Cánh cửa đã mở."}'),
            200,
          );
        });
        final result = await WishService(client: mock).generateProphecy(
          category: WishCategory.career,
          transcript: 'Tôi muốn đổi việc',
          question: 'Ngươi đang rời đi hay đi tới?',
          reflection: 'Tôi muốn đi tới.',
          locale: 'en',
        );

        expect(result.text, 'Cánh cửa đã mở.');
        expect(requestBody['question'], 'Ngươi đang rời đi hay đi tới?');
        expect(requestBody['reflection'], 'Tôi muốn đi tới.');
        expect(requestBody['locale'], 'en');
      });

      test('rejects a question response on the final turn', () async {
        final mock = MockClient(
          (req) async => http.Response.bytes(
            utf8.encode('{"type":"question","text":"Ngươi còn sợ gì?"}'),
            200,
          ),
        );

        expect(
          () => WishService(client: mock).generateProphecy(
            category: WishCategory.other,
            transcript: 'Tôi muốn thay đổi',
            question: 'Điều gì giữ ngươi lại?',
            reflection: 'Nỗi sợ.',
          ),
          throwsA(isA<WishProxyException>()),
        );
      });

      test('legacy first turn can still return a prophecy directly', () async {
        final mock = MockClient(
          (req) async => http.Response.bytes(
            utf8.encode('{"text":"Một lời tiên tri cũ."}'),
            200,
          ),
        );
        final result = await WishService(client: mock).beginWish(
          category: WishCategory.love,
          transcript: 'Tôi muốn được yêu',
        );

        expect(result.needsReflection, isFalse);
        expect(result.prophecy?.text, 'Một lời tiên tri cũ.');
      });

      test('decodes single-round mojibake (UTF-8 → latin-1 → UTF-8)', () async {
        final clean = 'Ngươi muốn tìm người hiểu mình thật lòng';
        final mojibake = mojibakeFromUtf8(clean);
        expect(mojibake, isNot(equals(clean)));

        final mock = MockClient((req) async {
          final body = utf8.encode('{"text": ${jsonEncode(mojibake)}}');
          return http.Response.bytes(
            body,
            200,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          );
        });
        final service = WishService(client: mock);
        final r = await service.generateProphecy(
          category: WishCategory.love,
          transcript: 'em muon tim nguoi hieu minh that long',
        );
        expect(r.text, clean);
      });

      test('passes through already-clean text untouched', () async {
        const clean = 'Ngươi muốn tìm người hiểu mình thật lòng';
        final mock = MockClient((req) async {
          final body = utf8.encode('{"text": ${jsonEncode(clean)}}');
          return http.Response.bytes(
            body,
            200,
            headers: {'Content-Type': 'application/json; charset=utf-8'},
          );
        });
        final service = WishService(client: mock);
        final r = await service.generateProphecy(
          category: WishCategory.love,
          transcript: 'em muon tim nguoi hieu minh that long',
        );
        expect(r.text, clean);
      });

      test(
        'accepts old shape {type, text, source} from prior deployment',
        () async {
          const clean = 'Sợ thất bại là điều dễ hiểu';
          final mock = MockClient((req) async {
            final body = utf8.encode(
              '{"type":"prophecy","text": ${jsonEncode(clean)},"source":"minimax"}',
            );
            return http.Response.bytes(body, 200);
          });
          final service = WishService(client: mock);
          final r = await service.generateProphecy(
            category: WishCategory.career,
            transcript: 'em sap phong van xin viec lo lam',
          );
          expect(r.text, clean);
        },
      );

      test('structured shape from older backend returns empty text', () async {
        // We no longer try to parse the structured envelope — the
        // backend serves plain `{ text: ... }` again. A leftover
        // structured response would just leave us with no text, which
        // the caller treats as a proxy error.
        const body =
            '{"main_message":"Ngươi đang ôm một nỗi sợ cũ.",'
            '"signs":["một cuộc gọi bất ngờ"],'
            '"action":"làm gì đó",'
            '"affirmation":"Ngươi đã đi đủ xa."}';
        final mock = MockClient((req) async {
          return http.Response.bytes(utf8.encode(body), 200);
        });
        final service = WishService(client: mock);
        expect(
          () => service.generateProphecy(
            category: WishCategory.career,
            transcript: 'em sap nghi viec',
          ),
          throwsA(isA<WishProxyException>()),
        );
      });
    });

    group('no offline fallback (user wants only AI)', () {
      test('empty transcript throws WishEmptyException', () async {
        final service = WishService();
        expect(
          () => service.generateProphecy(
            category: WishCategory.love,
            transcript: '',
          ),
          throwsA(isA<WishEmptyException>()),
        );
        // Whitespace-only should also throw.
        expect(
          () => service.generateProphecy(
            category: WishCategory.love,
            transcript: '   \n  ',
          ),
          throwsA(isA<WishEmptyException>()),
        );
      });

      test('network error throws WishProxyException — no local pool', () async {
        // Mock client always errors out. There is no fallback anymore,
        // so the service must surface the error to the caller.
        final failingMock = MockClient((req) async {
          throw Exception('connection refused');
        });
        final service = WishService(client: failingMock);
        expect(
          () => service.generateProphecy(
            category: WishCategory.love,
            transcript: 'em muon gap mot nguoi',
          ),
          throwsA(isA<WishProxyException>()),
        );
      });

      test('500 status throws WishProxyException', () async {
        final mock = MockClient((req) async {
          return http.Response.bytes(utf8.encode('Internal Server Error'), 500);
        });
        final service = WishService(client: mock);
        expect(
          () => service.generateProphecy(
            category: WishCategory.love,
            transcript: 'em muon gap mot nguoi',
          ),
          throwsA(isA<WishProxyException>()),
        );
      });

      test('200 with empty text throws WishProxyException', () async {
        final mock = MockClient((req) async {
          return http.Response.bytes(utf8.encode('{"text": ""}'), 200);
        });
        final service = WishService(client: mock);
        expect(
          () => service.generateProphecy(
            category: WishCategory.love,
            transcript: 'em muon gap mot nguoi',
          ),
          throwsA(isA<WishProxyException>()),
        );
      });

      test('200 with junk-looking text throws WishProxyException', () async {
        final mock = MockClient((req) async {
          return http.Response.bytes(
            utf8.encode('{"text": "Error: model down"}'),
            200,
          );
        });
        final service = WishService(client: mock);
        expect(
          () => service.generateProphecy(
            category: WishCategory.love,
            transcript: 'em muon gap mot nguoi',
          ),
          throwsA(isA<WishProxyException>()),
        );
      });
    });
  });
}

String mojibakeFromUtf8(String clean) {
  final utf8Bytes = utf8.encode(clean);
  final asLatin1 = latin1.decode(utf8Bytes);
  final reencoded = utf8.encode(asLatin1);
  return utf8.decode(reencoded);
}
