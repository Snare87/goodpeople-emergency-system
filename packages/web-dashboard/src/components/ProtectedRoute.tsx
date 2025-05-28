// src/components/ProtectedRoute.tsx
import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

interface ProtectedRouteProps {
  children: React.ReactNode;
  requiredPermission?: string;
}

// 보호된 라우트 컴포넌트
const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children, requiredPermission = 'web' }) => {
  const { isLoggedIn, hasPermission } = useAuth();
  const location = useLocation();
  
  // 로그인 체크
  if (!isLoggedIn) {
    return <Navigate to="/" state={{ from: location }} replace />;
  }
  
  // 권한 체크 - 에러 메시지 없이 리디렉션만
  if (requiredPermission && !hasPermission(requiredPermission)) {
    return <Navigate to="/" replace />;
  }
  
  // 모든 조건 통과
  return <>{children}</>;
};

export default ProtectedRoute;