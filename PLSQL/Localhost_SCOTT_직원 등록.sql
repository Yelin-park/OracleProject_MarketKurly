[1. 직원 등록]
1) 직원코드 시퀀스 생성
/*
CREATE SEQUENCE seq_mkemp_no
INCREMENT BY 1
START WITH 14
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) 직원코드 시퀀스 삭제
-- DROP SEQUENCE seq_mkemp_no;

--------------------------------------------------
2) 직원등록 저장프로시저 생성
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
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '직원 등록이 불가능합니다.');
END;

--------------------------------------------------
3) 직원등록 테스트 및 확인
EXEC mk_p_mkemp ('이상순', SYSDATE, '사원', '물류');

SELECT *
FROM mkemp;

--------------------------------------------------
4) 예외처리 확인
EXEC mk_p_mkemp (null, SYSDATE, '사원', '물류');
EXEC mk_p_mkemp ('이상순', null, '사원', '물류');
EXEC mk_p_mkemp ('이상순', SYSDATE, null, '물류');
EXEC mk_p_mkemp ('이상순', SYSDATE, '사원', null);
