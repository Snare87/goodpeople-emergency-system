// src/__tests__/utils/formatters.test.ts
import { formatTimestamp, formatDistance, formatDuration } from '../../utils/formatters';

describe('Formatters', () => {
  describe('formatTimestamp', () => {
    it('숫자 타임스탬프를 올바르게 포맷해야 함', () => {
      const timestamp = new Date('2025-05-28 14:30:00').getTime();
      const result = formatTimestamp(timestamp);
      expect(result).toMatch(/14:30/);
    });

    it('문자열 타임스탬프를 올바르게 처리해야 함', () => {
      const timestamp = '2025-05-28T14:30:00';
      const result = formatTimestamp(timestamp);
      expect(result).toMatch(/14:30/);
    });

    it('잘못된 타임스탬프는 빈 문자열을 반환해야 함', () => {
      expect(formatTimestamp(null)).toBe('');
      expect(formatTimestamp(undefined)).toBe('');
    });
  });

  describe('formatDistance', () => {
    it('1km 미만 거리는 미터로 표시해야 함', () => {
      expect(formatDistance(500)).toBe('500m');
      expect(formatDistance(999)).toBe('999m');
    });

    it('1km 이상 거리는 킬로미터로 표시해야 함', () => {
      expect(formatDistance(1000)).toBe('1.0km');
      expect(formatDistance(2500)).toBe('2.5km');
      expect(formatDistance(10000)).toBe('10.0km');
    });

    it('undefined는 빈 문자열을 반환해야 함', () => {
      expect(formatDistance(undefined)).toBe('');
    });
  });

  describe('formatDuration', () => {
    it('60초 미만은 초 단위로 표시해야 함', () => {
      expect(formatDuration(30)).toBe('30초');
      expect(formatDuration(59)).toBe('59초');
    });

    it('60초 이상은 분과 초로 표시해야 함', () => {
      expect(formatDuration(60)).toBe('1분');
      expect(formatDuration(90)).toBe('1분 30초');
      expect(formatDuration(125)).toBe('2분 5초');
    });

    it('3600초 이상은 시간, 분, 초로 표시해야 함', () => {
      expect(formatDuration(3600)).toBe('1시간');
      expect(formatDuration(3660)).toBe('1시간 1분');
      expect(formatDuration(7325)).toBe('2시간 2분 5초');
    });
  });
});