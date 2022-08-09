-- [주문 상세 내역]
-- 2. [주문 상세 내역]에 제품 및 수량 데이터 INSERT
    -- 2-1. [주문 상세 내역]에 따라 [재고] 수량 UPDATE  
    -- 2-2. [주문 상세 내역]에 따라 [상품] 누적판매수 UPDATE

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 주문번호 시퀀스
CREATE SEQUENCE od_code_seq
INCREMENT BY 1
START WITH 11
NOMAXVALUE
MINVALUE 1
NOCYCLE;

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 트리거 : 구매 -> [상품] 누적판매 , [재고] 수량
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
--[주문상세내역] 인서트하는 프로시저
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
            1 -- 임의 값
        );
    END LOOP;
END;

