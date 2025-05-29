// src/__tests__/hooks/useUserManagement.test.ts
import { renderHook, act } from '@testing-library/react';
import { useUserManagement } from '../../hooks/useUserManagement';
import { ref, onValue } from 'firebase/database';

// Firebase 모킹
jest.mock('firebase/database', () => ({
  ref: jest.fn(),
  onValue: jest.fn(),
  update: jest.fn(),
  get: jest.fn()
}));

describe('useUserManagement - 자격증 필터링', () => {
  const mockUsers = [
    {
      id: '1',
      email: 'user1@test.com',
      name: '김철수',
      status: 'approved',
      permissions: { app: true, web: false },
      roles: [],
      certifications: ['응급구조사 1급', '간호사']
    },
    {
      id: '2',
      email: 'user2@test.com',
      name: '이영희',
      status: 'approved',
      permissions: { app: true, web: false },
      roles: [],
      certifications: ['인명구조사 2급']
    },
    {
      id: '3',
      email: 'user3@test.com',
      name: '박민수',
      status: 'approved',
      permissions: { app: true, web: false },
      roles: [],
      certifications: ['화재대응능력 1급', '응급구조사 2급']
    },
    {
      id: '4',
      email: 'user4@test.com',
      name: '정지은',
      status: 'approved',
      permissions: { app: true, web: false },
      roles: [],
      certifications: []
    }
  ];

  beforeEach(() => {
    jest.clearAllMocks();
    
    // Firebase onValue 모킹
    (onValue as jest.Mock).mockImplementation((ref, callback) => {
      const data = mockUsers.reduce((acc, user) => {
        const { id, ...userData } = user;
        acc[id] = userData;
        return acc;
      }, {} as any);
      
      callback({ val: () => data });
      return jest.fn(); // unsubscribe function
    });
  });

  it('응급구조사 1급 필터가 올바르게 작동해야 함', () => {
    const { result } = renderHook(() => useUserManagement());

    act(() => {
      result.current.setFilter('cert_emergency_1');
    });

    expect(result.current.filteredUsers).toHaveLength(1);
    expect(result.current.filteredUsers[0].name).toBe('김철수');
  });

  it('응급구조사 2급 필터가 올바르게 작동해야 함', () => {
    const { result } = renderHook(() => useUserManagement());

    act(() => {
      result.current.setFilter('cert_emergency_2');
    });

    expect(result.current.filteredUsers).toHaveLength(1);
    expect(result.current.filteredUsers[0].name).toBe('박민수');
  });

  it('간호사 자격증 필터가 올바르게 작동해야 함', () => {
    const { result } = renderHook(() => useUserManagement());

    act(() => {
      result.current.setFilter('cert_nurse');
    });

    expect(result.current.filteredUsers).toHaveLength(1);
    expect(result.current.filteredUsers[0].name).toBe('김철수');
  });

  it('인명구조사 2급 필터가 올바르게 작동해야 함', () => {
    const { result } = renderHook(() => useUserManagement());

    act(() => {
      result.current.setFilter('cert_rescue_2');
    });

    expect(result.current.filteredUsers).toHaveLength(1);
    expect(result.current.filteredUsers[0].name).toBe('이영희');
  });

  it('화재대응능력 1급 필터가 올바르게 작동해야 함', () => {
    const { result } = renderHook(() => useUserManagement());

    act(() => {
      result.current.setFilter('cert_fire_1');
    });

    expect(result.current.filteredUsers).toHaveLength(1);
    expect(result.current.filteredUsers[0].name).toBe('박민수');
  });

  it('자격증이 없는 사용자는 자격증 필터에서 제외되어야 함', () => {
    const { result } = renderHook(() => useUserManagement());

    // 모든 자격증 필터 테스트
    ['cert_emergency_1', 'cert_emergency_2', 'cert_nurse', 'cert_rescue_1', 'cert_rescue_2', 'cert_fire_1', 'cert_fire_2'].forEach(filter => {
      act(() => {
        result.current.setFilter(filter as any);
      });
      
      const hasEmptyCertUser = result.current.filteredUsers.some(u => u.name === '정지은');
      expect(hasEmptyCertUser).toBe(false);
    });
  });

  it('전체 필터로 돌아가면 모든 사용자가 표시되어야 함', () => {
    const { result } = renderHook(() => useUserManagement());

    // 먼저 자격증 필터 적용
    act(() => {
      result.current.setFilter('cert_emergency_1');
    });
    expect(result.current.filteredUsers).toHaveLength(1);

    // 전체 필터로 변경
    act(() => {
      result.current.setFilter('all');
    });
    expect(result.current.filteredUsers).toHaveLength(4);
  });
});