// src/hooks/useUserManagement.ts
import { useState, useEffect, useMemo } from 'react';
import { ref, onValue, update, get } from 'firebase/database';
import { db } from '../firebase';
import { UserStatus } from '../constants';

interface User {
  id: string;
  email: string;
  name?: string;
  status: UserStatus;
  permissions: {
    app: boolean;
    web: boolean;
  };
  roles: string[];
  position?: string;
  rank?: string;
  createdAt?: string;
  updatedAt?: string;
}

type FilterType = 'all' | 'web_users' | 'app_users' | 'pending' | 'approved' | 'rejected';

interface UpdateResult {
  success: boolean;
  error?: unknown;
}

interface UseUserManagementReturn {
  users: User[];
  filteredUsers: User[];
  loading: boolean;
  filter: FilterType;
  setFilter: (filter: FilterType) => void;
  updateUserStatus: (userId: string, newStatus: UserStatus) => Promise<UpdateResult>;
}

export const useUserManagement = (): UseUserManagementReturn => {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [filter, setFilter] = useState<FilterType>('all');

  // Firebase 리스너
  useEffect(() => {
    const usersRef = ref(db, 'users');
    const unsubscribe = onValue(usersRef, (snapshot) => {
      const data = snapshot.val() || {};
      const usersList = Object.entries(data).map(([id, user]: [string, any]) => ({
        id,
        ...user,
        permissions: user.permissions || { app: true, web: false },
        roles: user.roles || []
      }));
      setUsers(usersList);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // 필터링된 사용자 목록
  const filteredUsers = useMemo(() => {
    return users.filter(user => {
      if (filter === 'all') return true;
      if (filter === 'web_users') return user.permissions?.web === true;
      if (filter === 'app_users') return user.permissions?.app === true;
      return user.status === filter;
    });
  }, [users, filter]);

  // 사용자 상태 업데이트
  const updateUserStatus = async (userId: string, newStatus: UserStatus): Promise<UpdateResult> => {
    try {
      await update(ref(db, `users/${userId}`), {
        status: newStatus,
        updatedAt: new Date().toISOString(),
      });
      
      // 승인 시 자동으로 앱 권한 부여
      if (newStatus === 'approved') {
        const userRef = ref(db, `users/${userId}`);
        const snapshot = await get(userRef);
        
        if (snapshot.exists()) {
          const userData = snapshot.val();
          const currentPermissions = userData.permissions || {};
          
          if (currentPermissions.app !== true) {
            await update(ref(db, `users/${userId}`), {
              permissions: {
                ...currentPermissions,
                app: true
              }
            });
          }
        }
      }
      
      return { success: true };
    } catch (error) {
      console.error('상태 업데이트 실패:', error);
      return { success: false, error };
    }
  };

  return {
    users,
    filteredUsers,
    loading,
    filter,
    setFilter,
    updateUserStatus
  };
};