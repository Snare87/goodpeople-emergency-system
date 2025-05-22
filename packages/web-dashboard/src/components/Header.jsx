// src/components/Header.jsx - 메인 페이지에서는 로그인 버튼 숨기기

import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import Button from './Button';
import { useAuth } from '../contexts/AuthContext';

export default function Header({ title = 'GoodPeople' }) {
  const navigate = useNavigate();
  const location = useLocation(); // 현재 경로 확인
  const { isLoggedIn, logout } = useAuth();
  
  const isLoginPage = location.pathname === '/'; // 현재 페이지가 로그인 페이지인지 확인
  
  const handleAuth = async () => {
    if (isLoggedIn) {
      try {
        await logout();
        navigate('/');
      } catch (error) {
        console.error('로그아웃 오류:', error);
      }
    } else {
      navigate('/');
    }
  };

  return (
    <header className="flex items-center justify-between bg-white shadow px-6 py-4">
      <h1 className="text-xl font-bold">{title}</h1>
      
      {/* 로그인 페이지가 아니거나 이미 로그인된 경우에만 버튼 표시 */}
      {(!isLoginPage || isLoggedIn) && (
        <Button variant="secondary" onClick={handleAuth}>
          {isLoggedIn ? '로그아웃' : '로그인'}
        </Button>
      )}
    </header>
  );
}