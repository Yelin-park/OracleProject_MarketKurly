[2-1. ��ǰ �̹��� ���]
1) ��ǰ �̹��� �ڵ� ������ ����

CREATE SEQUENCE seq_mk_productimg_code
INCREMENT BY 1
START WITH 31
NOMAXVALUE
MINVALUE 1
NOCYCLE;


1-1) ��ǰ �̹��� �ڵ� ������ ����
DROP SEQUENCE seq_mk_productimg_code;

-----------------------------------------------
2) ��ǰ �̹��� ��� ���ν��� ����
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
        RAISE_APPLICATION_ERROR(-20010, '��ǰ �ڵ尡 �������� �ʽ��ϴ�.');
    WHEN e_null_productimg THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.'); -- �ʼ��Է� ���� Ȯ��         
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '��ǰ �̹��� ����� �Ұ����մϴ�.');
END;


----------------------------------------------------------------
3) �׽�Ʈ
EXEC MK_P_PRODUCTIMG(10 , 'C:\admin\marketKurlyProject');

SELECT * FROM product_img;

--------------------------------------------------------------------
4) ����ó�� �׽�Ʈ
EXEC MK_P_PRODUCTIMG(100, 'C:\admin\marketKurlyProject'); -- ��ǰ �ڵ� ���� X
EXEC MK_P_PRODUCTIMG(10 , null); -- �ʼ��׸� �Է�


