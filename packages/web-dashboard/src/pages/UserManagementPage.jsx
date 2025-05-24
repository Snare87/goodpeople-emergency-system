// src/pages/UserManagementPage.jsx
import React, { useState, useEffect } from 'react';
import { ref, onValue, update, get } from 'firebase/database';
import { db } from '../firebase';
import Header from '../components/Header';
import PermissionsManager from '../components/PermissionsManager';
import { useAuth } from '../contexts/AuthContext';

export default function UserManagementPage() {
  const [users, setUsers] = useState([]);
  const [selectedUser, setSelectedUser] = useState(null);
  const [filter, setFilter] = useState('all'); // all, pending, approved, rejected
  const [loading, setLoading] = useState(true);
  const [showPermissionsModal, setShowPermissionsModal] = useState(false);
  
  const { hasPermission } = useAuth();
  const isAdmin = hasPermission('admin');

  useEffect(() => {
    const usersRef = ref(db, 'users');
    const unsubscribe = onValue(usersRef, (snapshot) => {
      const data = snapshot.val() || {};
      const usersList = Object.entries(data).map(([id, user]) => ({
        id,
        ...user,
        permissions: user.permissions || { app: true, web: false },
        roles: user.roles || []
      }));
      setUsers(usersList);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const filteredUsers = users.filter(user => {
    if (filter === 'all') return true;
    if (filter === 'web_users') return user.permissions?.web === true;
    if (filter === 'app_users') return user.permissions?.app === true;
    return user.status === filter;
  });

  const updateUserStatus = async (userId, newStatus) => {
    try {
      await update(ref(db, `users/${userId}`), {
        status: newStatus,
        updatedAt: new Date().toISOString(),
      });
      
      // 자동으로 앱 접근 권한 부여 (새로 승인된 사용자인 경우)
      if (newStatus === 'approved') {
        const userRef = ref(db, `users/${userId}`);
        const snapshot = await get(userRef);
        
        if (snapshot.exists()) {
          const userData = snapshot.val();
          const currentPermissions = userData.permissions || {};
          
          if (currentPermissions.app !== true) {
            await update(ref(db, `users/${userId}`), {
              permissions: {
                ...currentPermissions,
                app: true
              }
            });
          }
        }
      }
      
      alert(`사용자 상태가 ${newStatus === 'approved' ? '승인' : '거부'}되었습니다.`);
    } catch (error) {
      alert('상태 업데이트에 실패했습니다.');
      console.error(error);
    }
  };

  const handlePermissionsUpdate = (userId) => {
    const user = users.find(u => u.id === userId);
    if (user) {
      setSelectedUser(user);
      setShowPermissionsModal(true);
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

  const getPermissionsBadges = (permissions = {}) => {
    return (
      <div className="flex gap-1">
        {permissions.app && (
          <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded-md text-xs">모바일</span>
        )}
        {permissions.web && (
          <span className="px-2 py-1 bg-purple-100 text-purple-800 rounded-md text-xs">웹</span>
        )}
      </div>
    );
  };

  const getRolesBadges = (roles = []) => {
    const roleLabels = {
      'admin': '관리자',
      'dispatcher': '상황실',
      'supervisor': '감독관',
      'reporter': '보고자'
    };
    
    return (
      <div className="flex flex-wrap gap-1 mt-1">
        {roles.map(role => (
          <span 
            key={role} 
            className="px-2 py-0.5 bg-gray-100 text-gray-800 rounded-md text-xs"
          >
            {roleLabels[role] || role}
          </span>
        ))}
      </div>
    );
  };

  // 통계 카드 클릭 이벤트 핸들러
  const handleStatCardClick = (status) => {
    setFilter(status);
    // 맨 위로 스크롤
    window.scrollTo(0, 0);
  };

  // 권한 설정 모달
  const PermissionsModal = () => {
    if (!selectedUser) return null;
    
    return (
      <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center z-50">
        <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl mx-4">
          <div className="flex justify-between items-center p-4 border-b">
            <h2 className="text-lg font-semibold">접근 권한 관리: {selectedUser.name}</h2>
            <button 
              onClick={() => setShowPermissionsModal(false)}
              className="text-gray-400 hover:text-gray-600"
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          
          <div className="p-4">
            <div className="mb-4 flex items-center gap-2">
              <div className="font-medium">{selectedUser.name}</div>
              <div className="text-sm text-gray-500">({selectedUser.email})</div>
              {getStatusBadge(selectedUser.status)}
            </div>
            
            <PermissionsManager 
              userId={selectedUser.id}
              permissions={selectedUser.permissions}
              roles={selectedUser.roles}
              onUpdate={(updatedData) => {
                // 로컬 상태 업데이트
                setUsers(prev => prev.map(user => 
                  user.id === selectedUser.id 
                    ? {...user, ...updatedData} 
                    : user
                ));
                setSelectedUser(null);
                setShowPermissionsModal(false);
              }}
            />
          </div>
          
          <div className="p-4 border-t flex justify-end">
            <button
              onClick={() => setShowPermissionsModal(false)}
              className="px-4 py-2 text-gray-600 hover:bg-gray-100 rounded"
            >
              닫기
            </button>
          </div>
        </div>
      </div>
    );
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
            <nav className="flex space-x-4 overflow-x-auto">
              {[
                { key: 'all', label: '전체', count: users.length },
                { key: 'pending', label: '승인대기', count: users.filter(u => u.status === 'pending').length },
                { key: 'approved', label: '승인완료', count: users.filter(u => u.status === 'approved').length },
                { key: 'rejected', label: '거부됨', count: users.filter(u => u.status === 'rejected').length },
                { key: 'web_users', label: '웹 사용자', count: users.filter(u => u.permissions?.web === true).length },
                { key: 'app_users', label: '앱 사용자', count: users.filter(u => u.permissions?.app === true).length },
              ].map(tab => (
                <button
                  key={tab.key}
                  onClick={() => setFilter(tab.key)}
                  className={`py-3 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
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
                        접근 권한
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
                          <div>
                            {getPermissionsBadges(user.permissions)}
                            {getRolesBadges(user.roles)}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          {new Date(user.createdAt).toLocaleDateString('ko-KR')}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          {getStatusBadge(user.status)}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          <div className="flex flex-col gap-2">
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
                            
                            {/* 권한 관리 버튼 - 관리자만 접근 가능 */}
                            {isAdmin && (
                              <button
                                onClick={() => handlePermissionsUpdate(user.id)}
                                className="px-3 py-1 bg-purple-500 text-white rounded hover:bg-purple-600 mt-1"
                              >
                                권한 관리
                              </button>
                            )}
                          </div>
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
        <div className="mt-6 grid grid-cols-1 md:grid-cols-6 gap-4">
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
          <div 
            className="bg-white p-6 rounded-lg shadow cursor-pointer hover:bg-gray-50"
            onClick={() => handleStatCardClick('web_users')}
          >
            <div className="text-2xl font-bold text-purple-600">
              {users.filter(u => u.permissions?.web === true).length}
            </div>
            <div className="text-sm text-gray-500">웹 사용자</div>
            <div className="text-xs text-gray-400 mt-1">상황실 담당자</div>
          </div>
          <div 
            className="bg-white p-6 rounded-lg shadow cursor-pointer hover:bg-gray-50"
            onClick={() => handleStatCardClick('app_users')}
          >
            <div className="text-2xl font-bold text-blue-600">
              {users.filter(u => u.permissions?.app === true).length}
            </div>
            <div className="text-sm text-gray-500">앱 사용자</div>
            <div className="text-xs text-gray-400 mt-1">현장 대응 대원</div>
          </div>
        </div>
      </main>
      
      {/* 권한 관리 모달 */}
      {showPermissionsModal && <PermissionsModal />}
    </div>
  );
}