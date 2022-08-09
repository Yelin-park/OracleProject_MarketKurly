[2-2. 상품 상세페이지 등록]
1) 상품 상세페이지 코드 시퀀스 생성

CREATE SEQUENCE seq_mk_productdetail_code
INCREMENT BY 1
START WITH 11
NOMAXVALUE
MINVALUE 1
NOCYCLE;


1-1) 상품 상세페이지 코드 시퀀스 삭제
DROP SEQUENCE seq_mk_productdetail_code;

-----------------------------------------------
2) 상품 상세페이지 등록 프로시저 생성
CREATE OR REPLACE PROCEDURE mk_p_productdetail
(
    pP_CODE product_detail.P_CODE%TYPE
    , pPD_TYPE product_detail.PD_TYPE%TYPE
    , pPD_CONTENT product_detail.PD_CONTENT%TYPE
)
IS
    vPD_TYPE product_detail.PD_TYPE%TYPE;
    
    e_no_pd_type EXCEPTION;
    e_null_productdetail EXCEPTION;
    e_no_pcode EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_null_productdetail, -01400);
    PRAGMA EXCEPTION_INIT (e_no_pcode, -02291);
    
BEGIN
    IF pPD_TYPE IN ('설명', '알레르기정보', '영양정보', '원산지') THEN
        vPD_TYPE := pPD_TYPE;
    ELSE
        RAISE e_no_pd_type;
    END IF;

    INSERT INTO product_detail VALUES (seq_mk_productdetail_code.nextval, pP_CODE, vPD_TYPE, pPD_CONTENT);
    COMMIT;
    
EXCEPTION
    WHEN e_no_pcode THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, '상품 코드가 존재하지 않습니다.');
    WHEN e_no_pd_type THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, '상세타입은 설명, 알레르기정보, 영양정보, 원산지만 입력이 가능합니다.');        
    WHEN e_null_productdetail THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.');         
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '상품 상세페이지 등록이 불가능합니다.');
END;


----------------------------------------------------------------
3) 테스트
EXEC MK_P_PRODUCTDETAIL(4, '원산지', '제주도');
EXEC MK_P_PRODUCTDETAIL(4, '설명', '제주도에서 올라온 싱싱한 은갈치!');
EXEC MK_P_PRODUCTDETAIL(4, '알레르기정보', '없음');
EXEC MK_P_PRODUCTDETAIL(4, '영양정보', '[영양정보 이미지 파일 경로]');

SELECT *
FROM product_detail;

--------------------------------------------------------------------
4) 예외처리 테스트
EXEC MK_P_PRODUCTDETAIL(100, '원산지', '제주도'); -- 상품 코드 존재 X
EXEC MK_P_PRODUCTDETAIL(4, '포장상태', '종이박스'); -- 상세타입 체크 제약조건 위배
EXEC MK_P_PRODUCTDETAIL(4, '설명', null); -- 필수항목 입력 체크



