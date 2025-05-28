// src/components/users/UserActions.tsx
import React from 'react';
import { UserStatus } from '../../constants';

interface User {
  id: string;
  status: UserStatus;
}

interface UserActionsProps {
  user: User;
  onStatusUpdate: (userId: string, newStatus: UserStatus) => Promise<void>;
  onPermissionsUpdate: (userId: string) => void;
  isAdmin: boolean;
}

const UserActions: React.FC<UserActionsProps> = ({ user, onStatusUpdate, onPermissionsUpdate, isAdmin }) => {
  return (
    <div className="flex flex-col gap-2">
      {user.status === 'pending' && (
        <div className="flex gap-2">
          <button
            onClick={() => onStatusUpdate(user.id, 'approved')}
            className="px-3 py-1 bg-green-500 text-white rounded hover:bg-green-600"
          >
            승인
          </button>
          <button
            onClick={() => onStatusUpdate(user.id, 'rejected')}
            className="px-3 py-1 bg-red-500 text-white rounded hover:bg-red-600"
          >
            거부
          </button>
        </div>
      )}
      
      {user.status === 'approved' && (
        <button
          onClick={() => onStatusUpdate(user.id, 'rejected')}
          className="px-3 py-1 bg-gray-500 text-white rounded hover:bg-gray-600"
        >
          차단
        </button>
      )}
      
      {user.status === 'rejected' && (
        <button
          onClick={() => onStatusUpdate(user.id, 'approved')}
          className="px-3 py-1 bg-blue-500 text-white rounded hover:bg-blue-600"
        >
          승인
        </button>
      )}
      
      {isAdmin && (
        <button
          onClick={() => onPermissionsUpdate(user.id)}
          className="px-3 py-1 bg-purple-500 text-white rounded hover:bg-purple-600 mt-1"
        >
          권한 관리
        </button>
      )}
    </div>
  );
};

export default UserActions;