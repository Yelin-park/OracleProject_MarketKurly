[4. 특가/혜택 등록]
ALTER TABLE benefits
ADD CONSTRAINT FK_MKEMP_TO_BENEFITS FOREIGN KEY(mkemp_no) REFERENCES mkemp(mkemp_no);

1) 특가/혜택 코드 시퀀스 생성
/*
CREATE SEQUENCE seq_mk_benefits_code
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;
*/

1-1) 특가/혜택 코드 시퀀스 삭제
-- DROP SEQUENCE seq_mk_benefits_code;

--------------------------------------------------
2) 특가/혜택 등록 저장 프로시저 생성
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
        RAISE_APPLICATION_ERROR(-20010, '직원번호가 존재하지 않습니다.');  -- 직원코드 확인
    WHEN e_null_benefits THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, '필수항목을 입력해 주세요.'); -- 필수입력 사항 확인 
    WHEN e_b_start THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20020, '특가/혜택 시작일은 오늘날짜이거나 더 커야하며, 종료일자와 같거나 작아야합니다.');  
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20004, '특가/혜택 등록이 불가능합니다.');
END;

----------------------------------------
3) 특가/혜택 등록 테스트 및 확인
EXEC MK_P_BENEFITS('5월 가정의 달 이벤트', 'C:\admin\marketKurlyProject', '2022.05.01', '2022.05.30', 1);

SELECT * FROM BENEFITS;

DELETE BENEFITS
WHERE b_code = 5;

----------------------------------------
4) 예외처리 확인 및 날짜 조건 DBMS 출력 확인
EXEC MK_P_BENEFITS('5월 가정의 달 이벤트', 'C:\admin\marketKurlyProject', '2022.03.01', '2022.05.30', 1); -- 시작날짜가 오늘날짜보다 작아서 메시지 띄워줌
EXEC MK_P_BENEFITS('5월 가정의 달 이벤트', 'C:\admin\marketKurlyProject', '2022.04.27', '2022.04.27', 1); -- 종료날짜가 시작날짜보다 작아서 메시지 띄워줌
EXEC MK_P_BENEFITS('5월 가정의 달 이벤트', 'C:\admin\marketKurlyProject', '2022.05.01', '2022.05.30', 20); -- 직원번호 없다는 예외처리
EXEC MK_P_BENEFITS('5월 가정의 달 이벤트', 'C:\admin\marketKurlyProject', null, '2022.05.30', 1); -- 필수항목 체크 예외처리

SELECT * FROM BENEFITS;



