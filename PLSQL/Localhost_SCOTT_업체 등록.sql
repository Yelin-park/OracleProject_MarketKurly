[3. 업체등록]
1) 업체코드 시퀀스 생성
/*
CREATE SEQUENCE seq_mk_vendor_code
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) 업체코드 시퀀스 삭제
-- DROP SEQUENCE seq_mk_vendor_code;

--------------------------------------------------
2) 업체등록 저장프로시저 생성
CREATE OR REPLACE PROCEDURE mk_p_vendor
(
    pV_NAME vendor.v_name%TYPE
    , pV_FEES vendor.v_fees%TYPE        
    , pV_CUMUL vendor.v_cumul%TYPE      
    , pV_CEO_NAME vendor.v_ceo_name%TYPE  
    , pV_CEO_PHONE vendor.v_ceo_phone%TYPE
    , pMKEMP_NO vendor.mkemp_no%TYPE   
)
IS
    e_no_mkemp EXCEPTION;
    e_null_vendor EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_mkemp, -02291);
    PRAGMA EXCEPTION_INIT (e_null_vendor, -01400);
BEGIN
    INSERT INTO vendor (V_CODE, V_NAME, V_FEES, V_CUMUL, V_CEO_NAME, V_CEO_PHONE, MKEMP_NO) VALUES (seq_mk_vendor_code.nextval, pV_NAME, pV_FEES, pV_CUMUL, pV_CEO_NAME, pV_CEO_PHONE, pMKEMP_NO);
    COMMIT;
EXCEPTION
    WHEN e_no_mkemp THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, '직원번호가 존재하지 않습니다.');
    WHEN e_null_vendor THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.');        
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '업체 등록이 불가능합니다.');
END;

--------------------------------------------------
3) 업체등록 테스트 및 확인
EXEC MK_P_VENDOR('동원', 4000, 2800000, '최사장', '010-8282-4848', 7);

SELECT * FROM vendor;

--------------------------------------------------
4) 예외처리 확인
EXEC MK_P_VENDOR('동원', 4000, 2800000, '최사장', '010-8282-4848', 20); -- 직원번호 존재 X
EXEC MK_P_VENDOR('동원', 4000, 2800000, null, '010-8282-4848', 5); -- 필수항목 입력