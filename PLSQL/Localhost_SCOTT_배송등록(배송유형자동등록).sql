--5. 배송지 등록
-- (1) shipping에 관한 시퀀스 생성 seqship
DROP SEQUENCE seqSHIP2;

CREATE SEQUENCE seqSHIP2
INCREMENT BY 1
START WITH 6
NOMAXVALUE
MINVALUE 1
NOCYCLE;

DESC shipping;
 
이름           널?       유형            
------------ -------- ------------- 
S_CODE       NOT NULL NUMBER        -- 배송지 코드
C_CODE                NUMBER        -- 회원 코드
S_ADDRESS    NOT NULL VARCHAR2(500) -- 배송지
RECIPIENT    NOT NULL VARCHAR2(20)  -- 받으실 분
TELNUMBER    NOT NULL VARCHAR2(13)  -- 연락처
ADDRESS_CHECK          NUMBER(1)    -- 기본배송지여부
DELIVERY     NOT NULL NUMBER(1)     -- 배송유형


-- 받으실분,연락처는 sign_up, customer 테이블에서 가져오는거로 해야겠다..
-- (2) 배송지 등록하는 프로시져 생성
CREATE OR REPLACE PROCEDURE p_shipping2
(
    pC_CODE            shipping.C_CODE%TYPE        -- 회원 코드
    ,pS_ADDRESS        shipping.S_ADDRESS%TYPE     -- 배송지
    ,pRECIPIENT        shipping.RECIPIENT%TYPE     -- 받으실 분
    ,pTELNUMBER        shipping.TELNUMBER%TYPE     -- 연락처
    ,pADDRESS_CHECK    shipping.ADDRESS_CHECK%TYPE -- 기본배송지여부
)
IS
    vRECIPIENT  customer.c_name%TYPE;
    vTELNUMBER  sign_up.c_phone%TYPE;
    vs_address  shipping.S_ADDRESS%TYPE;
    vADDRESS_CHECK  shipping.ADDRESS_CHECK%TYPE;
    vDELIVERY         shipping.DELIVERY%TYPE; -- * 배송유형 변수 추가
    
    e_check_vio EXCEPTION;
    pragma EXCEPTION_INIT(e_check_vio, -02290);
BEGIN

   SELECT c_name INTO vRECIPIENT FROM customer WHERE c_code = pc_code;
   SELECT c_phone INTO vTELNUMBER  FROM sign_up WHERE c_code = pc_code;
   vADDRESS_CHECK := pADDRESS_CHECK;
   
   SELECT COUNT(s_address)||'1' INTO vs_address FROM shipping 
   WHERE c_code = pc_code AND s_address = ps_address AND recipient = precipient AND TELNUMBER = pTELNUMBER;
   
    IF REGEXP_LIKE(pS_ADDRESS, '서울|경기|대전|대구|부산|울산|충청') THEN -- * 배송유형 조건 추가
        vDELIVERY := 0;
    ELSE
        vDELIVERY := 1;
    END IF;    
   
   IF vs_address = 01  THEN       
      IF pADDRESS_CHECK = 1 THEN
         UPDATE SHIPPING SET ADDRESS_CHECK = 0 WHERE ADDRESS_CHECK = 1 AND c_code = pc_code;
         INSERT INTO shipping VALUES ( seqSHIP2.nextval , pc_code, ps_address, pRECIPIENT , pTELNUMBER, pADDRESS_CHECK, vDELIVERY );
         COMMIT; -- * 커밋 추가
      ELSIF pADDRESS_CHECK = 0 THEN
         INSERT INTO shipping VALUES ( seqSHIP2.nextval , pc_code, ps_address, pRECIPIENT , pTELNUMBER, pADDRESS_CHECK, vDELIVERY );
         COMMIT; -- * 커밋 추가
      END IF;
   ELSIF pADDRESS_CHECK = 1 THEN
       UPDATE SHIPPING 
       SET ADDRESS_CHECK = 0 
       WHERE ADDRESS_CHECK = 1 AND c_code = pc_code;
       COMMIT; -- * 커밋 추가
       
       UPDATE SHIPPING 
       SET address_check = paddress_check, delivery = vDELIVERY
       WHERE s_address = ps_address AND recipient = precipient AND telnumber = ptelnumber;
       COMMIT; -- * 커밋 추가
   ELSE
       UPDATE SHIPPING 
       SET address_check = paddress_check, delivery = vDELIVERY
       WHERE s_address = ps_address AND recipient = precipient AND telnumber = ptelnumber;
       COMMIT; -- * 커밋 추가
   END IF;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20984, '등록된 회원이 없습니다.');
   WHEN e_check_vio THEN
    RAISE_APPLICATION_ERROR(-20985, '[0, 1]값만 들어올 수 있습니다.');
END;


----------------------
exec p_shipping2( 1, '서울 자갈치 무일대학교 96', '김라면' ,'010-9999-0389', 1);
exec p_shipping2( 1, '서울 자갈치 무일대학교 96', '김라면' ,'010-9999-0389', 1);
exec p_shipping2( 1, '경기도 수원시 권선구', '김라면' ,'010-9999-0389' ,1);


