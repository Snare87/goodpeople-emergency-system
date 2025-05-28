// src/components/common/TabNav.jsx
import React from 'react';

const TabNav = ({ tabs, activeTab, onChange, className = '' }) => {
  return (
    <div className={`border-b ${className}`}>
      <nav className="flex space-x-4 overflow-x-auto px-4">
        {tabs.map(tab => (
          <button
            key={tab.key}
            onClick={() => onChange(tab.key)}
            className={`py-3 px-1 border-b-2 font-medium text-sm whitespace-nowrap transition-colors ${
              activeTab === tab.key
                ? 'border-primary text-primary'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            {tab.label}
            {tab.count !== undefined && (
              <span className="ml-2 px-2 py-1 bg-gray-100 text-gray-600 rounded-full text-xs">
                {tab.count}
              </span>
            )}
          </button>
        ))}
      </nav>
    </div>
  );
};

export default TabNav;