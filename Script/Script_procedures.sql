-- 1. Crea una nueva cuenta bancaria para un cliente, asignando un número de cuenta único y estableciendo un saldo inicial.


CREATE OR REPLACE procedure crear_cuenta_bancaria(
    p_cliente_id INT,
    p_tipo_cuenta VARCHAR,
    p_saldo_inicial NUMERIC,
	p_empleado_id INT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_numero_cuenta INT;
BEGIN
	v_numero_cuenta := FLOOR(RANDOM() * 100 + 1)::INT;
    INSERT INTO Cuentas_Bancarias (cliente_id, numero_cuenta, tipo_cuenta, saldo, fecha_apertura, estado, empleado_id)
    VALUES (p_cliente_id, v_numero_cuenta, p_tipo_cuenta, p_saldo_inicial, CURRENT_DATE, 'activa', p_empleado_id);
    RAISE NOTICE 'Cuenta creada con éxito';
END;
$$;

CALL crear_cuenta_bancaria(1,'ahorro', 100, 9);


-- 2. Actualiza la información personal de un cliente, como dirección, teléfono y correo electrónico, basado en el ID del cliente.

CREATE OR REPLACE procedure actualizar_informacion_cliente(
    p_cliente_id INT,
    p_direccion VARCHAR,
    p_telefono VARCHAR,
    p_correo_electronico VARCHAR
) 
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Clientes
    SET direccion = p_direccion,
        telefono = p_telefono,
        correo_electronico = p_correo_electronico
    WHERE cliente_id = p_cliente_id;
        RAISE NOTICE 'Datos actualizados con éxito';
END;
$$;

CALL actualizar_informacion_cliente(2,'carrera test', '123456789', 'test@gmail.com');



-- 3. Elimina una cuenta bancaria específica del sistema, incluyendo la eliminación de todas las transacciones asociadas.

CREATE OR REPLACE procedure eliminar_cuenta_bancaria(
    p_cuenta_id INT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM Transacciones WHERE cuenta_id = p_cuenta_id;
    DELETE FROM Cuentas_Bancarias WHERE cuenta_id = p_cuenta_id;
        RAISE NOTICE 'Cuenta y transacciones eliminadas con éxito';
END;
$$;


Call eliminar_cuenta_bancaria(23);


-- 4. Realiza una transferencia de fondos desde una cuenta a otra, asegurando que ambas cuentas se actualicen correctamente y se registre la transacción.


CREATE OR REPLACE procedure transferir_fondos(
    p_cuenta_origen INT,
    p_cuenta_destino INT,
    p_monto NUMERIC
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Restar el monto de la cuenta de origen
    UPDATE Cuentas_Bancarias
    SET saldo = saldo - p_monto
    WHERE cuenta_id = p_cuenta_origen;
    
    -- Sumar el monto a la cuenta de destino
    UPDATE Cuentas_Bancarias
    SET saldo = saldo + p_monto
    WHERE cuenta_id = p_cuenta_destino;
    
    -- Registrar cuenta de origen
    INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
    VALUES (p_cuenta_origen, 'transferencia', -p_monto, CURRENT_DATE, 'transferencia a cuenta ' || p_cuenta_destino);
    
    -- Registrar transacción cuenta de destino
    INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
    VALUES (p_cuenta_destino, 'transferencia', p_monto, CURRENT_DATE, 'transferencia desde cuenta ' || p_cuenta_origen);
    RAISE NOTICE 'Transferencia de fondos éxitosa';
END;
$$;


Call transferir_fondos(17,18,50000);


-- 5. Registra una nueva transacción (depósito, retiro) en el sistema, actualizando el saldo de la cuenta asociada.

CREATE OR REPLACE procedure registrar_transaccion(
    p_cuenta_id INT,
    p_tipo_transaccion VARCHAR,
    p_monto NUMERIC,
    p_descripcion VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Actualizar el saldo de la cuenta asociada
    IF p_tipo_transaccion = 'deposito' THEN
        UPDATE Cuentas_Bancarias
        SET saldo = saldo + p_monto
        WHERE cuenta_id = p_cuenta_id;
        RAISE NOTICE 'Transacción de deposito éxitosa';
    ELSIF p_tipo_transaccion = 'retiro' THEN
        UPDATE Cuentas_Bancarias
        SET saldo = saldo - p_monto
        WHERE cuenta_id = p_cuenta_id;
        RAISE NOTICE 'Transacción de retiro éxitosa';
    END IF;
    
    -- Registrar la transacción
    INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
    VALUES (p_cuenta_id, p_tipo_transaccion, p_monto, CURRENT_DATE, p_descripcion);
END;
$$;

Call registrar_transaccion(19,'deposito', 100, 'deposito de 100');
Call registrar_transaccion(19,'retiro', 50, 'retiro de 50');


-- 6. Calcula el saldo total combinado de todas las cuentas bancarias pertenecientes a un cliente específico.

CREATE OR REPLACE procedure saldo_total_cliente(
    p_cliente_id INT,
	OUT v_saldo_total NUMERIC
) 
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT SUM(saldo) INTO v_saldo_total
    FROM Cuentas_Bancarias
    WHERE cliente_id = p_cliente_id;
	RAISE NOTICE 'Saldo total del cliente', p_cliente_id ;
END;
$$;

Call saldo_total_cliente(1,0);



-- 7. Genera un reporte detallado de todas las transacciones realizadas en un rango de fechas específico.

CREATE OR REPLACE PROCEDURE reporte_transacciones(
    IN p_fecha_inicio TIMESTAMP,
    IN p_fecha_fin TIMESTAMP,
    OUT transaccion_id_r INT,
    OUT cuenta_id_r INT,
    OUT tipo_transaccion_r VARCHAR,
    OUT monto_r NUMERIC,
    OUT fecha_transaccion_r TIMESTAMP,
    OUT descripcion_r VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    FOR transaccion_id_r, cuenta_id_r, tipo_transaccion_r, monto_r, fecha_transaccion_r, descripcion_r
    IN 
    SELECT 
        transaccion_id, cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion
    FROM 
        transacciones
    WHERE 
        fecha_transaccion BETWEEN p_fecha_inicio AND p_fecha_fin
    LOOP
        RAISE NOTICE 'Transacción: %, Cuenta: %, Tipo: %, Monto: %, Fecha: %, Descripción: %',
            transaccion_id_r, cuenta_id_r, tipo_transaccion_r, monto_r, fecha_transaccion_r, descripcion_r;
    END LOOP;
END;
$$;


DO $$
DECLARE
    trans_id INT;
    cuenta_id INT;
    tipo_trans VARCHAR;
    monto NUMERIC;
    fecha TIMESTAMP;
    descripcion VARCHAR;
BEGIN
    CALL reporte_transacciones('2023-01-01 00:00:00', '2024-12-31 23:59:59', trans_id, cuenta_id, tipo_trans, monto, fecha, descripcion);
END $$;