[1. ���� ���]
1) �����ڵ� ������ ����
/*
CREATE SEQUENCE seq_mkemp_no
INCREMENT BY 1
START WITH 14
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) �����ڵ� ������ ����
-- DROP SEQUENCE seq_mkemp_no;

--------------------------------------------------
2) ������� �������ν��� ����
CREATE OR REPLACE PROCEDURE mk_p_mkemp
(
    pMKEMP_NAME mkemp.mkemp_name%TYPE
    , pMKEMP_DATE mkemp.mkemp_date%TYPE
    , pMKEMP_RANK mkemp.mkemp_rank%TYPE
    , pMKEMP_DEPT mkemp.mkemp_dept%TYPE
)
IS
    e_null_mkemp EXCEPTION;
    PRAGMA EXCEPTION_INIT (e_null_mkemp, -01400);
BEGIN
    INSERT INTO mkemp (MKEMP_NO, MKEMP_NAME, MKEMP_DATE, MKEMP_RANK, MKEMP_DEPT) VALUES (seq_mkemp_no.nextval, pMKEMP_NAME, pMKEMP_DATE, pMKEMP_RANK, pMKEMP_DEPT);
    COMMIT;
EXCEPTION
    WHEN e_null_mkemp THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '�ʼ��׸��� �Է��� �ּ���.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '���� ����� �Ұ����մϴ�.');
END;

--------------------------------------------------
3) ������� �׽�Ʈ �� Ȯ��
EXEC mk_p_mkemp ('�̻��', SYSDATE, '���', '����');

SELECT *
FROM mkemp;

--------------------------------------------------
4) ����ó�� Ȯ��
EXEC mk_p_mkemp (null, SYSDATE, '���', '����');
EXEC mk_p_mkemp ('�̻��', null, '���', '����');
EXEC mk_p_mkemp ('�̻��', SYSDATE, null, '����');
EXEC mk_p_mkemp ('�̻��', SYSDATE, '���', null);
