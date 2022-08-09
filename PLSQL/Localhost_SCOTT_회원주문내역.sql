--[회원 주문 내역]
-- 1. [회원 주문 내역]에 전체적인 주문에 대한 데이터 INSERT
    -- 1-1. [회원 주문 내역]에 따른 [회원 정보] 누적 주문 수 UPDATE

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 주문번호 시퀀스
CREATE SEQUENCE o_code_seq
INCREMENT BY 1
START WITH 5
NOMAXVALUE
MINVALUE 1
NOCYCLE;

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 트리거 : 구매 -> [회원정보] 누적 주문
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
-- [장바구니] 전체 금액 계산하는 함수
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
-- [배송비] 전체 금액 계산하는 함수
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
--[회원주문내역] 인서트하는 프로시저
create or replace PROCEDURE mk_p_order_insert
(
    pc_code customer.c_code%TYPE, -- 회원정보
    p_curr_time mk_order.o_date%TYPE, -- 주문시간
    po_price mk_order.o_price%TYPE, -- 전체 주문금액
    ps_code shipping.s_code%TYPE, -- 배송지정보
    po_rspot mk_order.o_rspot%TYPE, -- 받으실 장소
    po_lobbypw mk_order.o_lobbypw%TYPE, -- 현관비번
    po_message mk_order.o_message%TYPE, -- 메세지발송
    po_pay_method mk_order.o_pay_method%TYPE, --결제 수단
    p_shipping_pay NUMBER := 0
)
IS
    
BEGIN
    INSERT INTO mk_order
    (o_code, c_code, o_date, o_price, s_code, o_dstate, o_rspot, o_lobbypw,  o_message, o_pay_method, o_shipping_pay)
    VALUES
    (o_code_seq.nextval, pc_code, p_curr_time, po_price, ps_code, '결제 완료', po_rspot, po_lobbypw, po_message, po_pay_method, p_shipping_pay);
END;

