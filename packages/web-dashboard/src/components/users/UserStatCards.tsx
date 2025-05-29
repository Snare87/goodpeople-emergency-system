// src/components/users/UserStatCards.tsx
import React from 'react';

interface User {
  status: string;
  permissions?: {
    app?: boolean;
    web?: boolean;
  };
  certifications?: string[];
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

  // 자격증 통계 - 1급/2급 구분
  const certStats = [
    {
      key: 'cert_all',
      label: '전체 자격증',
      count: users.filter(u => u.certifications && u.certifications.length > 0).length,
      description: '자격증 보유자',
      color: 'text-indigo-600'
    },
    {
      key: 'cert_emergency_1',
      label: '응급구조사 1급',
      count: users.filter(u => u.certifications?.includes('응급구조사 1급')).length,
      description: '전문 응급구조',
      color: 'text-red-600'
    },
    {
      key: 'cert_emergency_2',
      label: '응급구조사 2급',
      count: users.filter(u => u.certifications?.includes('응급구조사 2급')).length,
      description: '기본 응급구조',
      color: 'text-red-500'
    },
    {
      key: 'cert_nurse',
      label: '간호사',
      count: users.filter(u => u.certifications?.includes('간호사')).length,
      description: '의료 자격증',
      color: 'text-pink-600'
    },
    {
      key: 'cert_rescue_1',
      label: '인명구조사 1급',
      count: users.filter(u => u.certifications?.includes('인명구조사 1급')).length,
      description: '전문 인명구조',
      color: 'text-orange-600'
    },
    {
      key: 'cert_rescue_2',
      label: '인명구조사 2급',
      count: users.filter(u => u.certifications?.includes('인명구조사 2급')).length,
      description: '기본 인명구조',
      color: 'text-orange-500'
    },
    {
      key: 'cert_fire_1',
      label: '화재대응능력 1급',
      count: users.filter(u => u.certifications?.includes('화재대응능력 1급')).length,
      description: '전문 화재진압',
      color: 'text-amber-600'
    },
    {
      key: 'cert_fire_2',
      label: '화재대응능력 2급',
      count: users.filter(u => u.certifications?.includes('화재대응능력 2급')).length,
      description: '기본 화재진압',
      color: 'text-amber-500'
    }
  ];

  return (
    <div className="space-y-4">
      {/* 기본 통계 */}
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
      
      {/* 자격증 통계 - 1급/2급 구분하여 표시 */}
      <div>
        <h3 className="text-sm font-medium text-gray-700 mb-2">자격증 보유 현황</h3>
        <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-8 gap-3">
          {certStats.map((stat, index) => (
            <div 
              key={stat.key}
              className="bg-white p-3 rounded-lg shadow cursor-pointer hover:bg-gray-50 transition-colors"
              onClick={() => onCardClick(stat.key)}
            >
              <div className={`text-lg font-bold ${stat.color}`}>
                {stat.count}
              </div>
              <div className="text-xs text-gray-500">
                {stat.label.includes('1급') && <span className="font-bold text-yellow-600">★ </span>}
                {stat.label.includes('2급') && <span className="font-bold text-gray-400">☆ </span>}
                {stat.label}
              </div>
              <div className="text-xs text-gray-400 mt-0.5">{stat.description}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default UserStatCards;