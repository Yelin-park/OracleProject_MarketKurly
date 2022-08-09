-- [����] / [������] / [��������]
-- 3. [����]�� ī��, ������, ���� ���� ���� INSERT
    -- 3-1. ī��(�������, īī������, �޴��� ����) ī������ݾ� * ����������� [������] ���� INSERT
        -- 3-1-1. ���� ������ ����, [ȸ������] ���� ������ UPDATE
    -- 3-2. ������ ��� ��, [������] ���  INSERT
        -- 3-2-1. ���� ��뿡 ����, [ȸ������] ���� ������ UPDATE
    -- 3-3. ���� ��� ��, [��������] ���ó�� UPDATE

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- �������� ������
CREATE SEQUENCE pay_code_seq
INCREMENT BY 1
START WITH 1
NOMAXVALUE
MINVALUE 1
NOCYCLE;

-- ������ ������
CREATE SEQUENCE rsv_code_seq
INCREMENT BY 1
START WITH 1
NOMAXVALUE
MINVALUE 1
NOCYCLE;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- Ʈ���� : [����] ������ ���� [������] ����/��� [����] ��� ó��
CREATE OR REPLACE TRIGGER mk_t_payment_after AFTER
INSERT OR DELETE ON payment
FOR EACH ROW
DECLARE
    vc_code reserves.c_code%TYPE;
    vrsv_date reserves.rsv_date%TYPE;
    vaccum customer_grade.accum%TYPE;
BEGIN

    
    IF INSERTING THEN
    
        SELECT c_code, o_date INTO vc_code, vrsv_date
        FROM mk_order
        WHERE o_code = :NEW.o_code;
        
        SELECT accum INTO vaccum
        FROM customer c JOIN customer_grade g ON c.grade = g.grade
        WHERE c.c_code = vc_code;
        
        IF :NEW.p_method IN ('�ſ�ī��', '�������', '�޴���', 'īī�� ����') THEN
            INSERT INTO reserves(rsv_code, c_code, rsv_date, rsv_memo, rsv_end, rsv_price, o_code)
            VALUES (rsv_code_seq.nextval, vc_code, vrsv_date, '����', LAST_DAY(TO_DATE(TO_CHAR(vrsv_date, 'YYYYMM')+100,'YYYYMM')), :NEW.p_price*vaccum, :NEW.o_code);
        ELSIF :NEW.p_method = '������' THEN 
            INSERT INTO reserves(rsv_code, c_code, rsv_date, rsv_memo, rsv_end, rsv_price, o_code)
            VALUES (rsv_code_seq.nextval, vc_code, vrsv_date, '���', NULL, :NEW.p_price*(-1), :NEW.o_code);
        ELSIF :NEW.p_method = '����' THEN
            UPDATE my_coupon
            SET mcou_check = 1
            WHERE mcou_id = :NEW.p_card_number;            
        END IF;
    ELSIF DELETING THEN
        IF :OLD.p_method IN ('�ſ�ī��', '�������', '�޴���', 'īī�� ����')  THEN
            DELETE FROM reserves
            WHERE o_code = :OLD.o_code AND rsv_memo = '����';
        ELSIF :OLD.p_method = '������' THEN
            DELETE FROM reserves
            WHERE o_code = :OLD.o_code AND rsv_memo = '���';
        ELSIF :OLD.p_method = '����' THEN
            UPDATE my_coupon
            SET mcou_check = 0
            WHERE mcou_id = :OLD.p_card_number;
        END IF;
    END IF;
END;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- Ʈ���� : [������] ������ ���� [ȸ������] ���� ����Ʈ ����
CREATE OR REPLACE TRIGGER mk_t_tot_reserves AFTER
INSERT OR DELETE ON reserves
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE customer 
        SET c_tot_reserves = c_tot_reserves + :NEW.rsv_price
        WHERE c_code = :NEW.c_code;
    ELSIF DELETING THEN
        UPDATE customer 
        SET c_tot_reserves = c_tot_reserves - :OLD.rsv_price
        WHERE c_code = :OLD.c_code;  
    END IF;
END;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--[����] �μ�Ʈ ���ν���
CREATE OR REPLACE PROCEDURE mk_p_payment_insert
(
    pc_code customer.c_code%TYPE, 
    p_use_reserves NUMBER,
    pmcou_id my_coupon.mcou_id%TYPE,
    po_pay_method mk_order.o_pay_method%TYPE,
    p_shipping_pay NUMBER,
    po_payprice OUT NUMBER
)
IS
    vo_price mk_order.o_price%TYPE;
    vo_payprice NUMBER := 0; --����Ʈ �������� ���� �����ݾ�
    vo_coupon_dis coupon.cou_discount%TYPE := 0; 
    vo_coupon_rate coupon.cou_d_rate%TYPE := 0;
    vc_tot_reserves customer.c_tot_reserves%TYPE;
BEGIN
    vo_price := mk_f_total_price(pc_code);
    
    IF pmcou_id IS NOT NULL THEN

        SELECT cou_d_rate INTO vo_coupon_rate
        FROM coupon c JOIN my_coupon m 
        ON c.cou_id = m.cou_id 
        WHERE mcou_id = pmcou_id;
       -- �� �ֹ��ǿ� ����� ������ ������


        SELECT c.cou_discount INTO vo_coupon_dis
        FROM coupon c JOIN my_coupon m 
        ON c.cou_id = m.cou_id 
        WHERE mcou_id = pmcou_id;
        -- �� �ֹ��� ����� ������ ���� �ݾ�

    END IF;
    
    -- �ֹ��Ϸ��� ���� �ܿ� ����Ʈ
    SELECT c_tot_reserves INTO vc_tot_reserves 
    FROM customer
    WHERE c_code = pc_code;
    
    
    vo_payprice := (
        vo_price * (1 - vo_coupon_rate) - vo_coupon_dis - p_use_reserves
    );


    -- ���� ���̺� �μ�Ʈ ���� �κ�
    INSERT INTO payment
    (
        p_code,
        o_code,
        p_method,
        p_price,
        p_card_number
    )
    VALUES
    (
        pay_code_seq.nextval,
        o_code_seq.currval,
        po_pay_method,
        vo_payprice + p_shipping_pay,
        TRUNC(dbms_random.value(1000,10000))||'-'||TRUNC(dbms_random.value(1000,10000))||
        '-'||TRUNC(dbms_random.value(1000,10000))||'-'||TRUNC(dbms_random.value(1000,10000)) -- ���ǰ�
    );

    IF p_use_reserves != 0 THEN -- ������ ���� �������̺� �μ�Ʈ
        INSERT INTO payment
        (
            p_code,
            o_code,
            p_method,
            p_price,
            p_card_number
        )
        VALUES
        (
            pay_code_seq.nextval,
            o_code_seq.currval,
            '������',
            p_use_reserves,
            null
        );
    END IF;

    IF pmcou_id IS NOT NULL THEN -- ���� ���� ���� ���̺� �μ�Ʈ
        INSERT INTO payment
        (
            p_code,
            o_code,
            p_method,
            p_price,
            p_card_number
        )
        VALUES
        (
            pay_code_seq.nextval,
            o_code_seq.currval,
            '����',
            vo_coupon_dis + vo_price * vo_coupon_rate,
            pmcou_id
        );
    END IF;
    
    po_payprice := vo_payprice;
END;
