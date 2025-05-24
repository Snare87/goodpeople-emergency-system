// src/components/ProtectedRoute.jsx
import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

// 보호된 라우트 컴포넌트 - 권한 기반 접근 제어 추가
const ProtectedRoute = ({ children, requiredPermission = 'web' }) => {
  const { isLoggedIn, hasPermission } = useAuth();
  const location = useLocation();
  
  // 로그인 체크
  if (!isLoggedIn) {
    return <Navigate to="/" state={{ from: location }} replace />;
  }
  
  // 권한 체크
  if (requiredPermission && !hasPermission(requiredPermission)) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="bg-white p-8 rounded-lg shadow-lg max-w-md w-full">
          <div className="text-center">
            <svg 
              xmlns="http://www.w3.org/2000/svg" 
              className="h-16 w-16 text-red-500 mx-auto mb-4" 
              fill="none" 
              viewBox="0 0 24 24" 
              stroke="currentColor"
            >
              <path 
                strokeLinecap="round" 
                strokeLinejoin="round" 
                strokeWidth={2} 
                d="M12 15v2m0 0v2m0-2h2m-2 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z" 
              />
            </svg>
            <h2 className="text-2xl font-bold text-gray-800 mb-2">접근 권한 없음</h2>
            <p className="text-gray-600 mb-6">
              이 페이지에 접근할 권한이 없습니다. 관리자에게 문의하세요.
            </p>
            <button
              onClick={() => window.history.back()}
              className="px-4 py-2 bg-blue-500 text-white rounded-md hover:bg-blue-600 transition-colors"
            >
              뒤로 가기
            </button>
          </div>
        </div>
      </div>
    );
  }
  
  // 모든 조건 통과
  return children;
};

export default ProtectedRoute;