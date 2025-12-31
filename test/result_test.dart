import 'package:test/test.dart';
import 'package:ordinals_sdk/ordinals_sdk.dart';

void main() {
  group('Result', () {
    test('success should hold value', () {
      final result = Result.success(42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.value, equals(42));
      expect(result.valueOrNull, equals(42));
      expect(result.errorOrNull, isNull);
    });

    test('failure should hold error', () {
      final result = Result<int>.failure('Something went wrong');
      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, equals('Something went wrong'));
      expect(result.valueOrNull, isNull);
    });

    test('failure with code should hold both', () {
      final result = Result<int>.failure('Not found', code: 'NOT_FOUND');
      expect(result.isFailure, isTrue);
      expect(result.code, equals('NOT_FOUND'));
      expect(result.errorOrNull, equals('Not found'));
    });

    test('map should transform success value', () {
      final result = Result.success(10);
      final mapped = result.map((v) => v * 2);
      expect(mapped.isSuccess, isTrue);
      expect(mapped.value, equals(20));
    });

    test('map should preserve failure', () {
      final result = Result<int>.failure('error');
      final mapped = result.map((v) => v * 2);
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull, equals('error'));
    });

    test('when should call correct branch', () {
      final success = Result.success('hello');
      final failure = Result<String>.failure('error');

      final successResult = success.when(
        success: (v) => 'got: $v',
        failure: (e) => 'fail: $e',
      );
      expect(successResult, equals('got: hello'));

      final failureResult = failure.when(
        success: (v) => 'got: $v',
        failure: (e) => 'fail: $e',
      );
      expect(failureResult, equals('fail: error'));
    });
  });
}
