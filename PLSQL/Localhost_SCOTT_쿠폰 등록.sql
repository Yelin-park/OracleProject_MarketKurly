[5. 쿠폰 등록]
1) 쿠폰코드 시퀀스 생성
/*
CREATE SEQUENCE seq_cou_id
INCREMENT BY 1
START WITH 10
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) 쿠폰코드 시퀀스 삭제
-- DROP SEQUENCE seq_cou_id;

--------------------------------------------------
2) 쿠폰등록 저장프로시저 생성
CREATE OR REPLACE PROCEDURE mk_p_coupon
(
    pCOU_NAME coupon.COU_NAME%TYPE
    , pCOU_FUNCTION coupon.COU_FUNCTION%TYPE
    , pCOU_DISCOUNT coupon.COU_DISCOUNT%TYPE
    , pCOU_D_RATE coupon.COU_D_RATE%TYPE
)
IS
    vCOU_DISCOUNT coupon.COU_DISCOUNT%TYPE;
    vCOU_D_RATE coupon.COU_D_RATE%TYPE;
    
    e_cou_discount EXCEPTION;
    e_cou_drate EXCEPTION;
    e_null_coupon EXCEPTION;
    e_coupon EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_null_coupon, -01400);
    
BEGIN   
    IF pCOU_DISCOUNT > 0 AND pCOU_D_RATE BETWEEN 0 AND 1 THEN
        RAISE e_coupon;
    ELSE
        IF pCOU_DISCOUNT >= 0 THEN
            vCOU_DISCOUNT := pCOU_DISCOUNT;
        ELSE
            RAISE e_cou_discount;
        END IF;
        
        IF pCOU_D_RATE BETWEEN 0 AND 1 THEN
            vCOU_D_RATE := pCOU_D_RATE;
        ELSE
            RAISE e_cou_drate;
        END IF;        
    END IF;

    INSERT INTO coupon VALUES(seq_cou_id.nextval, pCOU_NAME, pCOU_FUNCTION, vCOU_DISCOUNT, vCOU_D_RATE);
    COMMIT;
EXCEPTION
    WHEN e_cou_discount THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, '쿠폰 할인적용금액은 0원 이상으로 입력해 주세요.');
    WHEN e_cou_drate THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, '쿠폰 할인율은 0.00 ~ 1.00(0% ~ 100%) 사이의 값으로 입력해주세요.');
    WHEN e_coupon THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20200, '쿠폰 할인율과 쿠폰 할인적용금액 중 하나만 입력해 주세요.');           
    WHEN e_null_coupon THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '쿠폰 등록이 불가능합니다.');
END;

--------------------------------------------------
3) 쿠폰등록 테스트 및 확인
EXEC MK_P_COUPON('컬리는 탄수화물 중독자를 지지합니다!', '쌀, 잡곡 20% 할인', 0, 0.2);

SELECT * FROM coupon;

--------------------------------------------------
4) 예외처리 확인
EXEC MK_P_COUPON('컬리는 탄수화물 중독자를 지지합니다!', '쌀, 잡곡 20% 할인', 5000, 0.5); -- 쿠폰 할인율과 쿠폰 할인적용금액 둘 중 하나만 입력
EXEC MK_P_COUPON('컬리는 탄수화물 중독자를 지지합니다!', '쌀, 잡곡 20% 할인', 0, 10); -- 할인율 제약조건 위반
EXEC MK_P_COUPON('컬리는 탄수화물 중독자를 지지합니다!', '쌀, 잡곡 20% 할인', -500, 0); -- 할인금액 제약조건 위반
EXEC MK_P_COUPON('컬리는 탄수화물 중독자를 지지합니다!', null, 0, 0.2); -- 필수항목

