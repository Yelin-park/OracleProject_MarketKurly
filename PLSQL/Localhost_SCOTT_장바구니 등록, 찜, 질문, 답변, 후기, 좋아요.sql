
-- 맨 아래 기능들 사용한거 예시 있슴당..
-- 근데 몇개는 다시 확인을 안해봐서 에러 날수도 있슴당..
------------------ 김민 ---------------------------
--1. 장바구니 등록
DESC cart;
seqCART, pc_code, pp_code, 1, pCART_COUNT
, vCART_PRICE*pCART_COUNT, TRUNC(vCART_PRICE*pCART_COUNT*ACCUM)
이름            널?       유형        
------------- -------- --------- 
CART_CODE     NOT NULL NUMBER    -- 장바구니코드
C_CODE                 NUMBER    -- 회원코드
P_CODE                 NUMBER    -- 상품코드
CART_SELECT   NOT NULL NUMBER(1) -- 선택여부
CART_COUNT    NOT NULL NUMBER(4) -- 수량
CART_PRICE    NOT NULL NUMBER    -- 가격
CART_RESERVES NOT NULL NUMBER    -- 적립금(계산)
DROP SEQUENCE seqcart;
CREATE SEQUENCE seqCART
INCREMENT BY 1
START WITH 11
NOMAXVALUE
MINVALUE 1
NOCYCLE;

SELECT *
FROM cart;

-- 장바구니 등록 매개변수 : 회원코드, 상품코드,수량
EXEC p_cart_regist( 2, 6, 5)
-- 장바구니 수량 변경
EXEC p_cart_regist( 2, 6, 3)

DESC cart;
CREATE OR REPLACE PROCEDURE p_cart_regist
(
  pc_code            cart.c_code%TYPE       -- 회원코드
  , pp_code          cart.p_code%TYPE     -- 상품코드
  , pCART_COUNT      cart.cart_count%TYPE -- 수량
)
IS
    vCART_PRICE     cart.cart_price%TYPE;       -- 가격
    vCART_RESERVES  cart.CART_RESERVES%TYPE;    -- 적립금
    vc_code         cart.c_code%TYPE;
    vACCUM          customer_grade.ACCUM%TYPE;  -- 등급에 따른 적립률
    
    e_value_large_cart_count EXCEPTION;
    pragma EXCEPTION_INIT( e_value_large_cart_count , -01438 );
BEGIN
     SELECT p_price INTO vCART_PRICE FROM product WHERE p_code = pp_code; -- 상품의 가격을 변수에 저장
     
     SELECT ACCUM INTO vACCUM  -- 회원의 등급의 적립률을 변수에 저장
     FROM customer_grade cg join customer ct on cg.grade = ct.grade
     WHERE c_code = pc_code;
     
     SELECT COUNT(c_code) INTO vc_code FROM cart WHERE c_code = pc_code AND p_code = pp_code; 
     -- 회원코드와 상품코드가 같다면 수량만 업데이트 하기위해 vc_code변수에 회원코드 저장( 0 없음, 1 있음)
     -- (CART_CODE , C_CODE , P_CODE , CART_SELECT , CART_COUNT , CART_PRICE , CART_RESERVES) 
     IF vc_code = 0 THEN
         INSERT INTO cart VALUES ( seqCART.nextval, pc_code, pp_code,1, pcart_count, vcart_price*pcart_count,TRUNC(vcart_price*pcart_count*vACCUM) );
         -- 장바구니번호, 회원번호, 상품번호, 선택여부, 수량, 가격, 적립금
     ELSIF vc_code = 1 AND pCART_COUNT > 0 THEN
         UPDATE cart
         SET CART_COUNT = pCART_COUNT,cart_price = vcart_price*pcart_count
            , cart_reserves =  TRUNC(vcart_price*pcart_count*vACCUM)
         WHERE c_code = pc_code AND p_code = pp_code;
     ELSIF pCART_COUNT = 0 THEN
        DELETE FROM cart WHERE c_code = pc_code AND p_code = pp_code;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20980,'등록하려는 회원이나 상품이 없습니다.');
    WHEN e_value_large_cart_count THEN  
      RAISE_APPLICATION_ERROR(-20990,'수량이 너무 많습니다.(최대 수량 : 9999)');
END;
--------------------------------------------------------------------------------
-- 장바구니 등록 매개변수 : 회원코드, 상품코드,수량
EXEC p_cart_regist( 2, 6, 5);
-- 장바구니 수량 변경 : 회원코드, 상품코드, 수량
EXEC p_cart_regist( 2, 6, 3);
-- 회원코드와 상품코드가 이미 같이 존재하면 수량, 가격, 적립금 수정
-- 수량이 0으로 수정되면 레코드 삭제
EXEC p_cart_regist( 2, 6, 0);
--------------------------------------------------------------------------------
-- EXEC p_cart_checkout(회원코드, 상품코드) 를 입력하여 체크 on/off
CREATE OR REPLACE PROCEDURE p_cart_checkout
(
  pc_code cart.c_code%TYPE       -- 회원코드
  , pp_code cart.p_code%TYPE     -- 상품코드
)
IS
    vcart_code   cart.cart_code%TYPE;
BEGIN
  
    SELECT cart_code INTO vcart_code
    FROM cart
    WHERE c_code = pc_code AND p_code = pp_code;
    
    UPDATE cart
    SET cart_SELECT = DECODE(cart_SELECT,1,0,0,1)
    WHERE cart_code = vcart_code;
-- EXCEPTION
END;
----------------------------------------------------------------------------------------
-- EXEC p_cart_checkALL(회원 코드) 를 하게되면 회원의 모든 장바구니를 전체선택/전체 해제
CREATE OR REPLACE PROCEDURE p_cart_checkall
(
  pc_code cart.c_code%TYPE       -- 회원코드
)
IS
  vnum     number;
  vcart_select   cart.cart_select%TYPE;
BEGIN
      SELECT COUNT(cart_select) INTO vnum
      FROM cart
      WHERE c_code = pc_code AND cart_select = 1;
      
      IF vnum = 0 THEN
        UPDATE cart
        SET cart_select = 1
        WHERE c_code = pc_code;
      ELSE
        UPDATE cart
        SET cart_select = 0
        WHERE c_code = pc_code;
      END IF;  
-- EXCEPTION
END;


-- 회원코드, 상품코드      선택ON/OFF
EXEC p_cart_checkout(1,6);
-- 회원코드              전체선택 ON/OFF
EXEC p_cart_checkall(1);

----------------------------------------------------------------------------------------
--2. 찜목록 등록
CREATE SEQUENCE seqwish
INCREMENT BY 1
START WITH 14
NOMAXVALUE
MINVALUE 1
NOCYCLE;

SELECT *
FROM wish;

DESC wish;
WISH_CODE NOT NULL NUMBER   -- 찜코드
P_CODE             NUMBER   -- 상품코드
C_CODE             NUMBER   -- 회원코드
CREATE OR REPLACE PROCEDURE p_wish_regist
(
   pp_code  wish.p_code%TYPE
   ,pc_code  wish.c_code%TYPE
)
IS
   vnum      number(1);
   vp_code   wish.p_code%TYPE;
   vc_code   wish.c_code%TYPE;
BEGIN
    SELECT COUNT(wish_code) INTO vnum
    FROM wish
    WHERE p_code = pp_code AND c_code = pc_code;
    IF vnum = 0 THEN
       INSERT INTO wish VALUES( seqwish.nextval, pp_code, pc_code );
    END IF;   
--EXCEPTION
END;
----------------------------------------------------------------------------------------
-- 찜목록 등록 매개변수 : 회원코드, 상품코드
EXEC p_wish_regist(2,3);
----------------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE p_wish_delete
(
   pc_code  wish.c_code%TYPE
   ,pp_code  wish.p_code%TYPE
   
)
IS
   vnum      number;
   vp_code   wish.p_code%TYPE;
   vc_code   wish.c_code%TYPE;
BEGIN
       SELECT wish_code INTO vnum
       FROM wish
       WHERE p_code = pp_code AND c_code = pc_code;
       
       DELETE FROM wish WHERE p_code = pp_code AND c_code = pc_code;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20980,'삭제하려는 회원의 찜목록이 없습니다.');
END;
----------------------------------------------------------------------------------------
SELECT *
FROM wish;
ROLLBACK;
-- 찜목록 삭제  exec p_wish_delete(회원번호,상품번호)
exec p_wish_delete(4,5);
----------------------------------------------------------------------------------------
--3. 질문 등록
-- (1) QA에 관한 시퀀스 생성
CREATE SEQUENCE seqQA
INCREMENT BY 1
START WITH 6
NOMAXVALUE
MINVALUE 1
NOCYCLE;
-- Sequence SEQQA이(가) 생성되었습니다.

이름        널?       유형             
--------- -------- -------------- 
Q_CODE    NOT NULL NUMBER         -- 질문글 코드
C_CODE             NUMBER         -- 회원 코드
P_CODE             NUMBER         -- 상품 코드
Q_TITLE   NOT NULL VARCHAR2(50)   -- 질문 제목
Q_SYSD    NOT NULL DATE           -- 질문 작성일
Q_STATE   NOT NULL NUMBER(1)      -- 답변 상태
Q_CONTENT NOT NULL VARCHAR2(4000) -- 질문 내용
Q_ANSWER  NOT NULL VARCHAR2(4000) -- 답변 내용

SELECT *
FROM QUESTION;
-- 1	2	6	유통기한질문	22/02/22	0	유통기한 어떻게 되죠?	10일 정도입니다.
-- 2    4   7   배송질문     SYSDATE   null  언제도착하나요?         null 
-- 질문 작성일, 답변 상태, 답변 내용 입력이 안될시 -> DEFAULT SYSDATE, 'X' , 'X'

----------------------------------------------------------------------------------------
-- (2) 질문 프로시저 생성  Qproduct
CREATE OR REPLACE PROCEDURE p_Qproduct
(
    pc_code    customer.c_code%TYPE    -- 회원코드
    ,pp_code    product.p_code%TYPE    -- 상품코드
    ,pQ_title   question.q_title%TYPE   -- 질문제목
    ,pQ_content question.q_content%TYPE -- 질문내용
)
IS
    vq_code question.q_code%TYPE;
    vc_code customer.c_code%TYPE;
    vp_code product.p_code%TYPE;
BEGIN
    SELECT c_code 
       INTO vc_code
    FROM customer
    WHERE c_code = pc_code;

    SELECT p_code
       INTO vp_code
    FROM product
    WHERE p_code = pp_code;
     
    INSERT INTO QUESTION (  q_code , c_code, p_code, q_title, Q_SYSD, Q_STATE, q_content, Q_ANSWER )
    VALUES ( seqQA.nextval , pc_code, pp_code, pq_title, SYSDATE, 0, pq_content, 'X' );
    
    DBMS_OUTPUT.PUT_LINE( '[질문코드 : ' || vq_code || '] [회원코드 : ' || pc_code || '] [상품코드 : ' || pp_code
         ||'] [질문 제목 : ' || pq_title || '] [질문등록날짜 : '|| SYSDATE || '] [답변상태 : ' || 0 ||
         '] [질문내용 : ' || pq_content || '] [답변 내용 : ' || 'X]');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20980, '질문하려는 회원/상품이 없습니다.');
    WHEN VALUE_ERROR  THEN
    RAISE_APPLICATION_ERROR(-20981, '제목,내용이 허용범위를 넘어섰습니다.');
END;

----------------------------------------------------------------------------------------
 -- 질문 등록     매개변수 : 회원번호, 상품번호, 질문제목, 질문 내용
exec p_qproduct(4,1,'배송지연','언제 배송이 완료될까요?');

ROLLBACK;

SELECT *
FROM QUESTION;
----------------------------------------------------------------------------------------
-- (3) 답변 프로시저 생성  Aproduct
CREATE OR REPLACE PROCEDURE p_Aproduct
(
  pq_code question.q_code%TYPE       -- 질문 번호
  , pq_answer question.q_answer%TYPE -- 답변 내용
)
IS
BEGIN
    UPDATE QUESTION
    SET Q_STATE = 1, Q_ANSWER = pq_answer
    WHERE q_code = pq_code;
EXCEPTION
   WHEN VALUE_ERROR  THEN
     RAISE_APPLICATION_ERROR(-20100, '답변내용이 허용범위를 넘어섰습니다..');
END;

----------------------------------------------------------------------------------------
 -- 답변 등록 ( 리스트확인 -> 질문번호체크 -> 매개변수 : 질문번호, 답변내용 )
 exec p_aproduct(7, '30일쯤 도착합니다^^');
 
 SELECT *
 FROM QUESTION;
----------------------------------------------------------------------------------------
--4. 후기 등록
이름        널?       유형             
--------- -------- -------------- 
R_CODE    NOT NULL NUMBER         -- 후기글코드   시퀀스
C_CODE             NUMBER         -- 회원코드      v
P_CODE             NUMBER         -- 상품코드      v
RTITLE    NOT NULL VARCHAR2(30)   -- 후기제목      v
R_DATE    NOT NULL DATE           -- 후기작성일
R_HELP    NOT NULL NUMBER         -- 도움
R_CHECK   NOT NULL NUMBER         -- 조회수
R_CONTENT NOT NULL VARCHAR2(4000) -- 후기내용      v
-- (1) review에 관한 시퀀스 생성   [ seqRV  ]
DROP SEQUENCE seqRV;
CREATE SEQUENCE seqRV
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;
-- Sequence SEQRV이(가) 생성되었습니다.


DESC review;

SELECT *
FROM review;
-- (2) 후기 글 작성 프로시저 생성  RVproduct

CREATE OR REPLACE PROCEDURE p_RVproduct
(
  pC_CODE       review.c_code%TYPE
  , pP_CODE     review.P_CODE%TYPE
  , pRTITLE     review.RTITLE%TYPE
  , pR_CONTENT  review.R_CONTENT%TYPE
)
IS
  e_value_large_rtitle EXCEPTION;
  pragma EXCEPTION_INIT( e_value_large_rtitle , -12899 );
  
BEGIN
    INSERT INTO review VALUES ( seqRV.nextval, pc_code, pp_code, prtitle, SYSDATE, 0, 0, pr_content);
EXCEPTION
     WHEN e_value_large_rtitle THEN
       RAISE_APPLICATION_ERROR(-20982, '제목, 후기내용이 허용범위를 넘어섰습니다.');
END;
---------------------------------------------------------------
-- 후기 등록   ( 매개변수 : 회원코드, 상품코드, 후기 제목, 후기내용
EXEC p_RVproduct ( 4, 7, '굳..', '먹어본 것 중에 제일 맛있습니다.' );
-- 제목이 길이를 넘을때 (30 byte)
EXEC p_RVproduct ( 4, 7, '굳가나다라마바사아자차카타파하굳가나다라마바사아자차카타파하굳가나다라마바사아자차카타파하', '먹어본 것 중에 제일 맛있습니다.' );

SELECT *
FROM review;
---------------------------------------------------------------
-- (3) 도움 컬럼 증가 프로시저 rv_good
CREATE OR REPLACE PROCEDURE p_rv_good
(
   pr_code review.r_code%TYPE
)
IS
   vr_code review.r_code%TYPE;
BEGIN
    SELECT r_code
       INTO vr_code
    FROM review
    WHERE r_code = pr_code;

   UPDATE review
   SET r_help = r_help + 1
   WHERE r_code = pr_code;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20983, '등록된 후기번호가 없습니다.');
END;
-- Procedure RV_GOOD이(가) 컴파일되었습니다.
---------------------------------------------------------------
-- 좋아요   매개변수 : 후기번호
EXEC p_rv_good(10);
---------------------------------------------------------------
--5. 배송지 등록
-- (1) shipping에 관한 시퀀스 생성 seqship
DROP SEQUENCE seqSHIP;
CREATE SEQUENCE seqSHIP
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
CREATE OR REPLACE PROCEDURE p_shipping
(
    pC_CODE            shipping.C_CODE%TYPE        -- 회원 코드
    ,pS_ADDRESS        shipping.S_ADDRESS%TYPE     -- 배송지
    ,pRECIPIENT        shipping.RECIPIENT%TYPE     -- 받으실 분
    ,pTELNUMBER        shipping.TELNUMBER%TYPE     -- 연락처
    ,pADDRESS_CHECK    shipping.ADDRESS_CHECK%TYPE -- 기본배송지여부
    ,pDELIVERY         shipping.DELIVERY%TYPE      -- 배송유형
)
IS
    vRECIPIENT  customer.c_name%TYPE;
    vTELNUMBER  sign_up.c_phone%TYPE;
    vs_address  shipping.S_ADDRESS%TYPE;
    vADDRESS_CHECK  shipping.ADDRESS_CHECK%TYPE;
    e_check_vio EXCEPTION;
    pragma EXCEPTION_INIT(e_check_vio, -02290);
BEGIN

   SELECT c_name INTO vRECIPIENT FROM customer WHERE c_code = pc_code;
   SELECT c_phone INTO vTELNUMBER  FROM sign_up WHERE c_code = pc_code;
   vADDRESS_CHECK := pADDRESS_CHECK;
   
   SELECT COUNT(s_address)||'1' INTO vs_address FROM shipping 
   WHERE c_code = pc_code AND s_address = ps_address AND recipient = precipient AND TELNUMBER = pTELNUMBER;
   
   IF vs_address = 01  THEN
      IF pADDRESS_CHECK = 1 THEN
         UPDATE SHIPPING SET ADDRESS_CHECK = 0 WHERE ADDRESS_CHECK = 1 AND c_code = pc_code;
         INSERT INTO shipping VALUES ( seqSHIP.nextval , pc_code, ps_address, pRECIPIENT , pTELNUMBER, pADDRESS_CHECK, pDELIVERY );
      ELSIF pADDRESS_CHECK = 0 THEN
         INSERT INTO shipping VALUES ( seqSHIP.nextval , pc_code, ps_address, pRECIPIENT , pTELNUMBER, pADDRESS_CHECK, pDELIVERY );
      END IF;
   ELSIF pADDRESS_CHECK = 1 THEN
       UPDATE SHIPPING 
       SET ADDRESS_CHECK = 0 
       WHERE ADDRESS_CHECK = 1 AND c_code = pc_code;
       
       UPDATE SHIPPING 
       SET address_check = paddress_check, delivery = pDELIVERY
       WHERE s_address = ps_address AND recipient = precipient AND telnumber = ptelnumber;
   ELSE
       UPDATE SHIPPING 
       SET address_check = paddress_check, delivery = pDELIVERY
       WHERE s_address = ps_address AND recipient = precipient AND telnumber = ptelnumber;
   END IF;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20984, '등록된 회원이 없습니다.');
   WHEN e_check_vio THEN
    RAISE_APPLICATION_ERROR(-20985, '[0, 1]값만 들어올 수 있습니다.');
END;
-- 기본배송지가(1)이 있는데 다른 추가 배송지가 기본배송지로 등록(1)하게된다면 기존 기본배송지는 0이 된다
-- 같은 회원코드에 여러개의 배송지가 등록가능하다
-- 같은 회원코드에 배송지,받으실분,연락처가 동일하다면 기존 배송지에서 기본배송지여부와 배송유형이 수정된다.
---------------------------------------------------------------
-- 배송지 등록   매개변수 : 회원코드, 배송지, 받으실분, 연락처, 기본배송지여부, 배송유형
exec p_shipping( 14, '서울 자갈치 무일대학교 96', '김라면' ,'010-9999-0389' ,2, 0);




-------------- [  정리  ]  ----------------------
--------------------------------------------------------------------------------
-- 장바구니 등록 매개변수 : 회원코드, 상품코드,수량
EXEC p_cart_regist( 2, 6, 5);
-- 장바구니 수량 변경 : 회원코드, 상품코드, 수량
EXEC p_cart_regist( 2, 6, 3);
-- 회원코드와 상품코드가 이미 같이 존재하면 수량, 가격, 적립금 수정
-- 수량이 0으로 수정되면 레코드 삭제
EXEC p_cart_regist( 2, 6, 0);
----------------------------------------------------------------------------------------
-- 회원코드, 상품코드      선택ON/OFF
EXEC p_cart_checkout(1,6);
-- 회원코드              전체선택 ON/OFF
EXEC p_cart_checkall(1);
----------------------------------------------------------------------------------------
-- 찜목록 등록 매개변수 : 회원코드, 상품코드
EXEC p_wish_regist(2,3);
----------------------------------------------------------------------------------------
-- 찜목록 삭제  exec p_wish_delete(회원번호,상품번호)
exec p_wish_delete(4,5);
----------------------------------------------------------------------------------------
 -- 질문 등록     매개변수 : 회원번호, 상품번호, 질문제목, 질문 내용
exec p_qproduct(4,1,'배송지연','언제 배송이 완료될까요?');
----------------------------------------------------------------------------------------
 -- 답변 등록 ( 리스트확인 -> 질문번호체크 -> 매개변수 : 질문번호, 답변내용 )
 exec p_aproduct(7, '30일쯤 도착합니다^^');
 
---------------------------------------------------------------
-- 후기 등록   ( 매개변수 : 회원코드, 상품코드, 후기 제목, 후기내용
EXEC p_RVproduct ( 4, 7, '굳..', '먹어본 것 중에 제일 맛있습니다.' );
-- 제목이 길이를 넘을때 (30 byte)
EXEC p_RVproduct ( 4, 7, '굳가나다라마바사아자차카타파하굳가나다라마바사아자차카타파하굳가나다라마바사아자차카타파하', '먹어본 것 중에 제일 맛있습니다.' );

---------------------------------------------------------------
-- 좋아요   매개변수 : 후기번호
EXEC p_rv_good(10);
---------------------------------------------------------------
-- 배송지 등록   매개변수 : 회원코드, 배송지, 받으실분, 연락처, 기본배송지여부, 배송유형
exec p_shipping( 14, '서울 자갈치 무일대학교 96', '김라면' ,'010-9999-0389' ,2, 0);
---------------------------------------------------------------