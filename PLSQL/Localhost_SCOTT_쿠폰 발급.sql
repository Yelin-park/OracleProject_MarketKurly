[6. 쿠폰 발급]
1) 마이쿠폰코드 시퀀스 생성
/*
CREATE SEQUENCE seq_mycoupon_code
INCREMENT BY 1
START WITH 7
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) 마이쿠폰코드 시퀀스 삭제
-- DROP SEQUENCE seq_mycoupon_code;
--------------------------------------------------
2) 마이쿠폰발급하는 저장프로시저 생성
CREATE OR REPLACE PROCEDURE mk_p_mycoupon
(
    pCOU_ID my_coupon.COU_ID%TYPE
    , pC_CODE my_coupon.C_CODE%TYPE
    , pMCOU_END my_coupon.MCOU_END%TYPE
    , pMCOU_CHECK my_coupon.MCOU_CHECK%TYPE
)
IS
    vMCOU_END my_coupon.MCOU_END%TYPE;
    vMCOU_CHECK my_coupon.MCOU_CHECK%TYPE;
    
    e_mcou_end EXCEPTION;
    e_mcou_check EXCEPTION;
    e_no_coupon_code EXCEPTION;
    e_null_mycoupon EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_coupon_code, -02291);
    PRAGMA EXCEPTION_INIT (e_null_mycoupon, -01400);
    
BEGIN   
    IF TRUNC(SYSDATE) <= pMCOU_END THEN
        vMCOU_END := pMCOU_END;
    ELSE
        RAISE e_mcou_end;
    END IF;
    
    IF pMCOU_CHECK = 0 THEN
        vMCOU_CHECK := pMCOU_CHECK;
    ELSE
        RAISE e_mcou_check;
    END IF;    
    
    INSERT INTO my_coupon VALUES(seq_mycoupon_code.nextval, pCOU_ID, pC_CODE, vMCOU_END, vMCOU_CHECK);
    COMMIT;
    
EXCEPTION
    WHEN e_no_coupon_code THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, '회원코드 또는 쿠폰코드가 존재하지 않습니다.');
    WHEN e_mcou_end THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, '쿠폰 종료 일자는 오늘날짜이거나 더 커야합니다.');
    WHEN e_mcou_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, '사용가능한 쿠폰을 발급해주세요. (사용가능 0 입력)');           
    WHEN e_null_mycoupon THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '쿠폰 발급이 불가능합니다.');
END;

--------------------------------------------------
3) 쿠폰발급 테스트 및 확인
EXEC MK_P_MYCOUPON (1, 2, '2022.05.10', 0);

SELECT * FROM my_coupon;

--------------------------------------------------
4) 예외처리 확인
EXEC MK_P_MYCOUPON (100, 2, '2022.05.10', 0); -- 쿠폰 코드 존재 X
EXEC MK_P_MYCOUPON (1, 50, '2022.05.10', 0); -- 회원 코드 존재 X
EXEC MK_P_MYCOUPON (1, 1, '2022.03.10', 0); -- 쿠폰종료일자 <= 오늘날짜
EXEC MK_P_MYCOUPON (1, 2, '2022.05.10', 1); -- 사용한 쿠폰 발급
EXEC MK_P_MYCOUPON (1, null, '2022.05.10', 0); -- 필수항목 입력 X

