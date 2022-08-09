[2. ��ǰ ���]
1) ��ǰ �ڵ� ������ ����

CREATE SEQUENCE seq_mk_product_code
INCREMENT BY 1
START WITH 11
NOMAXVALUE
MINVALUE 1
NOCYCLE;


1-1) ��ǰ �ڵ� ������ ����
DROP SEQUENCE seq_mk_product_code;

--------------------------------------------------
2) ��ǰ ��� ���� ���ν��� ���� -- ���ϰ�� �Ķ���� ������ �� ��������ǿ��ܹ߻� �� �� ����. PL/SQL ���� ��ü�� ���� ������..
CREATE OR REPLACE PROCEDURE mk_p_product
(
    pP_NAME product.p_name%TYPE
    , pP_PRICE product.P_PRICE%TYPE
    , pP_DISCOUNT product.P_DISCOUNT%TYPE
    , pP_DETAIL product.P_DETAIL%TYPE
    , pP_COLD_TYPE product.P_COLD_TYPE%TYPE
    , pV_CODE product.V_CODE%TYPE
    , pCTGR_CODE product.CTGR_CODE%TYPE
    , pB_CODE product.B_CODE%TYPE
    , pP_RDATE product.P_RDATE%TYPE
    , pPATH product_img.file_path%TYPE -- ��ǰ�̹������ �Ķ����
    , pPD_TYPE product_detail.PD_TYPE%TYPE -- ��ǰ��������Ÿ�� �Ķ����
    , pPD_CONTENT product_detail.PD_CONTENT%TYPE -- ��ǰ������������ �Ķ����
)
IS
    vP_DETAIL product.P_DETAIL%TYPE;
    vV_CODE product.V_CODE%TYPE;
    vB_CODE product.B_CODE%TYPE;
    vP_PRICE product.P_PRICE%TYPE;
    vP_DISCOUNT product.P_DISCOUNT%TYPE;
    vTOTAL_SALES product.TOTAL_SALES%TYPE := 0;
    
    e_no_code EXCEPTION;
    e_null_product EXCEPTION;
    e_cold_type EXCEPTION;
    e_price EXCEPTION;
    e_discount EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_code, -02291);
    PRAGMA EXCEPTION_INIT(e_null_product, -01400);
    PRAGMA EXCEPTION_INIT(e_cold_type, -02290);
BEGIN
    
    IF pP_DETAIL IS NOT NULL THEN
        vP_DETAIL := pP_DETAIL;
    ELSE vP_DETAIL := null;
    END IF;
    
    IF pV_CODE IS NOT NULL THEN
        vV_CODE := pV_CODE;
    ELSE vV_CODE := null;
    END IF;
    
    IF pB_CODE IS NOT NULL THEN
        vB_CODE := pB_CODE;
    ELSE vB_CODE := null;
    END IF;
    
    IF pP_price >= 0 THEN
        vP_PRICE := pP_price;
    ELSE
        RAISE e_price;
    END IF;
    
    IF pP_DISCOUNT BETWEEN 0 AND 1 THEN
        vP_DISCOUNT := pP_DISCOUNT;
    ELSE 
        RAISE e_discount;
    END IF;

    INSERT INTO product (P_CODE, P_NAME, P_PRICE, P_DISCOUNT, P_DETAIL, P_COLD_TYPE, V_CODE, CTGR_CODE, B_CODE, P_RDATE, TOTAL_SALES)
    VALUES (seq_mk_product_code.nextval, pP_NAME, vP_PRICE, pP_DISCOUNT, vP_DETAIL, pP_COLD_TYPE, vV_CODE, pCTGR_CODE, vB_CODE, pP_RDATE, vTOTAL_SALES);
    COMMIT;
        
    MK_P_PRODUCTIMG(seq_mk_product_code.currval, pPATH);
    MK_P_PRODUCTDETAIL(seq_mk_product_code.currval, pPD_TYPE, pPD_CONTENT);
    
EXCEPTION
    WHEN e_no_code THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, '��ǰ��ü / ī�װ� / Ư������ �ڵ尡 �������� �ʽ��ϴ�.');
    WHEN e_null_product THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.');
    WHEN e_cold_type THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20003, '���1, ����2, �õ�3���� �Է��� �ּ���.');
    WHEN e_price THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20005, '������ 0�� �̻����� �Է����ּ���.');
    WHEN e_discount THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, '���ΰ��� 0.00 ~ 1.00(0% ~ 100%) ������ ������ �Է����ּ���.');        
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '��ǰ ����� �Ұ����մϴ�.');
END;

----------------------------------------
3) ��ǰ ��� �׽�Ʈ �� Ȯ��
EXEC MK_P_PRODUCT('[Ŀ�Ǻ�] �ٴҶ� �� �Ŀ�ġ', 1500, 0, '�ٴҶ��� �ε巯�� �ŷ�', 2, 1, 'H5', null, SYSDATE, 'C:\admin\marketKurlyProject');
EXEC MK_P_PRODUCT('[�� �ټ�] �ٸ���Ÿ ��ü�� 330ml', 2900, 0, '�����ϰ� ������ ������ ǳ��', 2, 1, 'H5', null, SYSDATE, 'C:\admin\marketKurlyProject');

SELECT * FROM product;
SELECT * FROM product_img;

----------------------------------------
4) ����ó�� Ȯ��
EXEC MK_P_PRODUCT('[�� �ټ�] �ٸ���Ÿ ��ü�� 330ml', -2900, 0, '�����ϰ� ������ ������ ǳ��', 2, 1, 'H5', null, SYSDATE, 'C:\admin\marketKurlyProject'); -- ���� ����
EXEC MK_P_PRODUCT('[�� �ټ�] �ٸ���Ÿ ��ü�� 330ml', 2900, 100, '�����ϰ� ������ ������ ǳ��', 2, 1, 'H5', null, SYSDATE, 'C:\admin\marketKurlyProject'); -- ���ΰ� ����
EXEC MK_P_PRODUCT('[�� �ټ�] �ٸ���Ÿ ��ü�� 330ml', 2900, 0, '�����ϰ� ������ ������ ǳ��', 5, 1, 'H5', null, SYSDATE, 'C:\admin\marketKurlyProject'); -- ��³���õ�����
EXEC MK_P_PRODUCT('[�� �ټ�] �ٸ���Ÿ ��ü�� 330ml', 2900, 0, '�����ϰ� ������ ������ ǳ��', 2, 1, 'Z99', null, SYSDATE, 'C:\admin\marketKurlyProject'); -- ī�װ� �ڵ� ����
EXEC MK_P_PRODUCT(null, 2900, 0, '�����ϰ� ������ ������ ǳ��', 2, 1, 'Z99', null, SYSDATE); -- �ʼ��׸� ����

-------------------------------------------

5) ��ǰ ��Ͻ� �������� ����ϴ� �͸����ν���
DECLARE
    vp_code product.p_code%TYPE;
BEGIN
    MK_P_PRODUCT('[Ŀ�Ǻ�] �ٴҶ� �� �Ŀ�ġ', 1500, 0, '�ٴҶ��� �ε巯�� �ŷ�', 2, 1, 'H5', null, SYSDATE, 'C:\admin\marketKurlyProject');
    
    SELECT p_code INTO vp_code
    FROM product
    WHERE p_name = '[Ŀ�Ǻ�] �ٴҶ� �� �Ŀ�ġ';
    
    MK_P_PRODUCTDETAIL(vp_code, '������', '������');
    MK_P_PRODUCTDETAIL(vp_code, '����', 'Ŀ�Ǻ󿡼� ������ ����޾ƿ� �α� �޴�, �ٴҶ� �󶼸� �ø����� ����������....');
    MK_P_PRODUCTDETAIL(vp_code, '�˷���������', '����, ��� ����');
    MK_P_PRODUCTDETAIL(vp_code, '��������', '[�������� �̹��� ���� ���]');
END;

5-1) Ȯ��
SELECT *
FROM product;

SELECT *
FROM product_img;

SELECT *
FROM product_detail;
