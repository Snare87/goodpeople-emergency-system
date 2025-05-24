// src/App.js - 권한 기반 라우팅 적용

import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UserManagementPage from './pages/UserManagementPage';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';

// 최상위 App 컴포넌트
function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* 로그인 페이지 - 공개 접근 */}
          <Route path="/" element={<LoginPage />} />
          
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
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;