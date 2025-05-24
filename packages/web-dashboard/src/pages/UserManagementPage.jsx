// src/pages/UserManagementPage.jsx
import React, { useState, useEffect } from 'react';
import { ref, onValue, update } from 'firebase/database';
import { db } from '../firebase';
import Header from '../components/Header';

export default function UserManagementPage() {
  const [users, setUsers] = useState([]);
  const [filter, setFilter] = useState('all'); // all, pending, approved, rejected
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const usersRef = ref(db, 'users');
    const unsubscribe = onValue(usersRef, (snapshot) => {
      const data = snapshot.val() || {};
      const usersList = Object.entries(data).map(([id, user]) => ({
        id,
        ...user,
      }));
      setUsers(usersList);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredUsers = users.filter(user => {
    if (filter === 'all') return true;
    return user.status === filter;
  });

  const updateUserStatus = async (userId, newStatus) => {
    try {
      await update(ref(db, `users/${userId}`), {
        status: newStatus,
        updatedAt: new Date().toISOString(),
      });
      alert(`사용자 상태가 ${newStatus === 'approved' ? '승인' : '거부'}되었습니다.`);
    } catch (error) {
      alert('상태 업데이트에 실패했습니다.');
      console.error(error);
    }
  };

  const getStatusBadge = (status) => {
    const badges = {
      pending: <span className="px-2 py-1 bg-yellow-100 text-yellow-800 rounded-md text-sm">승인대기</span>,
      approved: <span className="px-2 py-1 bg-green-100 text-green-800 rounded-md text-sm">승인완료</span>,
      rejected: <span className="px-2 py-1 bg-red-100 text-red-800 rounded-md text-sm">거부됨</span>,
    };
    return badges[status] || badges.pending;
  };

  const getPositionBadge = (position) => {
    // 직책별 색상
    const colors = {
      '화재진압대원': 'bg-red-100 text-red-800',
      '구조대원': 'bg-blue-100 text-blue-800',
      '구급대원': 'bg-emerald-100 text-emerald-800',
    };
    const colorClass = colors[position] || 'bg-gray-100 text-gray-800';
    return <span className={`px-2 py-1 ${colorClass} rounded-md text-sm`}>{position}</span>;
  };

  const getRankBadge = (rank) => {
    // 계급별 스타일 (계급이 높을수록 진한 색)
    const colors = {
      '소방사': 'bg-slate-100 text-slate-700',
      '소방교': 'bg-slate-200 text-slate-800',
      '소방장': 'bg-indigo-100 text-indigo-700',
      '소방위': 'bg-indigo-200 text-indigo-800',
      '소방경': 'bg-purple-100 text-purple-700',
      '소방령': 'bg-purple-200 text-purple-800',
      '소방정': 'bg-purple-300 text-purple-900',
    };
    const colorClass = colors[rank] || 'bg-gray-100 text-gray-800';
    return <span className={`px-2 py-1 ${colorClass} rounded-md text-sm font-medium`}>{rank}</span>;
  };

  // 통계 카드 클릭 이벤트 핸들러
  const handleStatCardClick = (status) => {
    setFilter(status);
    // 맨 위로 스크롤
    window.scrollTo(0, 0);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Header title="대원 관리" />
        <div className="flex items-center justify-center h-64">
          <div className="text-center">
            <div className="text-gray-500">로딩 중...</div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header title="대원 관리" />
      
      <main className="p-6">
        <div className="bg-white rounded-lg shadow">
          {/* 필터 탭 */}
          <div className="border-b px-4">
            <nav className="flex space-x-4">
              {[
                { key: 'all', label: '전체', count: users.length },
                { key: 'pending', label: '승인대기', count: users.filter(u => u.status === 'pending').length },
                { key: 'approved', label: '승인완료', count: users.filter(u => u.status === 'approved').length },
                { key: 'rejected', label: '거부됨', count: users.filter(u => u.status === 'rejected').length },
              ].map(tab => (
                <button
                  key={tab.key}
                  onClick={() => setFilter(tab.key)}
                  className={`py-3 px-1 border-b-2 font-medium text-sm ${
                    filter === tab.key
                      ? 'border-primary text-primary'
                      : 'border-transparent text-gray-500 hover:text-gray-700'
                  }`}
                >
                  {tab.label}
                  <span className="ml-2 px-2 py-1 bg-gray-100 text-gray-600 rounded-full text-xs">
                    {tab.count}
                  </span>
                </button>
              ))}
            </nav>
          </div>

          {/* 사용자 목록 */}
          <div className="p-4">
            {filteredUsers.length === 0 ? (
              <div className="text-center py-12 text-gray-500">
                {filter === 'pending' ? '승인 대기 중인 대원이 없습니다.' : '대원이 없습니다.'}
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                  <thead className="bg-gray-50">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        대원 정보
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        소속/계급/직책
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        자격증
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        가입일
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        상태
                      </th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                        관리
                      </th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {filteredUsers.map((user) => (
                      <tr key={user.id} className="hover:bg-gray-50">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div>
                            <div className="text-sm font-medium text-gray-900">{user.name}</div>
                            <div className="text-sm text-gray-500">{user.email}</div>
                            <div className="text-xs text-gray-400">식별번호: {user.officialId || user.employeeId}</div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div>
                            <div className="text-sm text-gray-900">{user.department}</div>
                            <div className="mt-1 flex gap-2">
                              {getRankBadge(user.rank || '소방사')}
                              {getPositionBadge(user.position)}
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4">
                          <div className="flex flex-wrap gap-1">
                            {user.certifications?.length > 0 ? (
                              user.certifications.map((cert, idx) => (
                                <span
                                  key={idx}
                                  className="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-gray-100 text-gray-800"
                                >
                                  {cert}
                                </span>
                              ))
                            ) : (
                              <span className="text-sm text-gray-400">없음</span>
                            )}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {new Date(user.createdAt).toLocaleDateString('ko-KR')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          {getStatusBadge(user.status)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          {user.status === 'pending' && (
                            <div className="flex gap-2">
                              <button
                                onClick={() => updateUserStatus(user.id, 'approved')}
                                className="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600"
                              >
                                승인
                              </button>
                              <button
                                onClick={() => updateUserStatus(user.id, 'rejected')}
                                className="px-3 py-1 bg-red-500 text-white rounded hover:bg-red-600"
                              >
                                거부
                              </button>
                            </div>
                          )}
                          {user.status === 'approved' && (
                            <button
                              onClick={() => updateUserStatus(user.id, 'rejected')}
                              className="px-3 py-1 bg-gray-500 text-white rounded hover:bg-gray-600"
                            >
                              차단
                            </button>
                          )}
                          {user.status === 'rejected' && (
                            <button
                              onClick={() => updateUserStatus(user.id, 'approved')}
                              className="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
                            >
                              승인
                            </button>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>

        {/* 통계 카드 - 클릭 이벤트 추가 */}
        <div className="mt-6 grid grid-cols-1 md:grid-cols-4 gap-4">
          <div 
            className="bg-white p-6 rounded-lg shadow cursor-pointer hover:bg-gray-50"
            onClick={() => handleStatCardClick('all')}
          >
            <div className="text-2xl font-bold text-gray-900">{users.length}</div>
            <div className="text-sm text-gray-500">전체 가입자</div>
            <div className="text-xs text-gray-400 mt-1">승인 + 대기 + 차단</div>
          </div>
          <div 
            className="bg-white p-6 rounded-lg shadow cursor-pointer hover:bg-gray-50"
            onClick={() => handleStatCardClick('approved')}
          >
            <div className="text-2xl font-bold text-green-600">
              {users.filter(u => u.status === 'approved').length}
            </div>
            <div className="text-sm text-gray-500">활동 가능 대원</div>
            <div className="text-xs text-gray-400 mt-1">승인 완료</div>
          </div>
          <div 
            className="bg-white p-6 rounded-lg shadow cursor-pointer hover:bg-gray-50"
            onClick={() => handleStatCardClick('pending')}
          >
            <div className="text-2xl font-bold text-yellow-600">
              {users.filter(u => u.status === 'pending').length}
            </div>
            <div className="text-sm text-gray-500">승인 대기</div>
            <div className="text-xs text-gray-400 mt-1">검토 필요</div>
          </div>
          <div 
            className="bg-white p-6 rounded-lg shadow cursor-pointer hover:bg-gray-50"
            onClick={() => handleStatCardClick('rejected')}
          >
            <div className="text-2xl font-bold text-red-600">
              {users.filter(u => u.status === 'rejected').length}
            </div>
            <div className="text-sm text-gray-500">활동 불가</div>
            <div className="text-xs text-gray-400 mt-1">거부/차단</div>
          </div>
        </div>
      </main>
    </div>
  );
}