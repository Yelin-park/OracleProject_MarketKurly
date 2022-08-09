-- [�ֹ� �� ����]
-- 2. [�ֹ� �� ����]�� ��ǰ �� ���� ������ INSERT
    -- 2-1. [�ֹ� �� ����]�� ���� [���] ���� UPDATE  
    -- 2-2. [�ֹ� �� ����]�� ���� [��ǰ] �����Ǹż� UPDATE

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- �ֹ���ȣ ������
CREATE SEQUENCE od_code_seq
INCREMENT BY 1
START WITH 11
NOMAXVALUE
MINVALUE 1
NOCYCLE;

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- Ʈ���� : ���� -> [��ǰ] �����Ǹ� , [���] ����
CREATE OR REPLACE TRIGGER mk_t_tot_sales AFTER
INSERT OR DELETE ON mk_dorder
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        UPDATE product 
        SET total_sales = total_sales + :NEW.od_count 
        WHERE p_code = :NEW.p_code;
        UPDATE inventory
        SET i_count = i_count - :NEW.od_count
        WHERE p_code = :NEW.p_code AND db_center_code = :NEW.db_center_code;
    ELSIF DELETING THEN
        UPDATE product 
        SET total_sales = total_sales - :OLD.od_count
        WHERE p_code = :OLD.p_code;
        UPDATE inventory
        SET i_count = i_count + :OLD.od_count
        WHERE p_code = :OLD.p_code AND db_center_code = :OLD.db_center_code;
    END IF;
END;


---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
--[�ֹ��󼼳���] �μ�Ʈ�ϴ� ���ν���
CREATE OR REPLACE PROCEDURE mk_p_dorder_insert
(
    pcursor SYS_REFCURSOR
)
IS
    vp_code cart.p_code%TYPE;
    vcart_count cart.cart_count%TYPE;
BEGIN
    LOOP
        FETCH pcursor INTO vp_code, vcart_count;
        EXIT WHEN pcursor%NOTFOUND;

        INSERT INTO mk_dorder
        (od_code, p_code, o_code, od_count, od_price, db_center_code)
        VALUES
        (
            od_code_seq.nextval,
            vp_code,
            o_code_seq.currval,
            vcart_count,
            (SELECT p_price*(1-p_discount) FROM product WHERE p_code = vp_code),
            1 -- ���� ��
        );
    END LOOP;
END;

