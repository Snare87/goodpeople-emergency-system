// src/__tests__/components/Badge.test.tsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import Badge from '../../components/common/Badge';

describe('Badge Component', () => {
  it('텍스트를 올바르게 렌더링해야 함', () => {
    render(<Badge variant="default">테스트 배지</Badge>);
    expect(screen.getByText('테스트 배지')).toBeInTheDocument();
  });

  it('다양한 variant에 따라 올바른 스타일이 적용되어야 함', () => {
    const { rerender } = render(<Badge variant="success">성공</Badge>);
    let badge = screen.getByText('성공');
    expect(badge.className).toContain('bg-green');

    rerender(<Badge variant="warning">경고</Badge>);
    badge = screen.getByText('경고');
    expect(badge.className).toContain('bg-yellow');

    rerender(<Badge variant="error">오류</Badge>);
    badge = screen.getByText('오류');
    expect(badge.className).toContain('bg-red');
  });

  it('className prop이 추가되어야 함', () => {
    render(
      <Badge variant="default" className="custom-class">
        커스텀 클래스
      </Badge>
    );
    const badge = screen.getByText('커스텀 클래스');
    expect(badge.className).toContain('custom-class');
  });

  it('children이 없을 때도 렌더링되어야 함', () => {
    const { container } = render(<Badge variant="default" />);
    expect(container.firstChild).toBeInTheDocument();
  });
});