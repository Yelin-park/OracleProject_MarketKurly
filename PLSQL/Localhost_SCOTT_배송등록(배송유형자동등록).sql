--5. ����� ���
-- (1) shipping�� ���� ������ ���� seqship
DROP SEQUENCE seqSHIP2;

CREATE SEQUENCE seqSHIP2
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
CREATE OR REPLACE PROCEDURE p_shipping2
(
    pC_CODE            shipping.C_CODE%TYPE        -- ȸ�� �ڵ�
    ,pS_ADDRESS        shipping.S_ADDRESS%TYPE     -- �����
    ,pRECIPIENT        shipping.RECIPIENT%TYPE     -- ������ ��
    ,pTELNUMBER        shipping.TELNUMBER%TYPE     -- ����ó
    ,pADDRESS_CHECK    shipping.ADDRESS_CHECK%TYPE -- �⺻���������
)
IS
    vRECIPIENT  customer.c_name%TYPE;
    vTELNUMBER  sign_up.c_phone%TYPE;
    vs_address  shipping.S_ADDRESS%TYPE;
    vADDRESS_CHECK  shipping.ADDRESS_CHECK%TYPE;
    vDELIVERY         shipping.DELIVERY%TYPE; -- * ������� ���� �߰�
    
    e_check_vio EXCEPTION;
    pragma EXCEPTION_INIT(e_check_vio, -02290);
BEGIN

   SELECT c_name INTO vRECIPIENT FROM customer WHERE c_code = pc_code;
   SELECT c_phone INTO vTELNUMBER  FROM sign_up WHERE c_code = pc_code;
   vADDRESS_CHECK := pADDRESS_CHECK;
   
   SELECT COUNT(s_address)||'1' INTO vs_address FROM shipping 
   WHERE c_code = pc_code AND s_address = ps_address AND recipient = precipient AND TELNUMBER = pTELNUMBER;
   
    IF REGEXP_LIKE(pS_ADDRESS, '����|���|����|�뱸|�λ�|���|��û') THEN -- * ������� ���� �߰�
        vDELIVERY := 0;
    ELSE
        vDELIVERY := 1;
    END IF;    
   
   IF vs_address = 01  THEN       
      IF pADDRESS_CHECK = 1 THEN
         UPDATE SHIPPING SET ADDRESS_CHECK = 0 WHERE ADDRESS_CHECK = 1 AND c_code = pc_code;
         INSERT INTO shipping VALUES ( seqSHIP2.nextval , pc_code, ps_address, pRECIPIENT , pTELNUMBER, pADDRESS_CHECK, vDELIVERY );
         COMMIT; -- * Ŀ�� �߰�
      ELSIF pADDRESS_CHECK = 0 THEN
         INSERT INTO shipping VALUES ( seqSHIP2.nextval , pc_code, ps_address, pRECIPIENT , pTELNUMBER, pADDRESS_CHECK, vDELIVERY );
         COMMIT; -- * Ŀ�� �߰�
      END IF;
   ELSIF pADDRESS_CHECK = 1 THEN
       UPDATE SHIPPING 
       SET ADDRESS_CHECK = 0 
       WHERE ADDRESS_CHECK = 1 AND c_code = pc_code;
       COMMIT; -- * Ŀ�� �߰�
       
       UPDATE SHIPPING 
       SET address_check = paddress_check, delivery = vDELIVERY
       WHERE s_address = ps_address AND recipient = precipient AND telnumber = ptelnumber;
       COMMIT; -- * Ŀ�� �߰�
   ELSE
       UPDATE SHIPPING 
       SET address_check = paddress_check, delivery = vDELIVERY
       WHERE s_address = ps_address AND recipient = precipient AND telnumber = ptelnumber;
       COMMIT; -- * Ŀ�� �߰�
   END IF;
   
EXCEPTION
   WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20984, '��ϵ� ȸ���� �����ϴ�.');
   WHEN e_check_vio THEN
    RAISE_APPLICATION_ERROR(-20985, '[0, 1]���� ���� �� �ֽ��ϴ�.');
END;


----------------------
exec p_shipping2( 1, '���� �ڰ�ġ ���ϴ��б� 96', '����' ,'010-9999-0389', 1);
exec p_shipping2( 1, '���� �ڰ�ġ ���ϴ��б� 96', '����' ,'010-9999-0389', 1);
exec p_shipping2( 1, '��⵵ ������ �Ǽ���', '����' ,'010-9999-0389' ,1);


