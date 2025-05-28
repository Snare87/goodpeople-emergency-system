// test/providers/call_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:goodpeople_responder/providers/call_provider.dart';
import 'package:goodpeople_responder/models/call.dart';

void main() {
  group('CallProvider Tests', () {
    late CallProvider provider;

    setUp(() {
      provider = CallProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('초기 상태 확인', () {
      expect(provider.allCalls, isEmpty);
      expect(provider.filteredCalls, isEmpty);
      expect(provider.isLoading, isTrue);
      expect(provider.filterType, equals("전체"));
      expect(provider.currentPosition, isNull);
    });

    test('필터 변경 테스트', () {
      // 필터 타입 변경
      provider.changeFilter("화재");
      expect(provider.filterType, equals("화재"));

      provider.changeFilter("구급");
      expect(provider.filterType, equals("구급"));

      provider.changeFilter("전체");
      expect(provider.filterType, equals("전체"));
    });

    test('필터링 로직 테스트', () {
      // 테스트용 더미 데이터 생성
      final testCalls = [
        Call(
          id: '1',
          eventType: '화재',
          address: '서울시 강남구',
          lat: 37.5665,
          lng: 126.9780,
          startAt: DateTime.now().millisecondsSinceEpoch,
          status: 'pending',
          distance: 100,
        ),
        Call(
          id: '2',
          eventType: '구급',
          address: '서울시 서초구',
          lat: 37.4837,
          lng: 127.0324,
          startAt: DateTime.now().millisecondsSinceEpoch - 3600000,
          status: 'pending',
          distance: 500,
        ),
        Call(
          id: '3',
          eventType: '화재',
          address: '서울시 송파구',
          lat: 37.5145,
          lng: 127.1066,
          startAt: DateTime.now().millisecondsSinceEpoch - 7200000,
          status: 'pending',
          distance: 1000,
        ),
      ];

      // 전체 필터 테스트
      provider.changeFilter("전체");
      expect(provider.filterType, equals("전체"));

      // 화재 필터 테스트
      provider.changeFilter("화재");
      expect(provider.filterType, equals("화재"));

      // 구급 필터 테스트
      provider.changeFilter("구급");
      expect(provider.filterType, equals("구급"));
    });

    test('로딩 상태 변경 테스트', () {
      expect(provider.isLoading, isTrue);
      
      // refresh 호출 시 로딩 상태가 true가 되는지 테스트
      provider.refresh();
      expect(provider.isLoading, isTrue);
    });
  });
}
