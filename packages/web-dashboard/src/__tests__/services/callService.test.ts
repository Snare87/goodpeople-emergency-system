// src/__tests__/services/callService.test.ts
import { acceptCall, cancelCall, dispatchCall, completeCall } from '../../services/callService';
import { ref, set, get, runTransaction } from 'firebase/database';
import { auth } from '../../firebase';

// Firebase 모듈 모킹
jest.mock('firebase/database', () => ({
  ref: jest.fn(),
  set: jest.fn(),
  get: jest.fn(),
  update: jest.fn(),
  runTransaction: jest.fn(),
  onValue: jest.fn(),
  off: jest.fn()
}));

jest.mock('../../firebase', () => ({
  db: {},
  auth: {
    currentUser: { uid: 'test-user-123' }
  }
}));

describe('CallService - 재난 수락 기능', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('acceptCall', () => {
    it('정상적으로 재난을 수락할 수 있어야 함', async () => {
      const mockUserData = {
        name: '김철수',
        position: '구조대원',
        rank: '소방사'
      };

      const mockCallData = {
        status: 'dispatched',
        eventType: '화재',
        address: '서울시 강남구'
      };

      // 사용자 데이터 모킹
      (get as jest.Mock).mockImplementation((ref) => {
        if (ref.toString().includes('users')) {
          return Promise.resolve({
            exists: () => true,
            val: () => mockUserData
          });
        }
        return Promise.resolve({ exists: () => false });
      });

      // Transaction 성공 모킹
      (runTransaction as jest.Mock).mockResolvedValue({
        committed: true,
        snapshot: { val: () => ({ ...mockCallData, status: 'accepted' }) }
      });

      // 실행
      await acceptCall('test-call-1', 'resp1', '김철수');

      // 검증
      expect(runTransaction).toHaveBeenCalled();
      const transactionCallback = (runTransaction as jest.Mock).mock.calls[0][1];
      
      // Transaction 콜백 테스트
      const result = transactionCallback(mockCallData);
      expect(result.status).toBe('accepted');
      expect(result.responder).toBeDefined();
      expect(result.responder.name).toBe('김철수');
    });

    it('dispatched 상태가 아닌 재난은 수락할 수 없어야 함', async () => {
      const mockCallData = {
        status: 'idle', // dispatched가 아님
        eventType: '화재'
      };

      (get as jest.Mock).mockResolvedValue({
        exists: () => true,
        val: () => ({ name: '김철수', position: '구조대원', rank: '소방사' })
      });

      (runTransaction as jest.Mock).mockImplementation(async (ref, updateFunction) => {
        const result = updateFunction(mockCallData);
        return {
          committed: result !== undefined,
          snapshot: { val: () => result }
        };
      });

      // Transaction이 중단되어야 함
      await acceptCall('test-call-1');
      
      const transactionCallback = (runTransaction as jest.Mock).mock.calls[0][1];
      const result = transactionCallback(mockCallData);
      expect(result).toBeUndefined(); // Transaction abort
    });

    it('이미 다른 대원이 수락한 재난은 수락할 수 없어야 함', async () => {
      const mockCallData = {
        status: 'dispatched',
        responder: { // 이미 다른 대원이 수락
          id: 'resp_other_123',
          name: '이영희'
        }
      };

      (get as jest.Mock).mockResolvedValue({
        exists: () => true,
        val: () => ({ name: '김철수', position: '구조대원', rank: '소방사' })
      });

      (runTransaction as jest.Mock).mockImplementation(async (ref, updateFunction) => {
        const result = updateFunction(mockCallData);
        return {
          committed: false,
          snapshot: { val: () => mockCallData }
        };
      });

      // 에러가 발생해야 함
      await expect(acceptCall('test-call-1')).rejects.toThrow();
    });

    it('동시에 여러 명이 수락 시도시 한 명만 성공해야 함', async () => {
      let acceptCount = 0;
      const mockCallData = {
        status: 'dispatched',
        eventType: '구조'
      };

      (get as jest.Mock).mockResolvedValue({
        exists: () => true,
        val: () => ({ name: '대원', position: '구조대원', rank: '소방사' })
      });

      // 첫 번째 호출만 성공하도록 모킹
      (runTransaction as jest.Mock).mockImplementation(async () => {
        acceptCount++;
        return {
          committed: acceptCount === 1,
          snapshot: { val: () => ({ ...mockCallData, status: 'accepted' }) }
        };
      });

      // 동시에 3명이 수락 시도
      const results = await Promise.allSettled([
        acceptCall('test-call-1', 'user1', '김철수'),
        acceptCall('test-call-1', 'user2', '이영희'),
        acceptCall('test-call-1', 'user3', '박민수')
      ]);

      // 1명만 성공해야 함
      const successCount = results.filter(r => r.status === 'fulfilled').length;
      const failureCount = results.filter(r => r.status === 'rejected').length;
      
      expect(successCount).toBe(1);
      expect(failureCount).toBe(2);
    });
  });

  describe('cancelCall', () => {
    it('dispatched 상태이고 responder가 없을 때만 취소 가능해야 함', async () => {
      const mockCallData = {
        status: 'dispatched',
        responder: null
      };

      (runTransaction as jest.Mock).mockImplementation(async (ref, updateFunction) => {
        const result = updateFunction(mockCallData);
        return {
          committed: result !== undefined,
          snapshot: { val: () => result }
        };
      });

      await cancelCall('test-call-1');

      const transactionCallback = (runTransaction as jest.Mock).mock.calls[0][1];
      const result = transactionCallback(mockCallData);
      
      expect(result.status).toBe('idle');
      expect(result.cancelledAt).toBeDefined();
    });

    it('이미 수락된 재난은 취소할 수 없어야 함', async () => {
      const mockCallData = {
        status: 'accepted',
        responder: { id: 'resp_123', name: '김철수' }
      };

      (runTransaction as jest.Mock).mockImplementation(async (ref, updateFunction) => {
        const result = updateFunction(mockCallData);
        return {
          committed: false,
          snapshot: { val: () => mockCallData }
        };
      });

      await expect(cancelCall('test-call-1')).rejects.toThrow('취소할 수 없는 상태입니다');
    });
  });
});

describe('CallService - 전체 시나리오 테스트', () => {
  it('재난 발생부터 완료까지 전체 프로세스가 정상 동작해야 함', async () => {
    // 1. 상황실에서 호출 (dispatched)
    (ref as jest.Mock).mockReturnValue({ id: 'test-call-1' });
    await dispatchCall('test-call-1');

    // 2. 대원이 수락
    const mockUserData = { name: '김철수', position: '구조대원', rank: '소방사' };
    (get as jest.Mock).mockResolvedValue({
      exists: () => true,
      val: () => mockUserData
    });
    
    (runTransaction as jest.Mock).mockResolvedValue({
      committed: true,
      snapshot: { val: () => ({ status: 'accepted' }) }
    });
    
    await acceptCall('test-call-1');

    // 3. 임무 완료
    await completeCall('test-call-1');

    // 각 단계가 호출되었는지 확인
    expect(runTransaction).toHaveBeenCalled(); // acceptCall에서 사용
  });
});