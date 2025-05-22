// 2. 인증 상태 관리를 위한 Context 생성
// src/contexts/AuthContext.js 파일 생성

import React, { createContext, useContext, useState, useEffect } from 'react';
import { 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged 
} from 'firebase/auth';
import { auth } from '../firebase';

// 인증 컨텍스트 생성
const AuthContext = createContext();

// 인증 상태 및 기능을 제공하는 Provider 컴포넌트
export function AuthProvider({ children }) {
  const [currentUser, setCurrentUser] = useState(null);
  const [loading, setLoading] = useState(true);

  // 로그인 함수
  function login(email, password) {
    return signInWithEmailAndPassword(auth, email, password);
  }

  // 로그아웃 함수
  function logout() {
    return signOut(auth);
  }

  // 인증 상태 변경 감지
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setCurrentUser(user);
      setLoading(false);
    });

    return unsubscribe;
  }, []);

  // 제공할 값들
  const value = {
    currentUser,
    login,
    logout,
    isLoggedIn: !!currentUser
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