// src/components/users/UserFilters.tsx
import React from 'react';
import TabNav from '../common/TabNav';

interface User {
  status: string;
  permissions?: {
    app?: boolean;
    web?: boolean;
  };
}

type FilterType = 'all' | 'pending' | 'approved' | 'rejected' | 'web_users' | 'app_users';

interface UserFiltersProps {
  filter: FilterType;
  onFilterChange: (filter: FilterType) => void;
  users: User[];
}

const UserFilters: React.FC<UserFiltersProps> = ({ filter, onFilterChange, users }) => {
  const tabs = [
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

  return <TabNav tabs={tabs} activeTab={filter} onChange={onFilterChange as (key: string) => void} />;
};

export default UserFilters;