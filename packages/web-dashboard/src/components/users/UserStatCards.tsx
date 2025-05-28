// src/components/users/UserStatCards.tsx
import React from 'react';

interface User {
  status: string;
  permissions?: {
    app?: boolean;
    web?: boolean;
  };
}

interface UserStatCardsProps {
  users: User[];
  onCardClick: (key: string) => void;
}

interface StatCard {
  key: string;
  label: string;
  count: number;
  description: string;
  color: string;
}

const UserStatCards: React.FC<UserStatCardsProps> = ({ users, onCardClick }) => {
  const stats: StatCard[] = [
    {
      key: 'all',
      label: '전체 가입자',
      count: users.length,
      description: '승인 + 대기 + 차단',
      color: 'text-gray-900'
    },
    {
      key: 'approved',
      label: '활동 가능 대원',
      count: users.filter(u => u.status === 'approved').length,
      description: '승인 완료',
      color: 'text-green-600'
    },
    {
      key: 'pending',
      label: '승인 대기',
      count: users.filter(u => u.status === 'pending').length,
      description: '검토 필요',
      color: 'text-yellow-600'
    },
    {
      key: 'rejected',
      label: '활동 불가',
      count: users.filter(u => u.status === 'rejected').length,
      description: '거부/차단',
      color: 'text-red-600'
    },
    {
      key: 'web_users',
      label: '웹 사용자',
      count: users.filter(u => u.permissions?.web === true).length,
      description: '상황실 담당자',
      color: 'text-purple-600'
    },
    {
      key: 'app_users',
      label: '앱 사용자',
      count: users.filter(u => u.permissions?.app === true).length,
      description: '현장 대응 대원',
      color: 'text-blue-600'
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-6 gap-4">
      {stats.map(stat => (
        <div 
          key={stat.key}
          className="bg-white p-6 rounded-lg shadow cursor-pointer hover:bg-gray-50 transition-colors"
          onClick={() => onCardClick(stat.key)}
        >
          <div className={`text-2xl font-bold ${stat.color}`}>
            {stat.count}
          </div>
          <div className="text-sm text-gray-500">{stat.label}</div>
          <div className="text-xs text-gray-400 mt-1">{stat.description}</div>
        </div>
      ))}
    </div>
  );
};

export default UserStatCards;