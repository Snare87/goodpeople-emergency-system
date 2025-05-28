// src/components/common/Modal.tsx
import React from 'react';

type ModalSize = 'sm' | 'md' | 'lg' | 'xl';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  size?: ModalSize;
  footer?: React.ReactNode;
  className?: string;
}

const Modal: React.FC<ModalProps> = ({ 
  isOpen, 
  onClose, 
  title, 
  children, 
  size = 'md',
  footer,
  className = '' 
}) => {
  if (!isOpen) return null;

  const sizes: Record<ModalSize, string> = {
    sm: 'max-w-md',
    md: 'max-w-2xl',
    lg: 'max-w-4xl',
    xl: 'max-w-6xl',
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-center justify-center min-h-screen px-4">
        {/* 배경 오버레이 */}
        <div 
          className="fixed inset-0 bg-gray-600 bg-opacity-50 transition-opacity"
          onClick={onClose}
        />
        
        {/* 모달 콘텐츠 */}
        <div className={`relative bg-white rounded-lg shadow-xl ${sizes[size]} w-full ${className}`}>
          {/* 헤더 */}
          {title && (
            <div className="flex items-center justify-between p-4 border-b">
              <h3 className="text-lg font-semibold">{title}</h3>
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          )}
          
          {/* 바디 */}
          <div className="p-4">
            {children}
          </div>
          
          {/* 푸터 */}
          {footer && (
            <div className="p-4 border-t">
              {footer}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Modal;