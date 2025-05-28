// src/pages/UserManagementPage.tsx
import React, { useState } from 'react';
import Header from '../components/Header';
import Card from '../components/common/Card';
import LoadingSpinner from '../components/common/LoadingSpinner';
import Modal from '../components/common/Modal';
import UserTable from '../components/users/UserTable';
import UserFilters from '../components/users/UserFilters';
import UserStatCards from '../components/users/UserStatCards';
import PermissionsManager from '../components/PermissionsManager';
import { useUserManagement } from '../hooks/useUserManagement';
import { useModal } from '../hooks/useModal';
import { useAuth } from '../contexts/AuthContext';
import { UserStatus } from '../constants';

interface User {
  id: string;
  email: string;
  name?: string;
  status: UserStatus;
  permissions: {
    app: boolean;
    web: boolean;
  };
  roles: string[];
  position?: string;
  rank?: string;
}

export default function UserManagementPage() {
  const { hasPermission } = useAuth();
  const isAdmin = hasPermission('admin');
  
  const {
    users,
    filteredUsers,
    loading,
    filter,
    setFilter,
    updateUserStatus
  } = useUserManagement();

  const permissionsModal = useModal();
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  const handlePermissionsUpdate = (userId: string) => {
    const user = users.find(u => u.id === userId);
    if (user) {
      setSelectedUser(user);
      permissionsModal.open();
    }
  };

  const handleStatusUpdate = async (userId: string, newStatus: UserStatus) => {
    const result = await updateUserStatus(userId, newStatus);
    if (result.success) {
      alert(`사용자 상태가 ${newStatus === 'approved' ? '승인' : '거부'}되었습니다.`);
    } else {
      alert('상태 업데이트에 실패했습니다.');
    }
  };

  const handleStatCardClick = (status: string) => {
    setFilter(status as any);
    window.scrollTo(0, 0);
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50">
        <Header title="대원 관리" />
        <div className="flex items-center justify-center h-64">
          <LoadingSpinner size="lg" />
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <Header title="대원 관리" />
      
      <main className="p-6 space-y-6">
        {/* 사용자 목록 */}
        <Card>
          <UserFilters 
            filter={filter}
            onFilterChange={setFilter}
            users={users}
          />
          
          <div className="p-4">
            <UserTable
              users={filteredUsers}
              onStatusUpdate={handleStatusUpdate}
              onPermissionsUpdate={handlePermissionsUpdate}
              isAdmin={isAdmin}
            />
          </div>
        </Card>

        {/* 통계 카드 */}
        <UserStatCards 
          users={users}
          onCardClick={handleStatCardClick}
        />
      </main>
      
      {/* 권한 관리 모달 */}
      <Modal
        isOpen={permissionsModal.isOpen}
        onClose={() => {
          permissionsModal.close();
          setSelectedUser(null);
        }}
        title={`접근 권한 관리: ${selectedUser?.name || ''}`}
        size="md"
      >
        {selectedUser && (
          <PermissionsManager 
            userId={selectedUser.id}
            permissions={selectedUser.permissions}
            roles={selectedUser.roles}
            onUpdate={(updatedData) => {
              // 로컬 상태는 Firebase 리스너가 자동으로 업데이트
              setSelectedUser(null);
              permissionsModal.close();
            }}
          />
        )}
      </Modal>
    </div>
  );
}