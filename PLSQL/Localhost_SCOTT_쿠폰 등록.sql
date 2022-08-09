[5. ���� ���]
1) �����ڵ� ������ ����
/*
CREATE SEQUENCE seq_cou_id
INCREMENT BY 1
START WITH 10
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) �����ڵ� ������ ����
-- DROP SEQUENCE seq_cou_id;

--------------------------------------------------
2) ������� �������ν��� ����
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
        RAISE_APPLICATION_ERROR(-20005, '���� ��������ݾ��� 0�� �̻����� �Է��� �ּ���.');
    WHEN e_cou_drate THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20006, '���� �������� 0.00 ~ 1.00(0% ~ 100%) ������ ������ �Է����ּ���.');
    WHEN e_coupon THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20200, '���� �������� ���� ��������ݾ� �� �ϳ��� �Է��� �ּ���.');           
    WHEN e_null_coupon THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '���� ����� �Ұ����մϴ�.');
END;

--------------------------------------------------
3) ������� �׽�Ʈ �� Ȯ��
EXEC MK_P_COUPON('�ø��� ź��ȭ�� �ߵ��ڸ� �����մϴ�!', '��, ��� 20% ����', 0, 0.2);

SELECT * FROM coupon;

--------------------------------------------------
4) ����ó�� Ȯ��
EXEC MK_P_COUPON('�ø��� ź��ȭ�� �ߵ��ڸ� �����մϴ�!', '��, ��� 20% ����', 5000, 0.5); -- ���� �������� ���� ��������ݾ� �� �� �ϳ��� �Է�
EXEC MK_P_COUPON('�ø��� ź��ȭ�� �ߵ��ڸ� �����մϴ�!', '��, ��� 20% ����', 0, 10); -- ������ �������� ����
EXEC MK_P_COUPON('�ø��� ź��ȭ�� �ߵ��ڸ� �����մϴ�!', '��, ��� 20% ����', -500, 0); -- ���αݾ� �������� ����
EXEC MK_P_COUPON('�ø��� ź��ȭ�� �ߵ��ڸ� �����մϴ�!', null, 0, 0.2); -- �ʼ��׸�

