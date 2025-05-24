// src/contexts/AuthContext.js
import React, { createContext, useContext, useState, useEffect } from 'react';
import { 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged 
} from 'firebase/auth';
import { ref, get } from 'firebase/database';
import { auth, db } from '../firebase';

// 인증 컨텍스트 생성
const AuthContext = createContext();

// 인증 상태 및 기능을 제공하는 Provider 컴포넌트
export function AuthProvider({ children }) {
  const [currentUser, setCurrentUser] = useState(null);
  const [userProfile, setUserProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState(null);

  // 로그인 함수 - 알림 표시 없음
  async function login(email, password) {
    try {
      const credential = await signInWithEmailAndPassword(auth, email, password);
      
      // 웹 접근 권한 확인
      const userRef = ref(db, `users/${credential.user.uid}`);
      const snapshot = await get(userRef);
      
      if (snapshot.exists()) {
        const userData = snapshot.val();
        
        // 상태가 approved가 아니면 로그아웃 처리
        if (userData.status !== 'approved') {
          await signOut(auth);
          throw new Error('승인되지 않은 계정입니다. 관리자에게 문의하세요.');
        }
        
        // 웹 권한이 없으면 권한 오류 발생
        if (!userData.permissions?.web) {
          await signOut(auth);
          throw new Error('웹 대시보드 접근 권한이 없습니다.');
        }
      } else {
        // 사용자 정보가 없는 경우
        await signOut(auth);
        throw new Error('사용자 정보를 찾을 수 없습니다.');
      }
      
      return credential;
    } catch (error) {
      console.error('로그인 실패:', error);
      throw error;
    }
  }

  // 로그아웃 함수
  function logout() {
    setUserProfile(null);
    return signOut(auth);
  }

  // 사용자 권한 확인 함수
  function hasPermission(permission) {
    if (!userProfile) return false;
    
    // 권한 확인 로직
    if (permission === 'web') {
      return userProfile.permissions?.web === true;
    } else if (permission === 'app') {
      return userProfile.permissions?.app === true;
    } else if (permission === 'admin') {
      return userProfile.roles?.includes('admin') === true;
    } else if (permission === 'dispatcher') {
      return userProfile.roles?.includes('dispatcher') === true;
    }
    
    return false;
  }

  // 사용자 정보 로드 함수
  async function loadUserProfile(uid) {
    try {
      const userRef = ref(db, `users/${uid}`);
      const snapshot = await get(userRef);
      
      if (snapshot.exists()) {
        const userData = snapshot.val();
        setUserProfile({ ...userData, id: uid });
        return userData;
      }
      return null;
    } catch (error) {
      console.error('사용자 정보 로드 실패:', error);
      return null;
    }
  }

  // 인증 상태 변경 감지
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      setCurrentUser(user);
      
      if (user) {
        // 사용자 정보 로드
        await loadUserProfile(user.uid);
      } else {
        setUserProfile(null);
      }
      
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  // 제공할 값들
  const value = {
    currentUser,
    userProfile,
    login,
    logout,
    hasPermission,
    isLoggedIn: !!currentUser,
    isAdmin: userProfile?.roles?.includes('admin') === true,
    isDispatcher: userProfile?.roles?.includes('dispatcher') === true,
    loadUserProfile,
    authError,
    setAuthError
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
}

// 인증 컨텍스트 사용을 위한 커스텀 훅
export function useAuth() {
  return useContext(AuthContext);
}