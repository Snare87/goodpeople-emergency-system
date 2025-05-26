// src/App.js - 권한 기반 라우팅 개선

import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UserManagementPage from './pages/UserManagementPage';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';

// 로그인 상태에서 로그인 페이지 접근 방지
function LoginRoute() {
  const { isLoggedIn, hasPermission } = useAuth();
  
  // 로그인되어 있고 웹 권한이 있으면 대시보드로 리디렉션
  if (isLoggedIn && hasPermission('web')) {
    return <Navigate to="/dashboard" replace />;
  }
  
  // 그 외의 경우 로그인 페이지 표시
  return <LoginPage />;
}

// 앱 라우터 컴포넌트
function AppRouter() {
  return (
    <Routes>
      {/* 로그인 페이지 - 개선된 로직 */}
      <Route path="/" element={<LoginRoute />} />
      
      {/* 대시보드 - 웹 권한 필요 */}
      <Route 
        path="/dashboard" 
        element={
          <ProtectedRoute requiredPermission="web">
            <DashboardPage />
          </ProtectedRoute>
        } 
      />
      
      {/* 사용자 관리 - 웹 권한 + 관리자 권한 필요 */}
      <Route 
        path="/users" 
        element={
          <ProtectedRoute requiredPermission="admin">
            <UserManagementPage />
          </ProtectedRoute>
        } 
      />
      
      {/* 알 수 없는 경로 - 로그인 페이지로 리디렉션 */}
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}

// 최상위 App 컴포넌트
function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRouter />
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;