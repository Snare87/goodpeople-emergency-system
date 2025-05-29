// src/components/users/UserFilters.tsx
import React from 'react';
import TabNav from '../common/TabNav';

interface User {
  status: string;
  permissions?: {
    app?: boolean;
    web?: boolean;
  };
  certifications?: string[];
}

type FilterType = 'all' | 'pending' | 'approved' | 'rejected' | 'web_users' | 'app_users' | 
  'cert_all' | 'cert_emergency_1' | 'cert_emergency_2' | 'cert_nurse' | 
  'cert_rescue_1' | 'cert_rescue_2' | 'cert_fire_1' | 'cert_fire_2';

interface UserFiltersProps {
  filter: FilterType;
  onFilterChange: (filter: FilterType) => void;
  users: User[];
}

const UserFilters: React.FC<UserFiltersProps> = ({ filter, onFilterChange, users }) => {
  // 기본 탭
  const basicTabs = [
    { 
      key: 'all', 
      label: '전체', 
      count: users.length 
    },
    { 
      key: 'pending', 
      label: '승인대기', 
      count: users.filter(u => u.status === 'pending').length 
    },
    { 
      key: 'approved', 
      label: '승인완료', 
      count: users.filter(u => u.status === 'approved').length 
    },
    { 
      key: 'rejected', 
      label: '거부됨', 
      count: users.filter(u => u.status === 'rejected').length 
    },
    { 
      key: 'web_users', 
      label: '웹 사용자', 
      count: users.filter(u => u.permissions?.web === true).length 
    },
    { 
      key: 'app_users', 
      label: '앱 사용자', 
      count: users.filter(u => u.permissions?.app === true).length 
    },
  ];
  
  // 자격증 탭 (필터가 자격증 관련일 때만 표시) - 1급/2급 구분
  const certTabs = [
    {
      key: 'cert_all',
      label: '자격증 보유자 전체',
      count: users.filter(u => u.certifications && u.certifications.length > 0).length
    },
    {
      key: 'cert_emergency_1',
      label: '응급구조사 1급',
      count: users.filter(u => u.certifications?.includes('응급구조사 1급')).length
    },
    {
      key: 'cert_emergency_2',
      label: '응급구조사 2급',
      count: users.filter(u => u.certifications?.includes('응급구조사 2급')).length
    },
    {
      key: 'cert_nurse',
      label: '간호사',
      count: users.filter(u => u.certifications?.includes('간호사')).length
    },
    {
      key: 'cert_rescue_1',
      label: '인명구조사 1급',
      count: users.filter(u => u.certifications?.includes('인명구조사 1급')).length
    },
    {
      key: 'cert_rescue_2',
      label: '인명구조사 2급',
      count: users.filter(u => u.certifications?.includes('인명구조사 2급')).length
    },
    {
      key: 'cert_fire_1',
      label: '화재대응능력 1급',
      count: users.filter(u => u.certifications?.includes('화재대응능력 1급')).length
    },
    {
      key: 'cert_fire_2',
      label: '화재대응능력 2급',
      count: users.filter(u => u.certifications?.includes('화재대응능력 2급')).length
    }
  ];
  
  // 현재 필터가 자격증 관련인지 확인
  const isCertFilter = filter.startsWith('cert_');
  const tabs = isCertFilter ? certTabs : basicTabs;

  return (
    <div>
      {isCertFilter && (
        <button
          onClick={() => onFilterChange('all')}
          className="mb-4 flex items-center text-sm text-gray-600 hover:text-gray-900"
        >
          <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          전체 필터로 돌아가기
        </button>
      )}
      <TabNav tabs={tabs} activeTab={filter} onChange={onFilterChange as (key: string) => void} />
    </div>
  );
};

export default UserFilters;