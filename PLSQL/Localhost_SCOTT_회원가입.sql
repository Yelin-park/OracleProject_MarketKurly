
--[회원가입]
--1. ID 중복 체크
--2. 회원가입 성공 시, 회원정보 생성

-- 회원 코드 시퀀스 생성
--DROP SEQUENCE c_code_seq;
--
--CREATE SEQUENCE c_code_seq
--INCREMENT BY 1
--START WITH 6
--NOMAXVALUE
--MINVALUE 1
--NOCYCLE;


-- 회원가입 시, 회원 정보 생성하는 트리거
CREATE OR REPLACE TRIGGER mk_t_signUpDML AFTER
    INSERT ON sign_up
    FOR EACH ROW
BEGIN
    INSERT INTO customer (c_code, c_name, c_id) 
    VALUES (:NEW.c_code, :NEW.c_name, :NEW.c_id);
END;
--
-- 회원가입하는 프로시저 정의
CREATE OR REPLACE PROCEDURE mk_p_sign_up
(
    pC_ID sign_up.c_id%TYPE, 
    pC_PWD sign_up.c_pwd%TYPE, 
    pC_ADDRESS sign_up.c_address%TYPE, 
    pC_EMAIL sign_up.c_email%TYPE, 
    pC_NAME sign_up.c_name%TYPE, 
    pC_BIRTHDAY sign_up.c_birthday%TYPE, 
    pC_GENDER sign_up.c_gender%TYPE, 
    pC_PHONE sign_up.c_phone%TYPE, 
    pC_TOS sign_up.c_tos%TYPE, 
    pC_AGECHECK sign_up.c_agecheck%TYPE, 
    pC_SMSCHECK sign_up.c_smscheck%TYPE, 
    pC_EMAILCHECK sign_up.c_emailcheck%TYPE, 
    pC_PERSONALAGREE sign_up.c_personalagree%TYPE, 
    pC_RECOMMEND sign_up.c_recommend%TYPE, 
    pC_EVENTCHECK sign_up.c_eventcheck%TYPE
)
IS
    e_invalid_sign_up EXCEPTION;
    e_null_sign_up EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_invalid_sign_up, -02290);
    PRAGMA EXCEPTION_INIT (e_null_sign_up, -01400);
BEGIN
    INSERT INTO sign_up (C_CODE, C_ID, C_PWD, C_ADDRESS, C_EMAIL, C_NAME, C_BIRTHDAY, 
        C_GENDER , C_PHONE, C_TOS, C_AGECHECK, C_SMSCHECK, C_EMAILCHECK, C_PERSONALAGREE, 
        C_RECOMMEND, C_EVENTCHECK) 
    VALUES (c_code_seq.nextval, pC_ID, pC_PWD, pC_ADDRESS, pC_EMAIL, pC_NAME, pC_BIRTHDAY, 
        pC_GENDER , pC_PHONE, pC_TOS, pC_AGECHECK, pC_SMSCHECK, pC_EMAILCHECK, pC_PERSONALAGREE, 
        pC_RECOMMEND, pC_EVENTCHECK);
    COMMIT;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, '중복된 ID가 존재합니다.');
    WHEN e_null_sign_up THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.');
    WHEN e_invalid_sign_up THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, '잘못 입력하였습니다.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '회원가입이 불가능합니다.');
END;


-- 회원가입 실행
BEGIN 
mk_p_sign_up (
    '1231254sdfsdf', -- ID
    'passleehyo12345', -- PW
    '제주특별자치도 제주시 한라대학로 38', --  주소
    'lhl10minutes@naver.com', --이메일
    '이효리', -- 이름
    '1979.01.01', -- 생년월일
    0, -- 성별
    '010-2851-5445', -- 전화번호
    1, -- 이용약관 동의 여부 (필수)
    1, -- 만 14세 여부 (필수)
    1, -- sms 수신 여부 (선택)
    1, -- 이메일 수신 여부 (선택)
    1, -- 개인정보 동의 여부 (필수)
    null, -- 추천인
    null -- 참여 이벤트
    );
END;




