// src/hooks/useUserManagement.js
import { useState, useEffect, useMemo } from 'react';
import { ref, onValue, update, get } from 'firebase/database';
import { db } from '../firebase';

export const useUserManagement = () => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  // Firebase 리스너
  useEffect(() => {
    const usersRef = ref(db, 'users');
    const unsubscribe = onValue(usersRef, (snapshot) => {
      const data = snapshot.val() || {};
      const usersList = Object.entries(data).map(([id, user]) => ({
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
  const updateUserStatus = async (userId, newStatus) => {
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