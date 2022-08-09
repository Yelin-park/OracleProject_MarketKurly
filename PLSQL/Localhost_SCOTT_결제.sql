-- [결제] / [적립금] / [마이쿠폰]
-- 3. [결제]에 카드, 적립금, 쿠폰 결제 내역 INSERT
    -- 3-1. 카드(간편결제, 카카오페이, 휴대폰 포함) 카드결제금액 * 고객등급적립률 [적립금] 적립 INSERT
        -- 3-1-1. 적립 내역에 따라, [회원정보] 누적 적립금 UPDATE
    -- 3-2. 적립금 사용 시, [적립금] 사용  INSERT
        -- 3-2-1. 적립 사용에 따라, [회원정보] 누적 적립금 UPDATE
    -- 3-3. 쿠폰 사용 시, [마이쿠폰] 사용처리 UPDATE

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 결제내역 시퀀스
CREATE SEQUENCE pay_code_seq
INCREMENT BY 1
START WITH 1
NOMAXVALUE
MINVALUE 1
NOCYCLE;

-- 적립금 시퀀스
CREATE SEQUENCE rsv_code_seq
INCREMENT BY 1
START WITH 1
NOMAXVALUE
MINVALUE 1
NOCYCLE;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 트리거 : [결제] 내역에 대한 [적립금] 적립/사용 [쿠폰] 사용 처리
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
        
        IF :NEW.p_method IN ('신용카드', '간편결제', '휴대폰', '카카오 페이') THEN
            INSERT INTO reserves(rsv_code, c_code, rsv_date, rsv_memo, rsv_end, rsv_price, o_code)
            VALUES (rsv_code_seq.nextval, vc_code, vrsv_date, '적립', LAST_DAY(TO_DATE(TO_CHAR(vrsv_date, 'YYYYMM')+100,'YYYYMM')), :NEW.p_price*vaccum, :NEW.o_code);
        ELSIF :NEW.p_method = '적립금' THEN 
            INSERT INTO reserves(rsv_code, c_code, rsv_date, rsv_memo, rsv_end, rsv_price, o_code)
            VALUES (rsv_code_seq.nextval, vc_code, vrsv_date, '사용', NULL, :NEW.p_price*(-1), :NEW.o_code);
        ELSIF :NEW.p_method = '쿠폰' THEN
            UPDATE my_coupon
            SET mcou_check = 1
            WHERE mcou_id = :NEW.p_card_number;            
        END IF;
    ELSIF DELETING THEN
        IF :OLD.p_method IN ('신용카드', '간편결제', '휴대폰', '카카오 페이')  THEN
            DELETE FROM reserves
            WHERE o_code = :OLD.o_code AND rsv_memo = '적립';
        ELSIF :OLD.p_method = '적립금' THEN
            DELETE FROM reserves
            WHERE o_code = :OLD.o_code AND rsv_memo = '사용';
        ELSIF :OLD.p_method = '쿠폰' THEN
            UPDATE my_coupon
            SET mcou_check = 0
            WHERE mcou_id = :OLD.p_card_number;
        END IF;
    END IF;
END;
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- 트리거 : [적립금] 내역에 따른 [회원정보] 누적 포인트 변경
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
--[결제] 인서트 프로시저
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
    vo_payprice NUMBER := 0; --포인트 쿠폰뺴고 실제 결제금액
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
       -- 이 주문건에 적용된 쿠폰의 할인율


        SELECT c.cou_discount INTO vo_coupon_dis
        FROM coupon c JOIN my_coupon m 
        ON c.cou_id = m.cou_id 
        WHERE mcou_id = pmcou_id;
        -- 이 주문에 적용된 쿠폰의 할인 금액

    END IF;
    
    -- 주문하려는 고객의 잔여 포인트
    SELECT c_tot_reserves INTO vc_tot_reserves 
    FROM customer
    WHERE c_code = pc_code;
    
    
    vo_payprice := (
        vo_price * (1 - vo_coupon_rate) - vo_coupon_dis - p_use_reserves
    );


    -- 결제 테이블 인서트 시작 부분
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
        '-'||TRUNC(dbms_random.value(1000,10000))||'-'||TRUNC(dbms_random.value(1000,10000)) -- 임의값
    );

    IF p_use_reserves != 0 THEN -- 적립금 사용시 결제테이블 인서트
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
            '적립금',
            p_use_reserves,
            null
        );
    END IF;

    IF pmcou_id IS NOT NULL THEN -- 쿠폰 사용시 결제 테이블 인서트
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
            '쿠폰',
            vo_coupon_dis + vo_price * vo_coupon_rate,
            pmcou_id
        );
    END IF;
    
    po_payprice := vo_payprice;
END;
