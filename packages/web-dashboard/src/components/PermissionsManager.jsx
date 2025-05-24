// src/components/PermissionsManager.jsx
import React, { useState } from 'react';
import { ref, update } from 'firebase/database';
import { db } from '../firebase';

const PermissionsManager = ({ userId, permissions, roles, onUpdate }) => {
  const [isEditing, setIsEditing] = useState(false);
  const [appPermission, setAppPermission] = useState(permissions?.app || false);
  const [webPermission, setWebPermission] = useState(permissions?.web || false);
  const [userRoles, setUserRoles] = useState(roles || []);
  const [isSaving, setIsSaving] = useState(false);

  const availableRoles = [
    { id: 'admin', label: '관리자', description: '시스템 전체 관리 권한' },
    { id: 'dispatcher', label: '상황실 요원', description: '재난 호출 및 관리 권한' },
    { id: 'supervisor', label: '감독관', description: '대원 감독 및 통계 열람 권한' },
    { id: 'reporter', label: '보고자', description: '보고서 작성 및 열람 권한' }
  ];

  const handleRoleToggle = (roleId) => {
    setUserRoles(prev => {
      if (prev.includes(roleId)) {
        return prev.filter(r => r !== roleId);
      } else {
        return [...prev, roleId];
      }
    });
  };

  const handleCancel = () => {
    // 편집 취소시 원래 값으로 복원
    setAppPermission(permissions?.app || false);
    setWebPermission(permissions?.web || false);
    setUserRoles(roles || []);
    setIsEditing(false);
  };

  const handleSave = async () => {
    try {
      setIsSaving(true);
      
      // Firebase에 권한 업데이트
      await update(ref(db, `users/${userId}`), {
        permissions: {
          app: appPermission,
          web: webPermission
        },
        roles: userRoles
      });
      
      // 부모 컴포넌트에 업데이트 알림
      if (onUpdate) {
        onUpdate({
          permissions: { app: appPermission, web: webPermission },
          roles: userRoles
        });
      }
      
      setIsEditing(false);
    } catch (error) {
      console.error('권한 업데이트 오류:', error);
      alert('권한 업데이트 중 오류가 발생했습니다.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="mt-2 border rounded-lg p-4 bg-gray-50">
      <div className="flex justify-between items-center mb-3">
        <h3 className="font-medium text-gray-700">접근 권한 관리</h3>
        
        {!isEditing ? (
          <button
            onClick={() => setIsEditing(true)}
            className="px-2 py-1 text-sm text-blue-700 hover:bg-blue-50 rounded"
          >
            권한 수정
          </button>
        ) : (
          <div className="flex gap-2">
            <button
              onClick={handleCancel}
              className="px-2 py-1 text-sm text-gray-600 hover:bg-gray-200 rounded"
              disabled={isSaving}
            >
              취소
            </button>
            <button
              onClick={handleSave}
              className="px-2 py-1 text-sm text-white bg-blue-600 hover:bg-blue-700 rounded"
              disabled={isSaving}
            >
              {isSaving ? '저장 중...' : '저장'}
            </button>
          </div>
        )}
      </div>
      
      {/* 앱/웹 접근 권한 */}
      <div className="mb-4">
        <div className="font-medium text-sm text-gray-600 mb-2">플랫폼 접근 권한</div>
        <div className="flex gap-4">
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={appPermission}
              onChange={() => isEditing && setAppPermission(!appPermission)}
              disabled={!isEditing}
              className="mr-2 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className={`${!isEditing && !appPermission ? 'text-gray-400' : 'text-gray-700'}`}>
              모바일 앱 접근
            </span>
          </label>
          
          <label className="flex items-center">
            <input
              type="checkbox"
              checked={webPermission}
              onChange={() => isEditing && setWebPermission(!webPermission)}
              disabled={!isEditing}
              className="mr-2 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
            <span className={`${!isEditing && !webPermission ? 'text-gray-400' : 'text-gray-700'}`}>
              웹 대시보드 접근
            </span>
          </label>
        </div>
      </div>
      
      {/* 역할 설정 */}
      <div>
        <div className="font-medium text-sm text-gray-600 mb-2">사용자 역할</div>
        <div className="grid grid-cols-2 gap-2">
          {availableRoles.map(role => (
            <label key={role.id} className="flex items-center p-2 rounded hover:bg-gray-100">
              <input
                type="checkbox"
                checked={userRoles.includes(role.id)}
                onChange={() => isEditing && handleRoleToggle(role.id)}
                disabled={!isEditing}
                className="mr-2 h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <div>
                <div className={`${!isEditing && !userRoles.includes(role.id) ? 'text-gray-400' : 'text-gray-700'}`}>
                  {role.label}
                </div>
                <div className="text-xs text-gray-500">{role.description}</div>
              </div>
            </label>
          ))}
        </div>
      </div>
      
      {/* 권한 변경 로그 */}
      {!isEditing && (
        <div className="mt-4 text-xs text-gray-500">
          마지막 변경: {new Date().toLocaleDateString('ko-KR')}
        </div>
      )}
    </div>
  );
};

export default PermissionsManager;