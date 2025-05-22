import React from 'react';

export default function Button({
  children,
  variant = 'primary',
  onClick,
  ...props
}) {
  const baseStyles = 'px-4 py-2 font-semibold rounded-lg shadow';
  const variants = {
    primary: 'bg-primary text-white hover:bg-blue-600',
    secondary: 'bg-secondary text-white hover:bg-orange-600',
  };
  
  return (
    <button
      className={`${baseStyles} ${variants[variant]}`}
      onClick={onClick}
      {...props}
    >
      {children}
    </button>
  );
}
