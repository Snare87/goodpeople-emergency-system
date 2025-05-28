// src/components/Header.tsx - 네비게이션 메뉴 추가

import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import Button from './Button';
import { useAuth } from '../contexts/AuthContext';

interface HeaderProps {
  title?: string;
}

interface NavItem {
  path: string;
  label: string;
  icon: string;
}

export default function Header({ title = 'GoodPeople' }: HeaderProps) {
  const navigate = useNavigate();
  const location = useLocation();
  const { isLoggedIn, logout } = useAuth();
  
  const isLoginPage = location.pathname === '/';
  
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

  const navItems: NavItem[] = [
    { path: '/dashboard', label: '대시보드', icon: '📊' },
    { path: '/users', label: '대원 관리', icon: '👥' },
  ];

  return (
    <header className="bg-white shadow">
      <div className="flex items-center justify-between px-6 py-4">
        <div className="flex items-center space-x-8">
          <h1 className="text-xl font-bold">{title}</h1>
          
          {/* 네비게이션 메뉴 - 로그인된 상태에서만 표시 */}
          {isLoggedIn && !isLoginPage && (
            <nav className="flex space-x-4">
              {navItems.map(item => (
                <button
                  key={item.path}
                  onClick={() => navigate(item.path)}
                  className={`flex items-center space-x-1 px-3 py-2 rounded-md text-sm font-medium transition-colors ${
                    location.pathname === item.path
                      ? 'bg-primary text-white'
                      : 'text-gray-700 hover:bg-gray-100'
                  }`}
                >
                  <span>{item.icon}</span>
                  <span>{item.label}</span>
                </button>
              ))}
            </nav>
          )}
        </div>
        
        {/* 로그아웃 버튼 */}
        {(!isLoginPage || isLoggedIn) && (
          <Button variant="secondary" onClick={handleAuth}>
            {isLoggedIn ? '로그아웃' : '로그인'}
          </Button>
        )}
      </div>
    </header>
  );
}