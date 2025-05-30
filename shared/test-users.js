// 테스트 유저 정보
export const TEST_USERS = [
  { email: 'test001@korea.kr', password: 'test1234', name: '박민수', uid: 'TestUser001' },
  { email: 'test002@korea.kr', password: 'test1234', name: '이정훈', uid: 'TestUser002' },
  { email: 'test003@korea.kr', password: 'test1234', name: '김서연', uid: 'TestUser003' },
  { email: 'test004@korea.kr', password: 'test1234', name: '최강호', uid: 'TestUser004' },
  { email: 'test005@korea.kr', password: 'test1234', name: '윤재영', uid: 'TestUser005' },
  { email: 'test006@korea.kr', password: 'test1234', name: '송민지', uid: 'TestUser006' },
  { email: 'test007@korea.kr', password: 'test1234', name: '장현우', uid: 'TestUser007' },
  { email: 'test008@korea.kr', password: 'test1234', name: '한도현', uid: 'TestUser008' },
  { email: 'test009@korea.kr', password: 'test1234', name: '정유진', uid: 'TestUser009' },
  { email: 'test010@korea.kr', password: 'test1234', name: '오성민', uid: 'TestUser010' }
];

// 빠른 로그인 함수 (테스트용)
export const quickTestLogin = async (userIndex: number, auth: any) => {
  if (userIndex < 1 || userIndex > 10) {
    throw new Error('유저 인덱스는 1부터 10까지입니다.');
  }
  
  const user = TEST_USERS[userIndex - 1];
  return await auth.signInWithEmailAndPassword(user.email, user.password);
};
