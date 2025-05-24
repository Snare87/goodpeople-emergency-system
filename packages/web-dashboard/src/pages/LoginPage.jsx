// src/pages/LoginPage.jsx
import React, { useState, useEffect, useRef } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import Button from '../components/Button';
import Header from '../components/Header';
import { useAuth } from '../contexts/AuthContext';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  
  const navigate = useNavigate();
  const location = useLocation();
  const { login, isLoggedIn } = useAuth();
  const errorShownRef = useRef(false);
  
  // 이미 로그인한 경우 대시보드로 리다이렉트
  useEffect(() => {
    if (isLoggedIn) {
      navigate('/dashboard');
    }
  }, [isLoggedIn, navigate]);
  
  // URL 상태에서 오류 메시지 확인 
  useEffect(() => {
    // 권한 오류가 있고 아직 표시하지 않았으면
    if (location.state?.authError && !errorShownRef.current) {
      setError(location.state.authError);
      errorShownRef.current = true;
      
      // 브라우저 히스토리에서 state 제거 (지연 없이)
      navigate(location.pathname, { replace: true });
    }
  }, [location, navigate]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    errorShownRef.current = false;
    
    if (!username || !password) {
      return setError('아이디와 비밀번호를 모두 입력해주세요.');
    }
    
    try {
      setLoading(true);
      await login(username, password);
      navigate('/dashboard');
    } catch (err) {
      console.error('로그인 오류:', err);
      
      // 에러 메시지 설정
      let errorMessage;
      
      // Firebase 인증 오류 처리
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
            errorMessage = '로그인에 실패했습니다. 아이디와 비밀번호를 확인해주세요.';
        }
      } else if (err.message) {
        // 권한 관련 오류 등 커스텀 에러 메시지 사용
        errorMessage = err.message;
      } else {
        errorMessage = '로그인 중 오류가 발생했습니다.';
      }
      
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Header title="전라북도형 복지사각지대 해소 프로젝트" />
      <div className="flex items-center justify-center min-h-screen bg-gray-100">
        <div className="bg-white p-8 rounded-lg shadow-lg w-full max-w-sm">
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
        </div>
      </div>
    </>
  );
}