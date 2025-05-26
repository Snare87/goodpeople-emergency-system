// src/utils/logger.js

/**
 * 구조화된 로깅 유틸리티
 * Firebase Functions 로그에서 쉽게 필터링하고 추적할 수 있도록 도움
 */
const logger = {
  /**
   * 정보성 로그
   * @param {string} message - 로그 메시지
   * @param {Object} data - 추가 데이터
   */
  info: (message, data = {}) => {
    console.log(JSON.stringify({
      level: 'INFO',
      message,
      data,
      timestamp: new Date().toISOString()
    }));
  },

  /**
   * 에러 로그
   * @param {string} message - 에러 메시지
   * @param {Error|Object} error - 에러 객체
   */
  error: (message, error = {}) => {
    console.error(JSON.stringify({
      level: 'ERROR',
      message,
      error: {
        message: error.message || error,
        code: error.code,
        stack: error.stack
      },
      timestamp: new Date().toISOString()
    }));
  },

  /**
   * 경고 로그
   * @param {string} message - 경고 메시지
   * @param {Object} data - 추가 데이터
   */
  warning: (message, data = {}) => {
    console.log(JSON.stringify({
      level: 'WARNING',
      message,
      data,
      timestamp: new Date().toISOString()
    }));
  },

  /**
   * 디버그 로그 (개발 환경에서만)
   * @param {string} message - 디버그 메시지
   * @param {Object} data - 추가 데이터
   */
  debug: (message, data = {}) => {
    if (process.env.NODE_ENV !== 'production') {
      console.log(JSON.stringify({
        level: 'DEBUG',
        message,
        data,
        timestamp: new Date().toISOString()
      }));
    }
  }
};

module.exports = logger;
