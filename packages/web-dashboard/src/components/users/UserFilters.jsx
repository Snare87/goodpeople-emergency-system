// src/components/users/UserFilters.jsx
import React from 'react';
import TabNav from '../common/TabNav';

const UserFilters = ({ filter, onFilterChange, users }) => {
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

  return <TabNav tabs={tabs} activeTab={filter} onChange={onFilterChange} />;
};

export default UserFilters;