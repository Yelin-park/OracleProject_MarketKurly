-- >�ֹ��ϱ�<

-- 1. [ȸ�� �ֹ� ����]�� ��ü���� �ֹ��� ���� ������ INSERT
    -- 1-1. [ȸ�� �ֹ� ����]�� ���� [ȸ�� ����] ���� �ֹ� �� UPDATE

-- 2. [�ֹ� �� ����]�� ��ǰ �� ���� ������ INSERT
    -- 2-1. [�ֹ� �� ����]�� ���� [���] ���� UPDATE  
    -- 2-2. [�ֹ� �� ����]�� ���� [��ǰ] �����Ǹż� UPDATE

-- 3. [����]�� ī��, ������, ���� ���� ���� INSERT
    -- 3-1. ī��(�������, īī������, �޴��� ����) ī������ݾ� * ����������� [������] ���� INSERT
        -- 3-1-1. ���� ������ ����, [ȸ������] ���� ������ UPDATE
    -- 3-2. ������ ��� ��, [������] ���  INSERT
        -- 3-2-1. ���� ��뿡 ����, [ȸ������] ���� ������ UPDATE
    -- 3-3. ���� ��� ��, [��������] ���ó�� UPDATE

-- 4. �ֹ� ���� ��, [��ٱ���]�� �ش� ȸ�� ���� DELETE
        

-- >�ֹ��ϱ�< �μ�Ʈ �� ������ ���� �߻� �ó�����
-- 1) ��ٱ��� ��� �׸��� �����ϴ�
-- 2) �������� �����մϴ�
-- 3) �ش� ������ ���� �����Դϴ�
-- 4) ǰ���� ��ǰ�� ���Ե� �ֹ��Դϴ�
-- 5) ...

-- >�ֹ� ���<
-- '���� �Ϸ�' �ܰ迡���� ����
-- '��� �غ� ��' ���� �ܰ迡�� �Ұ���
-- �ֹ��ϱ� ���� �� 4�� �����ϰ� �ݴ�� ����
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
-- {MAIN} �ֹ��ϴ� ���ν���
CREATE OR REPLACE PROCEDURE mk_p_order
(
        pc_code customer.c_code%TYPE, -- ȸ�� ����
        ps_code shipping.s_code%TYPE, -- ����� ����
        po_rspot mk_order.o_rspot%TYPE, -- ������ ���
        po_lobbypw mk_order.o_lobbypw%TYPE, -- ���� ���
        po_message mk_order.o_message%TYPE, -- �޼��� �߼�
        p_use_reserves customer.c_tot_reserves%TYPE, -- ������ ���
        pmcou_id my_coupon.mcou_id%TYPE, -- �������
        po_pay_method mk_order.o_pay_method%TYPE  --���� ����
)
IS
    v_curr_time DATE := SYSDATE;
    vo_price mk_order.o_price%TYPE := mk_f_total_price(pc_code); -- �� �ֹ��ǿ� ��ü �ֹ��ݾ�
    vo_payprice NUMBER := 0;
    v_reserves_check customer.c_tot_reserves%TYPE;
    v_coupon_check my_coupon.mcou_check%TYPE;
    v_shipping_pay NUMBER := 0;
    vcursor SYS_REFCURSOR; 
    ex_reserves EXCEPTION;
    ex_coupon EXCEPTION;
    ex_inventory EXCEPTION;
BEGIN
    -- �� ���ν����ȿ��� 4���� ���ν����� ���� > 9���� ���̺��� ������
    -- 4���� Ʈ���Ű� ����ǹǷ�, ���߿� ���ܹ߻��ϸ� �Ϻθ� �ѹ� ��
    -- ����Ǵ� ��� ���ܸ� ���� ���� �˻� ��, 
    -- ���� �߻� ������ �̸� �߻� ���Ѿ� ��
--    SELECT c_tot_reserves INTO v_reserves_check FROM customer WHERE c_code = pc_code;
--    SELECT mcou_check INTO v_coupon_check FROM my_coupon WHERE mcou_id = pmcou_id ;
--    IF p_use_reserves > v_reserves_check THEN
--        RAISE ex_reserves;
--    ELSIF v_coupon_check != 0 THEN
--        RAISE ex_coupon;
----    ELSIF true THEN
----        RAISE ex_inventory;
--    END IF;
    
    -- {��ۺ�} ���
    v_shipping_pay := mk_f_shipping_pay(pc_code, vo_price);
    
    -- [ȸ���ֹ�����] INSERT�ϴ� ���ν���
    mk_p_order_insert(pc_code, v_curr_time, vo_price, ps_code, po_rspot, po_lobbypw, po_message, po_pay_method, v_shipping_pay);

    -- [�ֹ��󼼳���] ISNERT�ϴ� ���ν���
    OPEN vcursor FOR SELECT p_code, cart_count FROM CART WHERE c_code = pc_code AND cart_select = 1;
    mk_p_dorder_insert(vcursor);
    CLOSE vcursor;

    -- [����] INSERT�ϴ� ���ν���
    mk_p_payment_insert(pc_code, p_use_reserves, pmcou_id, po_pay_method, v_shipping_pay, vo_payprice);

    -- [��ٱ���] DELETE�ϴ� ���ν���
    mk_p_cart_del(pc_code);

    COMMIT;
EXCEPTION
--    WHEN ex_reserves THEN
--        ROLLBACK;
--        RAISE_APPLICATION_ERROR(-20001, '>�������� �����մϴ�.<');
--    WHEN ex_coupon THEN
--        ROLLBACK;
--        RAISE_APPLICATION_ERROR(-20001, '>��� �Ұ��� �����Դϴ�.<');
----    WHEN ex_inventory THEN
----        ROLLBACK;
----        RAISE_APPLICATION_ERROR(-20001, '>ǰ���� ��ǰ�� ���ԵǾ��ֽ��ϴ�.<');
--    WHEN NO_DATA_FOUND THEN
--        ROLLBACK;
--        RAISE_APPLICATION_ERROR(-20001, '>��ٱ��ϰ� ����ֽ��ϴ�.<');        
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, '>�ֹ��� �Ұ��մϴ�.<');
END;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- �ֹ� ����ϴ� ���ν���
CREATE OR REPLACE PROCEDURE mk_p_order_cancle
(
    po_code mk_order.o_code%TYPE
)
IS
    vo_dstate mk_order.o_dstate%TYPE;
    ex_cancle_impos EXCEPTION;
    
BEGIN

    SELECT o_dstate INTO vo_dstate FROM mk_order WHERE o_code = po_code;
    IF vo_dstate != '���� �Ϸ�' THEN
        RAISE ex_cancle_impos;
    END IF;

    DELETE FROM mk_dorder
    WHERE o_code = po_code;
    
    DELETE FROM payment
    WHERE o_code = po_code;
    
    DELETE FROM reserves
    WHERE o_code = po_code AND rsv_memo = '����';
    
    DELETE FROM mk_order
    WHERE o_code = po_code;
    
EXCEPTION
    WHEN ex_cancle_impos THEN
        RAISE_APPLICATION_ERROR(-20001, '>��� �غ� �� ���Ŀ��� ��Ұ� �Ұ��մϴ�<');

END;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--[�׽�Ʈ]

-- >�ֹ��ϱ�<
BEGIN
mk_p_order(
        1, --ȸ��
        1, --�����
        '�� ��', -- ������ ���
        '1234*', -- �������
        1, --�޼���
        1000, -- ����Ʈ ���
        null, --��������
        '�ſ�ī��'   -- �������� 
);
END;

-- >�ֹ����<
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