// src/App.js - 구조 개선

import React from 'react';
import { BrowserRouter, Routes, Route, Navigate, useLocation } from 'react-router-dom';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import { AuthProvider, useAuth } from './contexts/AuthContext';

// 보호된 라우트 컴포넌트 - 별도 파일로 분리해도 좋습니다
const ProtectedRoute = ({ children }) => {
  const { isLoggedIn } = useAuth();
  const location = useLocation();
  
  if (!isLoggedIn) {
    // 현재 위치 정보를 state로 전달하여 로그인 후 원래 페이지로 리디렉션 가능
    return <Navigate to="/" state={{ from: location }} replace />;
  }
  
  return children;
};

// 브라우저 라우터를 포함한 전체 앱 컴포넌트
const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/" element={<LoginPage />} />
      <Route 
        path="/dashboard" 
        element={
          <ProtectedRoute>
            <DashboardPage />
          </ProtectedRoute>
        } 
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
};

// 최상위 App 컴포넌트
function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;