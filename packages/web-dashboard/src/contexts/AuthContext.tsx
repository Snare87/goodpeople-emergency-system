// src/contexts/AuthContext.tsx
import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  User,
  UserCredential
} from 'firebase/auth';
import { ref, get } from 'firebase/database';
import { auth, db } from '../firebase';

// 사용자 프로필 타입 정의
interface UserProfile {
  id: string;
  email: string;
  name?: string;
  status: 'pending' | 'approved' | 'rejected';
  permissions?: {
    web?: boolean;
    app?: boolean;
  };
  roles?: string[];
  position?: string;
  rank?: string;
}

// 인증 컨텍스트 타입 정의
interface AuthContextType {
  currentUser: User | null;
  userProfile: UserProfile | null;
  login: (email: string, password: string) => Promise<UserCredential>;
  logout: () => Promise<void>;
  hasPermission: (permission: string) => boolean;
  isLoggedIn: boolean;
  isAdmin: boolean;
  isDispatcher: boolean;
  loadUserProfile: (uid: string) => Promise<UserProfile | null>;
}

// 인증 컨텍스트 생성
const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

// 인증 상태 및 기능을 제공하는 Provider 컴포넌트
export function AuthProvider({ children }: AuthProviderProps) {
  const [currentUser, setCurrentUser] = useState<User | null>(null);
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState<boolean>(true);

  // 로그인 함수
  async function login(email: string, password: string): Promise<UserCredential> {
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
          // 여기서 alert 띄우기
          alert('웹 대시보드 접근 권한이 없습니다. 관리자에게 문의하세요.');
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
  function logout(): Promise<void> {
    setUserProfile(null);
    return signOut(auth);
  }

  // 사용자 권한 확인 함수
  function hasPermission(permission: string): boolean {
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
  async function loadUserProfile(uid: string): Promise<UserProfile | null> {
    try {
      const userRef = ref(db, `users/${uid}`);
      const snapshot = await get(userRef);
      
      if (snapshot.exists()) {
        const userData = snapshot.val();
        const profile: UserProfile = { ...userData, id: uid };
        setUserProfile(profile);
        return profile;
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
  const value: AuthContextType = {
    currentUser,
    userProfile,
    login,
    logout,
    hasPermission,
    isLoggedIn: !!currentUser,
    isAdmin: userProfile?.roles?.includes('admin') === true,
    isDispatcher: userProfile?.roles?.includes('dispatcher') === true,
    loadUserProfile
  };

  return (
    <AuthContext.Provider value={value}>
      {!loading && children}
    </AuthContext.Provider>
  );
}

// 인증 컨텍스트 사용을 위한 커스텀 훅
export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}