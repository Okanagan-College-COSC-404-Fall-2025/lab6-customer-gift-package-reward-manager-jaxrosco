CREATE OR REPLACE PACKAGE CUSTOMER_MANAGER IS
    FUNCTION get_total_purchase(p_customer_id IN NUMBER) RETURN NUMBER;
    PROCEDURE assign_gifts_to_all;
    PROCEDURE show_rewards_for_first_five;
    END CUSTOMER_MANAGER;
/

CREATE OR REPLACE PACKAGE BODY CUSTOMER_MANAGER IS
    FUNCTION get_total_purchase(p_customer_id IN NUMBER) RETURN NUMBER IS
        v_total NUMBER := 0;
    BEGIN
        SELECT NVL(SUM(oi.unit_price * oi.quantity), 0) INTO v_total
        FROM orders o
        JOIN order_items oi ON o.order_id = oi.order_id
        WHERE o.customer_id = p_customer_id
        AND UPPER(o.order_status) = 'COMPLETE';
        RETURN v_total;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN RETURN 0;
    END get_total_purchase;

    FUNCTION choose_gift_package(p_total_purchase IN NUMBER) RETURN NUMBER IS
        v_gift_id gift_catalog.gift_id%TYPE;
        v_id1   gift_catalog.gift_id%TYPE := NULL;
        v_min1  gift_catalog.min_purchase%TYPE := NULL;
        v_id2   gift_catalog.gift_id%TYPE := NULL;
        v_min2  gift_catalog.min_purchase%TYPE := NULL;
        v_id3   gift_catalog.gift_id%TYPE := NULL;
        v_min3  gift_catalog.min_purchase%TYPE := NULL;
    BEGIN
        FOR r IN (
            SELECT gift_id, min_purchase
            FROM gift_catalog
            ORDER BY min_purchase DESC
        ) LOOP
        IF v_id1 IS NULL THEN
            v_id1 := r.gift_id; v_min1 := r.min_purchase;
        ELSIF v_id2 IS NULL THEN
            v_id2 := r.gift_id; v_min2 := r.min_purchase;
        ELSIF v_id3 IS NULL THEN
            v_id3 := r.gift_id; v_min3 := r.min_purchase;
            EXIT;
        END IF;
    END LOOP;

    v_gift_id := CASE
        WHEN v_min1 IS NOT NULL AND p_total_purchase >= v_min1 THEN v_id1
        WHEN v_min2 IS NOT NULL AND p_total_purchase >= v_min2 THEN v_id2
        WHEN v_min3 IS NOT NULL AND p_total_purchase >= v_min3 THEN v_id3
        ELSE NULL
    END;

    RETURN v_gift_id;
    EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
    END choose_gift_package;

    PROCEDURE assign_gifts_to_all IS
        v_total NUMBER;
        v_gift  NUMBER;
    BEGIN
        FOR c IN (SELECT customer_id, email_address FROM customers) LOOP
        v_total := get_total_purchase(c.customer_id);
        v_gift  := choose_gift_package(v_total);
        IF v_gift IS NOT NULL THEN
            MERGE INTO customer_rewards cr
            USING (SELECT c.email_address AS email, v_gift AS gid FROM DUAL) src
            ON (cr.customer_email = src.email AND cr.gift_id = src.gid AND TRUNC(cr.reward_date) = TRUNC(SYSDATE))
        WHEN NOT MATCHED THEN
            INSERT (reward_id, customer_email, gift_id, reward_date)
            VALUES (DEFAULT, src.email, src.gid, SYSDATE);
        END IF;
    END LOOP;
    COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
    END assign_gifts_to_all;

    PROCEDURE show_rewards_for_first_five IS
        BEGIN
    FOR rec IN (
        SELECT * FROM (
        SELECT cr.reward_id, cr.customer_email, g.gift_id,
            LISTAGG(gi.COLUMN_VALUE, ', ') WITHIN GROUP (ORDER BY gi.COLUMN_VALUE) AS gift_items
        FROM customer_rewards cr
        JOIN gift_catalog g ON cr.gift_id = g.gift_id,
           TABLE(g.gifts) gi
        GROUP BY cr.reward_id, cr.customer_email, g.gift_id
        ORDER BY cr.reward_id
        ) WHERE ROWNUM <= 5
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Reward '||rec.reward_id||': '||rec.customer_email||' -> Gift '||rec.gift_id||' ['||rec.gift_items||']');
    END LOOP;
    END show_rewards_for_first_five;
END CUSTOMER_MANAGER;
/

COMMIT;