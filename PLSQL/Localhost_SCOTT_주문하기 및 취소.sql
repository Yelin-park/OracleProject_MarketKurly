-- >주문하기<

-- 1. [회원 주문 내역]에 전체적인 주문에 대한 데이터 INSERT
    -- 1-1. [회원 주문 내역]에 따른 [회원 정보] 누적 주문 수 UPDATE

-- 2. [주문 상세 내역]에 제품 및 수량 데이터 INSERT
    -- 2-1. [주문 상세 내역]에 따라 [재고] 수량 UPDATE  
    -- 2-2. [주문 상세 내역]에 따라 [상품] 누적판매수 UPDATE

-- 3. [결제]에 카드, 적립금, 쿠폰 결제 내역 INSERT
    -- 3-1. 카드(간편결제, 카카오페이, 휴대폰 포함) 카드결제금액 * 고객등급적립률 [적립금] 적립 INSERT
        -- 3-1-1. 적립 내역에 따라, [회원정보] 누적 적립금 UPDATE
    -- 3-2. 적립금 사용 시, [적립금] 사용  INSERT
        -- 3-2-1. 적립 사용에 따라, [회원정보] 누적 적립금 UPDATE
    -- 3-3. 쿠폰 사용 시, [마이쿠폰] 사용처리 UPDATE

-- 4. 주문 성공 시, [장바구니]에 해당 회원 내역 DELETE
        

-- >주문하기< 인서트 문 이전에 오류 발생 시나리오
-- 1) 장바구니 담긴 항목이 없습니다
-- 2) 적립금이 부족합니다
-- 3) 해당 쿠폰은 없는 쿠폰입니다
-- 4) 품절된 상품이 포함된 주문입니다
-- 5) ...

-- >주문 취소<
-- '결제 완료' 단계에서만 가능
-- '배송 준비 중' 이후 단계에선 불가능
-- 주문하기 과정 중 4번 제외하고 반대로 실행
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- {MAIN} 주문하는 프로시저
CREATE OR REPLACE PROCEDURE mk_p_order
(
        pc_code customer.c_code%TYPE, -- 회원 정보
        ps_code shipping.s_code%TYPE, -- 배송지 정보
        po_rspot mk_order.o_rspot%TYPE, -- 받으실 장소
        po_lobbypw mk_order.o_lobbypw%TYPE, -- 현관 비번
        po_message mk_order.o_message%TYPE, -- 메세지 발송
        p_use_reserves customer.c_tot_reserves%TYPE, -- 적립금 사용
        pmcou_id my_coupon.mcou_id%TYPE, -- 쿠폰사용
        po_pay_method mk_order.o_pay_method%TYPE  --결제 수단
)
IS
    v_curr_time DATE := SYSDATE;
    vo_price mk_order.o_price%TYPE := mk_f_total_price(pc_code); -- 이 주문건에 전체 주문금액
    vo_payprice NUMBER := 0;
    v_reserves_check customer.c_tot_reserves%TYPE;
    v_coupon_check my_coupon.mcou_check%TYPE;
    v_shipping_pay NUMBER := 0;
    vcursor SYS_REFCURSOR; 
    ex_reserves EXCEPTION;
    ex_coupon EXCEPTION;
    ex_inventory EXCEPTION;
BEGIN
    -- 이 프로시저안에서 4개의 프로시저가 실행 > 9개의 테이블이 수정됨
    -- 4개의 트리거가 실행되므로, 도중에 예외발생하면 일부만 롤백 됨
    -- 예상되는 모든 예외를 제일 먼저 검사 후, 
    -- 예외 발생 조건은 미리 발생 시켜야 함
--    SELECT c_tot_reserves INTO v_reserves_check FROM customer WHERE c_code = pc_code;
--    SELECT mcou_check INTO v_coupon_check FROM my_coupon WHERE mcou_id = pmcou_id ;
--    IF p_use_reserves > v_reserves_check THEN
--        RAISE ex_reserves;
--    ELSIF v_coupon_check != 0 THEN
--        RAISE ex_coupon;
----    ELSIF true THEN
----        RAISE ex_inventory;
--    END IF;
    
    -- {배송비} 계산
    v_shipping_pay := mk_f_shipping_pay(pc_code, vo_price);
    
    -- [회원주문내역] INSERT하는 프로시저
    mk_p_order_insert(pc_code, v_curr_time, vo_price, ps_code, po_rspot, po_lobbypw, po_message, po_pay_method, v_shipping_pay);

    -- [주문상세내역] ISNERT하는 프로시저
    OPEN vcursor FOR SELECT p_code, cart_count FROM CART WHERE c_code = pc_code AND cart_select = 1;
    mk_p_dorder_insert(vcursor);
    CLOSE vcursor;

    -- [결제] INSERT하는 프로시저
    mk_p_payment_insert(pc_code, p_use_reserves, pmcou_id, po_pay_method, v_shipping_pay, vo_payprice);

    -- [장바구니] DELETE하는 프로시저
    mk_p_cart_del(pc_code);

    COMMIT;
EXCEPTION
--    WHEN ex_reserves THEN
--        ROLLBACK;
--        RAISE_APPLICATION_ERROR(-20001, '>적립금이 부족합니다.<');
--    WHEN ex_coupon THEN
--        ROLLBACK;
--        RAISE_APPLICATION_ERROR(-20001, '>사용 불가한 쿠폰입니다.<');
----    WHEN ex_inventory THEN
----        ROLLBACK;
----        RAISE_APPLICATION_ERROR(-20001, '>품절된 상품이 포함되어있습니다.<');
--    WHEN NO_DATA_FOUND THEN
--        ROLLBACK;
--        RAISE_APPLICATION_ERROR(-20001, '>장바구니가 비어있습니다.<');        
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, '>주문이 불가합니다.<');
END;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- 주문 취소하는 프로시저
CREATE OR REPLACE PROCEDURE mk_p_order_cancle
(
    po_code mk_order.o_code%TYPE
)
IS
    vo_dstate mk_order.o_dstate%TYPE;
    ex_cancle_impos EXCEPTION;
    
BEGIN

    SELECT o_dstate INTO vo_dstate FROM mk_order WHERE o_code = po_code;
    IF vo_dstate != '결제 완료' THEN
        RAISE ex_cancle_impos;
    END IF;

    DELETE FROM mk_dorder
    WHERE o_code = po_code;
    
    DELETE FROM payment
    WHERE o_code = po_code;
    
    DELETE FROM reserves
    WHERE o_code = po_code AND rsv_memo = '적립';
    
    DELETE FROM mk_order
    WHERE o_code = po_code;
    
EXCEPTION
    WHEN ex_cancle_impos THEN
        RAISE_APPLICATION_ERROR(-20001, '>배송 준비 중 이후에는 취소가 불가합니다<');

END;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--[테스트]

-- >주문하기<
BEGIN
mk_p_order(
        1, --회원
        1, --배송지
        '문 앞', -- 받으실 장소
        '1234*', -- 현관비번
        1, --메세지
        1000, -- 포인트 사용
        null, --마이쿠폰
        '신용카드'   -- 결제수단 
);
END;

-- >주문취소<
BEGIN
    mk_p_order_cancle(66);
END;
EXEC mk_p_order_click(60);
SELECT * FROM cart;
SELECT * FROM product;
SELECT * FROM customer;
SELECT * FROM mk_order;
SELECT * FROM mk_dorder;
SELECT * FROM payment;
SELECT * FROM reserves;
SELECT * FROM my_coupon;
SELECT * FROM inventory;



SELECT * 
FROM SYS.user_triggers
WHERE table_name = 'PAYMENT';