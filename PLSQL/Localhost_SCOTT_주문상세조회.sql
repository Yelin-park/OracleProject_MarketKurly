CREATE OR REPLACE PROCEDURE mk_p_order_click
(
    p_o_code mk_order.o_code%TYPE
)
IS
    v_method_check payment.p_method%TYPE;
    v_reserves_check NUMBER(1);
    v_coupon_check NUMBER(1);
    a NUMBER :=0;
    b NUMBER :=0;
    c NUMBER :=0;
    d NUMBER :=0;
    e NUMBER :=0;
    f NUMBER :=0;
    g NUMBER :=0;
    h payment.p_method%TYPE;
    v_s_a shipping.recipient%TYPE;
    v_s_b shipping.telnumber%TYPE;
    v_s_c delivery.delivery_type%TYPE;
    v_s_d shipping.s_address%TYPE;
    v_s_e mk_order.o_rspot%TYPE;
    v_s_f mk_order.o_lobbypw%TYPE;
    
    row_dorder mk_dorder%ROWTYPE;
    v_p_name product.p_name%TYPE;
    v_p_price product.p_price%TYPE;
    v_discount product.p_discount%TYPE;
    v_s_code shipping.s_code%TYPE;
    
    CURSOR dorder_cursor IS (
        SELECT p.p_name, d.od_count , d.od_price
        FROM mk_dorder d JOIN product p
        ON d.p_code = p.p_code
        WHERE o_code = p_o_code);
    CURSOR dorder_cursor_2 IS (
        SELECT d.od_count , p.p_price, p.p_discount
        FROM mk_dorder d JOIN product p
        ON d.p_code = p.p_code
        WHERE o_code = p_o_code);
BEGIN
    DBMS_OUTPUT.PUT_LINE('[주문 내역 상세]');
    DBMS_OUTPUT.PUT_LINE('주문번호 : '|| p_o_code);
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    OPEN dorder_cursor;
    LOOP
        FETCH dorder_cursor INTO v_p_name, row_dorder.od_count, row_dorder.od_price;
        EXIT WHEN dorder_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(v_p_name);
            DBMS_OUTPUT.PUT_LINE('          '||row_dorder.od_price||' 원 | '||row_dorder.od_count || '개' );
        END LOOP;
    CLOSE dorder_cursor;
    
 
    SELECT NVL(SUM(p_price * od_count),0) INTO a
    FROM mk_dorder d JOIN product p ON d.p_code = p.p_code
    WHERE d.o_code = p_o_code;
        
    SELECT p_method, NVL(p_price,0) INTO h, f
    FROM payment
    WHERE o_code = p_o_code
    AND p_method IN ('신용카드', '간편결제', '휴대폰', '카카오 페이');
    
    SELECT COUNT(p_method) INTO v_reserves_check FROM payment WHERE o_code = p_o_code AND p_method = '적립금'; 
    IF v_reserves_check != 0 THEN
        SELECT NVL(p_price,0) INTO e
        FROM payment
        WHERE o_code = p_o_code
        AND p_method = '적립금'; 
    END IF;
    
    SELECT COUNT(p_method) INTO v_coupon_check FROM payment WHERE o_code = p_o_code AND p_method = '쿠폰'; 
    IF v_coupon_check != 0 THEN
        SELECT NVL(p_price,0) INTO d
        FROM payment
        WHERE o_code = p_o_code
        AND p_method = '쿠폰';         
    END IF;

    OPEN dorder_cursor_2;
    LOOP
        FETCH dorder_cursor_2 INTO row_dorder.od_count, v_p_price, v_discount;
        EXIT WHEN dorder_cursor_2%NOTFOUND;
            c := c + row_dorder.od_count * v_p_price * v_discount;
        END LOOP;
    CLOSE dorder_cursor_2;
    
    SELECT rsv_price INTO g
    FROM RESERVES
    WHERE o_code = p_o_code
    AND rsv_memo = '적립';
    
    SELECT o_shipping_pay INTO b
    FROM mk_order
    WHERE o_code = p_o_code;
    
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('- 결제 정보');
    DBMS_OUTPUT.PUT_LINE('    상품금액 : '||a||'원');
    DBMS_OUTPUT.PUT_LINE('    배송비 : '||b||'원');
    DBMS_OUTPUT.PUT_LINE('    상품할인금액 : '||c*(-1)||'원');
    DBMS_OUTPUT.PUT_LINE('    쿠폰할인 : '||d*(-1)||'원');
    DBMS_OUTPUT.PUT_LINE('    적립금사용 : '||e*(-1)||'원');
    DBMS_OUTPUT.PUT_LINE('    결제금액 : '||f||'원');
    DBMS_OUTPUT.PUT_LINE('    적립예정금액 : '||g||'원');
    DBMS_OUTPUT.PUT_LINE('    결제방법 : '||h);
    

    SELECT s_code INTO v_s_code
    FROM mk_order
    WHERE o_code = p_o_code;
    
    SELECT
        s.recipient, telnumber, d.delivery_type, s_address, o_rspot, o_lobbypw
    INTO
        v_s_a, v_s_b, v_s_c, v_s_d, v_s_e, v_s_f
    FROM shipping s
        JOIN mk_order o ON s.s_code = o.s_code
        JOIN sign_up u ON o.c_code = u.c_code
        JOIN delivery d ON d.delivery = s.delivery
    WHERE o_code = p_o_code;

    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('----------------------------------');
    DBMS_OUTPUT.PUT_LINE('- 배송 정보');
    DBMS_OUTPUT.PUT_LINE('    받는 분 : '||v_s_a);
    DBMS_OUTPUT.PUT_LINE('    핸드폰 : '||v_s_b);
    DBMS_OUTPUT.PUT_LINE('    배송방법 : '||v_s_c);
    DBMS_OUTPUT.PUT_LINE('    주소 : '||v_s_d);
    DBMS_OUTPUT.PUT_LINE('    받으실 장소 : '||v_s_e);    
    DBMS_OUTPUT.PUT_LINE('    현관 비밀번호 : '||v_s_f);    


END;


EXEC mk_p_order_click(70);