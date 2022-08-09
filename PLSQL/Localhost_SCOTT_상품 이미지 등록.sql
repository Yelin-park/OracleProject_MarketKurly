[2-1. 상품 이미지 등록]
1) 상품 이미지 코드 시퀀스 생성

CREATE SEQUENCE seq_mk_productimg_code
INCREMENT BY 1
START WITH 31
NOMAXVALUE
MINVALUE 1
NOCYCLE;


1-1) 상품 이미지 코드 시퀀스 삭제
DROP SEQUENCE seq_mk_productimg_code;

-----------------------------------------------
2) 상품 이미지 등록 프로시저 생성
CREATE OR REPLACE PROCEDURE mk_p_productimg
(
    pP_CODE product_img.p_code%TYPE
    , pFILE_PATH product_img.file_path%TYPE
)
IS
    vP_CODE product_img.p_code%TYPE;
    
    e_null_productimg EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_null_productimg, -01400);
    
BEGIN
    SELECT p_code INTO vP_CODE
    FROM product
    WHERE p_code = pP_CODE;

    INSERT INTO product_img VALUES (seq_mk_productimg_code.nextval, pP_CODE, pFILE_PATH);
  
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, '상품 코드가 존재하지 않습니다.');
    WHEN e_null_productimg THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.'); -- 필수입력 사항 확인         
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '상품 이미지 등록이 불가능합니다.');
END;


----------------------------------------------------------------
3) 테스트
EXEC MK_P_PRODUCTIMG(10 , 'C:\admin\marketKurlyProject');

SELECT * FROM product_img;

--------------------------------------------------------------------
4) 예외처리 테스트
EXEC MK_P_PRODUCTIMG(100, 'C:\admin\marketKurlyProject'); -- 상품 코드 존재 X
EXEC MK_P_PRODUCTIMG(10 , null); -- 필수항목 입력


