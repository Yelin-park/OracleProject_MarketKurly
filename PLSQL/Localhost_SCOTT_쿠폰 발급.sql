[6. ���� �߱�]
1) ���������ڵ� ������ ����
/*
CREATE SEQUENCE seq_mycoupon_code
INCREMENT BY 1
START WITH 7
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) ���������ڵ� ������ ����
-- DROP SEQUENCE seq_mycoupon_code;
--------------------------------------------------
2) ���������߱��ϴ� �������ν��� ����
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
        RAISE_APPLICATION_ERROR(-20010, 'ȸ���ڵ� �Ǵ� �����ڵ尡 �������� �ʽ��ϴ�.');
    WHEN e_mcou_end THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, '���� ���� ���ڴ� ���ó�¥�̰ų� �� Ŀ���մϴ�.');
    WHEN e_mcou_check THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20030, '��밡���� ������ �߱����ּ���. (��밡�� 0 �Է�)');           
    WHEN e_null_mycoupon THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '���� �߱��� �Ұ����մϴ�.');
END;

--------------------------------------------------
3) �����߱� �׽�Ʈ �� Ȯ��
EXEC MK_P_MYCOUPON (1, 2, '2022.05.10', 0);

SELECT * FROM my_coupon;

--------------------------------------------------
4) ����ó�� Ȯ��
EXEC MK_P_MYCOUPON (100, 2, '2022.05.10', 0); -- ���� �ڵ� ���� X
EXEC MK_P_MYCOUPON (1, 50, '2022.05.10', 0); -- ȸ�� �ڵ� ���� X
EXEC MK_P_MYCOUPON (1, 1, '2022.03.10', 0); -- ������������ <= ���ó�¥
EXEC MK_P_MYCOUPON (1, 2, '2022.05.10', 1); -- ����� ���� �߱�
EXEC MK_P_MYCOUPON (1, null, '2022.05.10', 0); -- �ʼ��׸� �Է� X

