// src/components/users/UserTable.jsx
import React from 'react';
import Badge from '../common/Badge';
import { USER_STATUS_LABELS, STATUS_BADGE_VARIANTS, POSITION_BADGE_VARIANTS, RANK_COLORS } from '../../constants';
import UserActions from './UserActions';

const UserTable = ({ users, onStatusUpdate, onPermissionsUpdate, isAdmin }) => {
  if (users.length === 0) {
    return (
      <div className="text-center py-12 text-gray-500">
        대원이 없습니다.
      </div>
    );
  }

  const getRankBadge = (rank) => {
    const colorClass = RANK_COLORS[rank] || 'bg-gray-100 text-gray-800';
    return <span className={`px-2 py-1 ${colorClass} rounded-md text-sm font-medium`}>{rank}</span>;
  };

  const getPermissionsBadges = (permissions = {}) => {
    return (
      <div className="flex gap-1">
        {permissions.app && (
          <Badge variant="info" size="sm">모바일</Badge>
        )}
        {permissions.web && (
          <Badge variant="purple" size="sm">웹</Badge>
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
          <Badge key={role} variant="default" size="sm">
            {roleLabels[role] || role}
          </Badge>
        ))}
      </div>
    );
  };

  return (
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
          {users.map((user) => (
            <tr key={user.id} className="hover:bg-gray-50">
              <td className="px-6 py-4 whitespace-nowrap">
                <div>
                  <div className="text-sm font-medium text-gray-900">{user.name}</div>
                  <div className="text-sm text-gray-500">{user.email}</div>
                  <div className="text-xs text-gray-400">
                    식별번호: {user.officialId || user.employeeId}
                  </div>
                </div>
              </td>
              <td className="px-6 py-4 whitespace-nowrap">
                <div>
                  <div className="text-sm text-gray-900">{user.department}</div>
                  <div className="mt-1 flex gap-2">
                    {getRankBadge(user.rank || '소방사')}
                    <Badge variant={POSITION_BADGE_VARIANTS[user.position] || 'default'}>
                      {user.position}
                    </Badge>
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
                <Badge variant={STATUS_BADGE_VARIANTS[user.status]}>
                  {USER_STATUS_LABELS[user.status]}
                </Badge>
              </td>
              <td className="px-6 py-4 whitespace-nowrap text-sm">
                <UserActions
                  user={user}
                  onStatusUpdate={onStatusUpdate}
                  onPermissionsUpdate={onPermissionsUpdate}
                  isAdmin={isAdmin}
                />
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

export default UserTable;