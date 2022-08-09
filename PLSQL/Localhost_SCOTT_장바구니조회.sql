--특정 회원의 [장바구니] 조회하는 프로시저
CREATE OR REPLACE PROCEDURE mk_p_cart_view
(
    p_c_code customer.c_code%TYPE
)
IS
    ROW_cart cart%ROWTYPE;
    ROW_product product%ROWTYPE;
    ROW_cold_type cold_type%ROWTYPE;
    ROW_shipping shipping%ROWTYPE;
    v_delivery_type delivery.delivery_type%TYPE;
    v_count_a NUMBER := 0;
    v_count_b NUMBER := 0;
    v_check_box VARCHAR2(2);
    v_tot_price NUMBER := 0;
    v_tot_discount NUMBER := 0;
    v_sum_price NUMBER := 0;
    v_reserves_usable NUMBER := 0;
    v_mcou_id my_coupon.mcou_id%TYPE;
    v_cou_name coupon.cou_name%TYPE;
    v_cou_function coupon.cou_function%TYPE;
    
    CURSOR cart_list_cursor IS(
        SELECT cart_select, p.p_name, p.p_price, c.cart_count, c.cart_price, t.cold_type_name, p.p_discount
        FROM cart c 
            JOIN product p ON c.p_code = p.p_code
            JOIN cold_type t ON p.p_cold_type = t.p_cold_type
        WHERE c.c_code = p_c_code);
    CURSOR shipping_list_cursor IS(
        SELECT s_code, s_address, delivery_type
        FROM shipping s JOIN delivery d ON s.delivery = d.delivery
        WHERE c_code = p_c_code);
    CURSOR my_coupon_cursor IS(
        SELECT mcou_id, cou_name, cou_function
        FROM my_coupon m 
            JOIN coupon c ON m.cou_id = c.cou_id
        WHERE c_code = p_c_code
        AND mcou_check = 0);
BEGIN
    
    DBMS_OUTPUT.PUT_LINE('[장바구니]');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    SELECT COUNT(*) INTO v_count_a FROM cart WHERE c_code = p_c_code AND cart_select = 1;
    SELECT COUNT(*) INTO v_count_b FROM cart WHERE c_code = p_c_code;
    DBMS_OUTPUT.PUT_LINE(v_count_b || '개 중 ' || v_count_a || '개 선택');
    OPEN cart_list_cursor ;
    LOOP
        FETCH cart_list_cursor 
        INTO ROW_cart.cart_select, ROW_product.p_name, ROW_product.p_price, ROW_cart.cart_count, ROW_cart.cart_price, ROW_cold_type.cold_type_name, ROW_product.p_discount;
        EXIT WHEN cart_list_cursor%NOTFOUND;
        IF ROW_cart.cart_select = 1 THEN v_check_box := 'v';
        ELSIF ROW_cart.cart_select = 0 THEN v_check_box := ' ';
        END IF;
        DBMS_OUTPUT.PUT_LINE('['||v_check_box||']    '|| ROW_product.p_name || '    '|| ROW_cart.cart_count || '개     ' || ROW_cart.cart_price || '원    ' ||ROW_cold_type.cold_type_name);
        v_tot_price := v_tot_price + ROW_product.p_price * ROW_cart.cart_count * ROW_cart.cart_select;
        v_tot_discount := v_tot_discount + ROW_product.p_price * ROW_cart.cart_count * ROW_cart.cart_select * ROW_product.p_discount ;
        
    END LOOP;
    CLOSE cart_list_cursor;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('[배송지 목록]');
    OPEN shipping_list_cursor;
    LOOP
        FETCH shipping_list_cursor INTO ROW_shipping.s_code, ROW_shipping.s_address, v_delivery_type;
        EXIT WHEN shipping_list_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('['||ROW_shipping.s_code||']'|| ROW_shipping.s_address);
        DBMS_OUTPUT.PUT_LINE('(배송유형 : '|| v_delivery_type|| ')');
    END LOOP;
    CLOSE shipping_list_cursor;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('[주문 금액]');
    DBMS_OUTPUT.PUT_LINE('상품금액 : ' || v_tot_price || '원');
    DBMS_OUTPUT.PUT_LINE('상품할인 : ' || v_tot_discount || '원');

    DBMS_OUTPUT.PUT_LINE('배송비 : ' ||mk_f_shipping_pay(p_c_code, v_tot_price) || '원');
    DBMS_OUTPUT.PUT_LINE('>결제금액 : ' || (v_tot_price - v_tot_discount + mk_f_shipping_pay(p_c_code, v_tot_price)) || '원' );

    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('[사용 가능 적립금]');
    SELECT c_tot_reserves INTO v_reserves_usable FROM customer WHERE c_code = p_c_code;
    
    DBMS_OUTPUT.PUT_LINE('> '||v_reserves_usable|| '원');
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('[사용 가능 쿠폰]');
    OPEN my_coupon_cursor;
    LOOP
        FETCH my_coupon_cursor INTO v_mcou_id, v_cou_name, v_cou_function;
        EXIT WHEN my_coupon_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('['||v_mcou_id||']'||v_cou_name||' / '|| v_cou_function);
    END LOOP;
    CLOSE my_coupon_cursor;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
END;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--[테스트]
EXEC mk_p_cart_view(1);
