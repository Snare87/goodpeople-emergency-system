import React, { ButtonHTMLAttributes } from 'react';

type ButtonVariant = 'primary' | 'secondary';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  variant?: ButtonVariant;
}

export default function Button({
  children,
  variant = 'primary',
  onClick,
  ...props
}: ButtonProps) {
  const baseStyles = 'px-4 py-2 font-semibold rounded-lg shadow';
  const variants: Record<ButtonVariant, string> = {
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