--[ȸ�� �ֹ� ����]
-- 1. [ȸ�� �ֹ� ����]�� ��ü���� �ֹ��� ���� ������ INSERT
    -- 1-1. [ȸ�� �ֹ� ����]�� ���� [ȸ�� ����] ���� �ֹ� �� UPDATE

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- �ֹ���ȣ ������
CREATE SEQUENCE o_code_seq
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- Ʈ���� : ���� -> [ȸ������] ���� �ֹ�
CREATE OR REPLACE TRIGGER mk_t_order_count AFTER
INSERT OR DELETE ON mk_order
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE customer
        SET c_order_count = c_order_count + 1
        WHERE c_code = :NEW.c_code;
    ELSIF DELETING THEN
        UPDATE customer
        SET c_order_count = c_order_count - 1
        WHERE c_code = :OLD.c_code;       
    END IF;
END;

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- [��ٱ���] ��ü �ݾ� ����ϴ� �Լ�
CREATE OR REPLACE FUNCTION mk_f_total_price
(
    pc_code customer.c_code%TYPE 
)
RETURN NUMBER
IS
    vo_price mk_order.o_price%TYPE;
BEGIN
    SELECT SUM(p.p_price*(1-p_discount)*c.cart_count) INTO vo_price
    FROM cart c JOIN product p
    ON c.p_code = p.p_code
    WHERE c_code = pc_code 
    AND cart_select = 1;
    
    RETURN vo_price;
END;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- [��ۺ�] ��ü �ݾ� ����ϴ� �Լ�
CREATE OR REPLACE FUNCTION mk_f_shipping_pay
(
    pc_code customer.c_code%TYPE,
    po_price NUMBER
)
RETURN NUMBER
IS
    v_shipping_pay NUMBER;
    v_pass_check NUMBER(1);
BEGIN

    SELECT c_curlypass INTO v_pass_check
    FROM customer
    WHERE c_code = pc_code;
    
    IF po_price < 15000 THEN
        v_shipping_pay := 3000;
    ELSIF v_pass_check = 0 AND po_price < 40000 THEN
        v_shipping_pay := 3000;
    ELSE
        v_shipping_pay := 0;
    END IF;
    
    RETURN v_shipping_pay;
END;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--[ȸ���ֹ�����] �μ�Ʈ�ϴ� ���ν���
create or replace PROCEDURE mk_p_order_insert
(
    pc_code customer.c_code%TYPE, -- ȸ������
    p_curr_time mk_order.o_date%TYPE, -- �ֹ��ð�
    po_price mk_order.o_price%TYPE, -- ��ü �ֹ��ݾ�
    ps_code shipping.s_code%TYPE, -- ���������
    po_rspot mk_order.o_rspot%TYPE, -- ������ ���
    po_lobbypw mk_order.o_lobbypw%TYPE, -- �������
    po_message mk_order.o_message%TYPE, -- �޼����߼�
    po_pay_method mk_order.o_pay_method%TYPE, --���� ����
    p_shipping_pay NUMBER := 0
)
IS
    
BEGIN
    INSERT INTO mk_order
    (o_code, c_code, o_date, o_price, s_code, o_dstate, o_rspot, o_lobbypw,  o_message, o_pay_method, o_shipping_pay)
    VALUES
    (o_code_seq.nextval, pc_code, p_curr_time, po_price, ps_code, '���� �Ϸ�', po_rspot, po_lobbypw, po_message, po_pay_method, p_shipping_pay);
END;

