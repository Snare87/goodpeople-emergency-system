// src/components/ProtectedRoute.jsx
import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

// 보호된 라우트 컴포넌트 - 알림 없이 리디렉션만 처리
const ProtectedRoute = ({ children, requiredPermission = 'web' }) => {
  const { isLoggedIn, hasPermission } = useAuth();
  const location = useLocation();
  
  // 로그인 체크
  if (!isLoggedIn) {
    return <Navigate to="/" state={{ from: location }} replace />;
  }
  
  // 권한 체크 - 알림 없이 리디렉션 (메시지 포함)
  if (requiredPermission && !hasPermission(requiredPermission)) {
    // 오류 메시지와 함께 리디렉션
    return (
      <Navigate 
        to="/" 
        replace 
        state={{ 
          authError: '웹 대시보드 접근 권한이 없습니다. 관리자에게 문의하세요.' 
        }} 
      />
    );
  }
  
  // 모든 조건 통과
  return children;
};

export default ProtectedRoute;