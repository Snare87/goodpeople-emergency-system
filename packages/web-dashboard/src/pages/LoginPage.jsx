// src/pages/LoginPage.jsx
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Button from '../components/Button';
import Header from '../components/Header';
import { useAuth } from '../contexts/AuthContext';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const navigate = useNavigate();
  const { login, logout, isLoggedIn, userProfile, hasPermission } = useAuth();
  
  // 로그인 상태에 따른 처리
  useEffect(() => {
    if (isLoggedIn && userProfile) {
      // 웹 권한이 있으면 대시보드로
      if (hasPermission('web')) {
        navigate('/dashboard');
      }
      // 웹 권한이 없으면 여기 남아있되, 메시지 표시
    }
  }, [isLoggedIn, userProfile, hasPermission, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    
    if (!username || !password) {
      return setError('아이디와 비밀번호를 모두 입력해주세요.');
    }
    
    try {
      setLoading(true);
      await login(username, password);
      // 로그인 성공 후 처리는 useEffect에서 자동으로 됨
    } catch (err) {
      console.error('로그인 오류:', err);
      
      let errorMessage;
      if (err.code) {
        switch (err.code) {
          case 'auth/user-not-found':
            errorMessage = '등록되지 않은 이메일입니다.';
            break;
          case 'auth/wrong-password':
            errorMessage = '비밀번호가 일치하지 않습니다.';
            break;
          case 'auth/invalid-email':
            errorMessage = '유효하지 않은 이메일 형식입니다.';
            break;
          case 'auth/network-request-failed':
            errorMessage = '네트워크 연결을 확인해주세요.';
            break;
          default:
            errorMessage = '로그인에 실패했습니다.';
        }
      } else if (err.message) {
        errorMessage = err.message;
      } else {
        errorMessage = '로그인 중 오류가 발생했습니다.';
      }
      
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleLogout = async () => {
    try {
      await logout();
      setUsername('');
      setPassword('');
      setError('');
    } catch (err) {
      console.error('로그아웃 오류:', err);
      setError('로그아웃 중 오류가 발생했습니다.');
    }
  };

  return (
    <>
      <Header title="전라북도형 복지사각지대 해소 프로젝트" />
      <div className="flex items-center justify-center min-h-screen bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-lg w-full max-w-sm">
          {/* 로그인 상태에 따른 UI 분기 */}
          {isLoggedIn ? (
            // 로그인된 상태
            <div className="text-center">
              <h2 className="text-2xl font-bold mb-6">로그인 상태</h2>
              
              {/* 사용자 정보 표시 */}
              <div className="mb-6 p-4 bg-gray-50 rounded-lg">
                <p className="text-sm text-gray-600 mb-2">현재 로그인된 계정</p>
                <p className="font-semibold">{userProfile?.email}</p>
                <p className="text-sm text-gray-600 mt-2">{userProfile?.name}</p>
              </div>

              {/* 권한에 따른 메시지 */}
              {hasPermission('web') ? (
                <div className="mb-6">
                  <p className="text-green-600 mb-4">✅ 웹 대시보드 접근 권한이 있습니다.</p>
                  <Button 
                    onClick={() => navigate('/dashboard')}
                    className="w-full mb-3"
                  >
                    대시보드로 이동
                  </Button>
                </div>
              ) : (
                <div className="mb-6">
                  <div className="p-4 bg-red-50 text-red-800 rounded-lg mb-4">
                    <p className="font-semibold mb-2">⚠️ 웹 대시보드 접근 권한이 없습니다</p>
                    <p className="text-sm">관리자에게 웹 접근 권한을 요청하세요.</p>
                  </div>
                </div>
              )}

              {/* 관리자 권한이 있으면 사용자 관리 버튼 추가 */}
              {hasPermission('admin') && (
                <Button 
                  onClick={() => navigate('/users')}
                  variant="secondary"
                  className="w-full mb-3"
                >
                  사용자 관리
                </Button>
              )}

              {/* 로그아웃 버튼 */}
              <Button 
                onClick={handleLogout}
                variant="secondary"
                className="w-full"
              >
                로그아웃
              </Button>
            </div>
          ) : (
            // 로그인 전 상태
            <>
              <h2 className="text-2xl font-bold mb-6 text-center">로그인</h2>
              
              {error && (
                <div className="mb-4 p-3 bg-red-100 text-red-800 rounded border border-red-200 flex items-center">
                  <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5 mr-2 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                  </svg>
                  <span>{error}</span>
                </div>
              )}
              
              <form onSubmit={handleSubmit} className="space-y-4">
                <input
                  type="email" 
                  placeholder="이메일"
                  value={username}
                  onChange={e => setUsername(e.target.value)}
                  className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-primary"
                  disabled={loading}
                />
                <input
                  type="password"
                  placeholder="비밀번호"
                  value={password}
                  onChange={e => setPassword(e.target.value)}
                  className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-primary"
                  disabled={loading}
                />
                <Button 
                  type="submit" 
                  className="w-full"
                  disabled={loading}
                >
                  {loading ? '로그인 중...' : '로그인'}
                </Button>
              </form>
            </>
          )}
        </div>
      </div>
    </>
  );
}