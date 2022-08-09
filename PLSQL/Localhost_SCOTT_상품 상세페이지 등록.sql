[2-2. ��ǰ �������� ���]
1) ��ǰ �������� �ڵ� ������ ����

CREATE SEQUENCE seq_mk_productdetail_code
INCREMENT BY 1
START WITH 11
NOMAXVALUE
MINVALUE 1
NOCYCLE;


1-1) ��ǰ �������� �ڵ� ������ ����
DROP SEQUENCE seq_mk_productdetail_code;

-----------------------------------------------
2) ��ǰ �������� ��� ���ν��� ����
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
    IF pPD_TYPE IN ('����', '�˷���������', '��������', '������') THEN
        vPD_TYPE := pPD_TYPE;
    ELSE
        RAISE e_no_pd_type;
    END IF;

    INSERT INTO product_detail VALUES (seq_mk_productdetail_code.nextval, pP_CODE, vPD_TYPE, pPD_CONTENT);
    COMMIT;
    
EXCEPTION
    WHEN e_no_pcode THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, '��ǰ �ڵ尡 �������� �ʽ��ϴ�.');
    WHEN e_no_pd_type THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20009, '��Ÿ���� ����, �˷���������, ��������, �������� �Է��� �����մϴ�.');        
    WHEN e_null_productdetail THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.');         
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '��ǰ �������� ����� �Ұ����մϴ�.');
END;


----------------------------------------------------------------
3) �׽�Ʈ
EXEC MK_P_PRODUCTDETAIL(4, '������', '���ֵ�');
EXEC MK_P_PRODUCTDETAIL(4, '����', '���ֵ����� �ö�� �̽��� ����ġ!');
EXEC MK_P_PRODUCTDETAIL(4, '�˷���������', '����');
EXEC MK_P_PRODUCTDETAIL(4, '��������', '[�������� �̹��� ���� ���]');

SELECT *
FROM product_detail;

--------------------------------------------------------------------
4) ����ó�� �׽�Ʈ
EXEC MK_P_PRODUCTDETAIL(100, '������', '���ֵ�'); -- ��ǰ �ڵ� ���� X
EXEC MK_P_PRODUCTDETAIL(4, '�������', '���̹ڽ�'); -- ��Ÿ�� üũ �������� ����
EXEC MK_P_PRODUCTDETAIL(4, '����', null); -- �ʼ��׸� �Է� üũ



