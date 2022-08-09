
-- �� �Ʒ� ��ɵ� ����Ѱ� ���� �ֽ���..
-- �ٵ� ��� �ٽ� Ȯ���� ���غ��� ���� ������ �ֽ���..
------------------ ��� ---------------------------
--1. ��ٱ��� ���
DESC cart;
seqCART, pc_code, pp_code, 1, pCART_COUNT
, vCART_PRICE*pCART_COUNT, TRUNC(vCART_PRICE*pCART_COUNT*ACCUM)
�̸�            ��?       ����        
------------- -------- --------- 
CART_CODE     NOT NULL NUMBER    -- ��ٱ����ڵ�
C_CODE                 NUMBER    -- ȸ���ڵ�
P_CODE                 NUMBER    -- ��ǰ�ڵ�
CART_SELECT   NOT NULL NUMBER(1) -- ���ÿ���
CART_COUNT    NOT NULL NUMBER(4) -- ����
CART_PRICE    NOT NULL NUMBER    -- ����
CART_RESERVES NOT NULL NUMBER    -- ������(���)
DROP SEQUENCE seqcart;
CREATE SEQUENCE seqCART
INCREMENT BY 1
START WITH 11
NOMAXVALUE
MINVALUE 1
NOCYCLE;

SELECT *
FROM cart;

-- ��ٱ��� ��� �Ű����� : ȸ���ڵ�, ��ǰ�ڵ�,����
EXEC p_cart_regist( 2, 6, 5)
-- ��ٱ��� ���� ����
EXEC p_cart_regist( 2, 6, 3)

DESC cart;
CREATE OR REPLACE PROCEDURE p_cart_regist
(
  pc_code            cart.c_code%TYPE       -- ȸ���ڵ�
  , pp_code          cart.p_code%TYPE     -- ��ǰ�ڵ�
  , pCART_COUNT      cart.cart_count%TYPE -- ����
)
IS
    vCART_PRICE     cart.cart_price%TYPE;       -- ����
    vCART_RESERVES  cart.CART_RESERVES%TYPE;    -- ������
    vc_code         cart.c_code%TYPE;
    vACCUM          customer_grade.ACCUM%TYPE;  -- ��޿� ���� ������
    
    e_value_large_cart_count EXCEPTION;
    pragma EXCEPTION_INIT( e_value_large_cart_count , -01438 );
BEGIN
     SELECT p_price INTO vCART_PRICE FROM product WHERE p_code = pp_code; -- ��ǰ�� ������ ������ ����
     
     SELECT ACCUM INTO vACCUM  -- ȸ���� ����� �������� ������ ����
     FROM customer_grade cg join customer ct on cg.grade = ct.grade
     WHERE c_code = pc_code;
     
     SELECT COUNT(c_code) INTO vc_code FROM cart WHERE c_code = pc_code AND p_code = pp_code; 
     -- ȸ���ڵ�� ��ǰ�ڵ尡 ���ٸ� ������ ������Ʈ �ϱ����� vc_code������ ȸ���ڵ� ����( 0 ����, 1 ����)
     -- (CART_CODE , C_CODE , P_CODE , CART_SELECT , CART_COUNT , CART_PRICE , CART_RESERVES) 
     IF vc_code = 0 THEN
         INSERT INTO cart VALUES ( seqCART.nextval, pc_code, pp_code,1, pcart_count, vcart_price*pcart_count,TRUNC(vcart_price*pcart_count*vACCUM) );
         -- ��ٱ��Ϲ�ȣ, ȸ����ȣ, ��ǰ��ȣ, ���ÿ���, ����, ����, ������
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
      RAISE_APPLICATION_ERROR(-20980,'����Ϸ��� ȸ���̳� ��ǰ�� �����ϴ�.');
    WHEN e_value_large_cart_count THEN  
      RAISE_APPLICATION_ERROR(-20990,'������ �ʹ� �����ϴ�.(�ִ� ���� : 9999)');
END;
--------------------------------------------------------------------------------
-- ��ٱ��� ��� �Ű����� : ȸ���ڵ�, ��ǰ�ڵ�,����
EXEC p_cart_regist( 2, 6, 5);
-- ��ٱ��� ���� ���� : ȸ���ڵ�, ��ǰ�ڵ�, ����
EXEC p_cart_regist( 2, 6, 3);
-- ȸ���ڵ�� ��ǰ�ڵ尡 �̹� ���� �����ϸ� ����, ����, ������ ����
-- ������ 0���� �����Ǹ� ���ڵ� ����
EXEC p_cart_regist( 2, 6, 0);
--------------------------------------------------------------------------------
-- EXEC p_cart_checkout(ȸ���ڵ�, ��ǰ�ڵ�) �� �Է��Ͽ� üũ on/off
CREATE OR REPLACE PROCEDURE p_cart_checkout
(
  pc_code cart.c_code%TYPE       -- ȸ���ڵ�
  , pp_code cart.p_code%TYPE     -- ��ǰ�ڵ�
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
-- EXEC p_cart_checkALL(ȸ�� �ڵ�) �� �ϰԵǸ� ȸ���� ��� ��ٱ��ϸ� ��ü����/��ü ����
CREATE OR REPLACE PROCEDURE p_cart_checkall
(
  pc_code cart.c_code%TYPE       -- ȸ���ڵ�
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


-- ȸ���ڵ�, ��ǰ�ڵ�      ����ON/OFF
EXEC p_cart_checkout(1,6);
-- ȸ���ڵ�              ��ü���� ON/OFF
EXEC p_cart_checkall(1);

----------------------------------------------------------------------------------------
--2. ���� ���
CREATE SEQUENCE seqwish
INCREMENT BY 1
START WITH 14
NOMAXVALUE
MINVALUE 1
NOCYCLE;

SELECT *
FROM wish;

DESC wish;
WISH_CODE NOT NULL NUMBER   -- ���ڵ�
P_CODE             NUMBER   -- ��ǰ�ڵ�
C_CODE             NUMBER   -- ȸ���ڵ�
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
-- ���� ��� �Ű����� : ȸ���ڵ�, ��ǰ�ڵ�
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
      RAISE_APPLICATION_ERROR(-20980,'�����Ϸ��� ȸ���� ������ �����ϴ�.');
END;
----------------------------------------------------------------------------------------
SELECT *
FROM wish;
ROLLBACK;
-- ���� ����  exec p_wish_delete(ȸ����ȣ,��ǰ��ȣ)
exec p_wish_delete(4,5);
----------------------------------------------------------------------------------------
--3. ���� ���
-- (1) QA�� ���� ������ ����
CREATE SEQUENCE seqQA
INCREMENT BY 1
START WITH 6
NOMAXVALUE
MINVALUE 1
NOCYCLE;
-- Sequence SEQQA��(��) �����Ǿ����ϴ�.

�̸�        ��?       ����             
--------- -------- -------------- 
Q_CODE    NOT NULL NUMBER         -- ������ �ڵ�
C_CODE             NUMBER         -- ȸ�� �ڵ�
P_CODE             NUMBER         -- ��ǰ �ڵ�
Q_TITLE   NOT NULL VARCHAR2(50)   -- ���� ����
Q_SYSD    NOT NULL DATE           -- ���� �ۼ���
Q_STATE   NOT NULL NUMBER(1)      -- �亯 ����
Q_CONTENT NOT NULL VARCHAR2(4000) -- ���� ����
Q_ANSWER  NOT NULL VARCHAR2(4000) -- �亯 ����

SELECT *
FROM QUESTION;
-- 1	2	6	�����������	22/02/22	0	������� ��� ����?	10�� �����Դϴ�.
-- 2    4   7   �������     SYSDATE   null  ���������ϳ���?         null 
-- ���� �ۼ���, �亯 ����, �亯 ���� �Է��� �ȵɽ� -> DEFAULT SYSDATE, 'X' , 'X'

----------------------------------------------------------------------------------------
-- (2) ���� ���ν��� ����  Qproduct
CREATE OR REPLACE PROCEDURE p_Qproduct
(
    pc_code    customer.c_code%TYPE    -- ȸ���ڵ�
    ,pp_code    product.p_code%TYPE    -- ��ǰ�ڵ�
    ,pQ_title   question.q_title%TYPE   -- ��������
    ,pQ_content question.q_content%TYPE -- ��������
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
    
    DBMS_OUTPUT.PUT_LINE( '[�����ڵ� : ' || vq_code || '] [ȸ���ڵ� : ' || pc_code || '] [��ǰ�ڵ� : ' || pp_code
         ||'] [���� ���� : ' || pq_title || '] [������ϳ�¥ : '|| SYSDATE || '] [�亯���� : ' || 0 ||
         '] [�������� : ' || pq_content || '] [�亯 ���� : ' || 'X]');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20980, '�����Ϸ��� ȸ��/��ǰ�� �����ϴ�.');
    WHEN VALUE_ERROR  THEN
    RAISE_APPLICATION_ERROR(-20981, '����,������ �������� �Ѿ���ϴ�.');
END;

----------------------------------------------------------------------------------------
 -- ���� ���     �Ű����� : ȸ����ȣ, ��ǰ��ȣ, ��������, ���� ����
exec p_qproduct(4,1,'�������','���� ����� �Ϸ�ɱ��?');

ROLLBACK;

SELECT *
FROM QUESTION;
----------------------------------------------------------------------------------------
-- (3) �亯 ���ν��� ����  Aproduct
CREATE OR REPLACE PROCEDURE p_Aproduct
(
  pq_code question.q_code%TYPE       -- ���� ��ȣ
  , pq_answer question.q_answer%TYPE -- �亯 ����
)
IS
BEGIN
    UPDATE QUESTION
    SET Q_STATE = 1, Q_ANSWER = pq_answer
    WHERE q_code = pq_code;
EXCEPTION
   WHEN VALUE_ERROR  THEN
     RAISE_APPLICATION_ERROR(-20100, '�亯������ �������� �Ѿ���ϴ�..');
END;

----------------------------------------------------------------------------------------
 -- �亯 ��� ( ����ƮȮ�� -> ������ȣüũ -> �Ű����� : ������ȣ, �亯���� )
 exec p_aproduct(7, '30���� �����մϴ�^^');
 
 SELECT *
 FROM QUESTION;
----------------------------------------------------------------------------------------
--4. �ı� ���
�̸�        ��?       ����             
--------- -------- -------------- 
R_CODE    NOT NULL NUMBER         -- �ı���ڵ�   ������
C_CODE             NUMBER         -- ȸ���ڵ�      v
P_CODE             NUMBER         -- ��ǰ�ڵ�      v
RTITLE    NOT NULL VARCHAR2(30)   -- �ı�����      v
R_DATE    NOT NULL DATE           -- �ı��ۼ���
R_HELP    NOT NULL NUMBER         -- ����
R_CHECK   NOT NULL NUMBER         -- ��ȸ��
R_CONTENT NOT NULL VARCHAR2(4000) -- �ı⳻��      v
-- (1) review�� ���� ������ ����   [ seqRV  ]
DROP SEQUENCE seqRV;
CREATE SEQUENCE seqRV
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;
-- Sequence SEQRV��(��) �����Ǿ����ϴ�.


DESC review;

SELECT *
FROM review;
-- (2) �ı� �� �ۼ� ���ν��� ����  RVproduct

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
       RAISE_APPLICATION_ERROR(-20982, '����, �ı⳻���� �������� �Ѿ���ϴ�.');
END;
---------------------------------------------------------------
-- �ı� ���   ( �Ű����� : ȸ���ڵ�, ��ǰ�ڵ�, �ı� ����, �ı⳻��
EXEC p_RVproduct ( 4, 7, '��..', '�Ծ �� �߿� ���� ���ֽ��ϴ�.' );
-- ������ ���̸� ������ (30 byte)
EXEC p_RVproduct ( 4, 7, '�������ٶ󸶹ٻ������īŸ���ϱ������ٶ󸶹ٻ������īŸ���ϱ������ٶ󸶹ٻ������īŸ����', '�Ծ �� �߿� ���� ���ֽ��ϴ�.' );

SELECT *
FROM review;
---------------------------------------------------------------
-- (3) ���� �÷� ���� ���ν��� rv_good
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
    RAISE_APPLICATION_ERROR(-20983, '��ϵ� �ı��ȣ�� �����ϴ�.');
END;
-- Procedure RV_GOOD��(��) �����ϵǾ����ϴ�.
---------------------------------------------------------------
-- ���ƿ�   �Ű����� : �ı��ȣ
EXEC p_rv_good(10);
---------------------------------------------------------------
--5. ����� ���
-- (1) shipping�� ���� ������ ���� seqship
DROP SEQUENCE seqSHIP;
CREATE SEQUENCE seqSHIP
INCREMENT BY 1
START WITH 6
NOMAXVALUE
MINVALUE 1
NOCYCLE;

 DESC shipping;
 
�̸�           ��?       ����            
------------ -------- ------------- 
S_CODE       NOT NULL NUMBER        -- ����� �ڵ�
C_CODE                NUMBER        -- ȸ�� �ڵ�
S_ADDRESS    NOT NULL VARCHAR2(500) -- �����
RECIPIENT    NOT NULL VARCHAR2(20)  -- ������ ��
TELNUMBER    NOT NULL VARCHAR2(13)  -- ����ó
ADDRESS_CHECK          NUMBER(1)    -- �⺻���������
DELIVERY     NOT NULL NUMBER(1)     -- �������


-- �����Ǻ�,����ó�� sign_up, customer ���̺��� �������°ŷ� �ؾ߰ڴ�..
-- (2) ����� ����ϴ� ���ν��� ����
CREATE OR REPLACE PROCEDURE p_shipping
(
    pC_CODE            shipping.C_CODE%TYPE        -- ȸ�� �ڵ�
    ,pS_ADDRESS        shipping.S_ADDRESS%TYPE     -- �����
    ,pRECIPIENT        shipping.RECIPIENT%TYPE     -- ������ ��
    ,pTELNUMBER        shipping.TELNUMBER%TYPE     -- ����ó
    ,pADDRESS_CHECK    shipping.ADDRESS_CHECK%TYPE -- �⺻���������
    ,pDELIVERY         shipping.DELIVERY%TYPE      -- �������
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
    RAISE_APPLICATION_ERROR(-20984, '��ϵ� ȸ���� �����ϴ�.');
   WHEN e_check_vio THEN
    RAISE_APPLICATION_ERROR(-20985, '[0, 1]���� ���� �� �ֽ��ϴ�.');
END;
-- �⺻�������(1)�� �ִµ� �ٸ� �߰� ������� �⺻������� ���(1)�ϰԵȴٸ� ���� �⺻������� 0�� �ȴ�
-- ���� ȸ���ڵ忡 �������� ������� ��ϰ����ϴ�
-- ���� ȸ���ڵ忡 �����,�����Ǻ�,����ó�� �����ϴٸ� ���� ��������� �⺻��������ο� ��������� �����ȴ�.
---------------------------------------------------------------
-- ����� ���   �Ű����� : ȸ���ڵ�, �����, �����Ǻ�, ����ó, �⺻���������, �������
exec p_shipping( 14, '���� �ڰ�ġ ���ϴ��б� 96', '����' ,'010-9999-0389' ,2, 0);




-------------- [  ����  ]  ----------------------
--------------------------------------------------------------------------------
-- ��ٱ��� ��� �Ű����� : ȸ���ڵ�, ��ǰ�ڵ�,����
EXEC p_cart_regist( 2, 6, 5);
-- ��ٱ��� ���� ���� : ȸ���ڵ�, ��ǰ�ڵ�, ����
EXEC p_cart_regist( 2, 6, 3);
-- ȸ���ڵ�� ��ǰ�ڵ尡 �̹� ���� �����ϸ� ����, ����, ������ ����
-- ������ 0���� �����Ǹ� ���ڵ� ����
EXEC p_cart_regist( 2, 6, 0);
----------------------------------------------------------------------------------------
-- ȸ���ڵ�, ��ǰ�ڵ�      ����ON/OFF
EXEC p_cart_checkout(1,6);
-- ȸ���ڵ�              ��ü���� ON/OFF
EXEC p_cart_checkall(1);
----------------------------------------------------------------------------------------
-- ���� ��� �Ű����� : ȸ���ڵ�, ��ǰ�ڵ�
EXEC p_wish_regist(2,3);
----------------------------------------------------------------------------------------
-- ���� ����  exec p_wish_delete(ȸ����ȣ,��ǰ��ȣ)
exec p_wish_delete(4,5);
----------------------------------------------------------------------------------------
 -- ���� ���     �Ű����� : ȸ����ȣ, ��ǰ��ȣ, ��������, ���� ����
exec p_qproduct(4,1,'�������','���� ����� �Ϸ�ɱ��?');
----------------------------------------------------------------------------------------
 -- �亯 ��� ( ����ƮȮ�� -> ������ȣüũ -> �Ű����� : ������ȣ, �亯���� )
 exec p_aproduct(7, '30���� �����մϴ�^^');
 
---------------------------------------------------------------
-- �ı� ���   ( �Ű����� : ȸ���ڵ�, ��ǰ�ڵ�, �ı� ����, �ı⳻��
EXEC p_RVproduct ( 4, 7, '��..', '�Ծ �� �߿� ���� ���ֽ��ϴ�.' );
-- ������ ���̸� ������ (30 byte)
EXEC p_RVproduct ( 4, 7, '�������ٶ󸶹ٻ������īŸ���ϱ������ٶ󸶹ٻ������īŸ���ϱ������ٶ󸶹ٻ������īŸ����', '�Ծ �� �߿� ���� ���ֽ��ϴ�.' );

---------------------------------------------------------------
-- ���ƿ�   �Ű����� : �ı��ȣ
EXEC p_rv_good(10);
---------------------------------------------------------------
-- ����� ���   �Ű����� : ȸ���ڵ�, �����, �����Ǻ�, ����ó, �⺻���������, �������
exec p_shipping( 14, '���� �ڰ�ġ ���ϴ��б� 96', '����' ,'010-9999-0389' ,2, 0);
---------------------------------------------------------------