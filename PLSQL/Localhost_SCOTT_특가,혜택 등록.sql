[4. Ư��/���� ���]
ALTER TABLE benefits
ADD CONSTRAINT FK_MKEMP_TO_BENEFITS FOREIGN KEY(mkemp_no) REFERENCES mkemp(mkemp_no);

1) Ư��/���� �ڵ� ������ ����
/*
CREATE SEQUENCE seq_mk_benefits_code
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) Ư��/���� �ڵ� ������ ����
-- DROP SEQUENCE seq_mk_benefits_code;

--------------------------------------------------
2) Ư��/���� ��� ���� ���ν��� ����
CREATE OR REPLACE PROCEDURE mk_p_benefits
(
     pB_NAME BENEFITS.B_NAME%TYPE
     , pB_IMGPATH BENEFITS.B_IMGPATH%TYPE
     , pB_START BENEFITS.B_START%TYPE
     , pB_END BENEFITS.B_END%TYPE
     , pMKEMP_NO BENEFITS.MKEMP_NO%TYPE
)
IS
    vB_START BENEFITS.B_START%TYPE;
    vB_END BENEFITS.B_END%TYPE;
    
    e_no_mkemp EXCEPTION;
    e_null_benefits EXCEPTION;
    e_b_start EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_no_mkemp, -02291);
    PRAGMA EXCEPTION_INIT (e_null_benefits, -01400);
BEGIN          
    IF TRUNC(SYSDATE) <= pB_START AND pB_START <= pB_END THEN
        vB_START := pB_START;
        vB_END := pB_END;
    ELSE
        RAISE e_b_start;
    END IF; 
    
    INSERT INTO benefits (B_CODE, B_NAME, B_IMGPATH, B_START, B_END, MKEMP_NO)
    VALUES (seq_mk_benefits_code.nextval, pB_NAME, pB_IMGPATH, vB_START, vB_END, pMKEMP_NO);
    COMMIT;
EXCEPTION
    WHEN e_no_mkemp THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20010, '������ȣ�� �������� �ʽ��ϴ�.');  -- �����ڵ� Ȯ��
    WHEN e_null_benefits THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.'); -- �ʼ��Է� ���� Ȯ�� 
    WHEN e_b_start THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, 'Ư��/���� �������� ���ó�¥�̰ų� �� Ŀ���ϸ�, �������ڿ� ���ų� �۾ƾ��մϴ�.');  
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, 'Ư��/���� ����� �Ұ����մϴ�.');
END;

----------------------------------------
3) Ư��/���� ��� �׽�Ʈ �� Ȯ��
EXEC MK_P_BENEFITS('5�� ������ �� �̺�Ʈ', 'C:\admin\marketKurlyProject', '2022.05.01', '2022.05.30', 1);

SELECT * FROM BENEFITS;

DELETE BENEFITS
WHERE b_code = 5;

----------------------------------------
4) ����ó�� Ȯ�� �� ��¥ ���� DBMS ��� Ȯ��
EXEC MK_P_BENEFITS('5�� ������ �� �̺�Ʈ', 'C:\admin\marketKurlyProject', '2022.03.01', '2022.05.30', 1); -- ���۳�¥�� ���ó�¥���� �۾Ƽ� �޽��� �����
EXEC MK_P_BENEFITS('5�� ������ �� �̺�Ʈ', 'C:\admin\marketKurlyProject', '2022.04.27', '2022.04.27', 1); -- ���ᳯ¥�� ���۳�¥���� �۾Ƽ� �޽��� �����
EXEC MK_P_BENEFITS('5�� ������ �� �̺�Ʈ', 'C:\admin\marketKurlyProject', '2022.05.01', '2022.05.30', 20); -- ������ȣ ���ٴ� ����ó��
EXEC MK_P_BENEFITS('5�� ������ �� �̺�Ʈ', 'C:\admin\marketKurlyProject', null, '2022.05.30', 1); -- �ʼ��׸� üũ ����ó��

SELECT * FROM BENEFITS;



