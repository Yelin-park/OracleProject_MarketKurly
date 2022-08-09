[3. ��ü���]
1) ��ü�ڵ� ������ ����
/*
CREATE SEQUENCE seq_mk_vendor_code
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) ��ü�ڵ� ������ ����
-- DROP SEQUENCE seq_mk_vendor_code;

--------------------------------------------------
2) ��ü��� �������ν��� ����
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
        RAISE_APPLICATION_ERROR(-20010, '������ȣ�� �������� �ʽ��ϴ�.');
    WHEN e_null_vendor THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.');        
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '��ü ����� �Ұ����մϴ�.');
END;

--------------------------------------------------
3) ��ü��� �׽�Ʈ �� Ȯ��
EXEC MK_P_VENDOR('����', 4000, 2800000, '�ֻ���', '010-8282-4848', 7);

SELECT * FROM vendor;

--------------------------------------------------
4) ����ó�� Ȯ��
EXEC MK_P_VENDOR('����', 4000, 2800000, '�ֻ���', '010-8282-4848', 20); -- ������ȣ ���� X
EXEC MK_P_VENDOR('����', 4000, 2800000, null, '010-8282-4848', 5); -- �ʼ��׸� �Է�