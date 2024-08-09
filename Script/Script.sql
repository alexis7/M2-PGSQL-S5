-- 1. Crea una nueva cuenta bancaria para un cliente, asignando un número de cuenta único y estableciendo un saldo inicial.

CREATE OR REPLACE FUNCTION crear_cuenta_bancaria(
    p_cliente_id INT,
    p_tipo_cuenta VARCHAR,
    p_saldo_inicial NUMERIC,
	p_empleado_id INT
) RETURNS VOID AS $$
DECLARE
    v_numero_cuenta INT;
BEGIN
	v_numero_cuenta := FLOOR(RANDOM() * 100 + 1)::INT;
    INSERT INTO Cuentas_Bancarias (cliente_id, numero_cuenta, tipo_cuenta, saldo, fecha_apertura, estado, empleado_id)
    VALUES (p_cliente_id, v_numero_cuenta, p_tipo_cuenta, p_saldo_inicial, CURRENT_DATE, 'activa', p_empleado_id);
END;
$$ LANGUAGE plpgsql;


Select crear_cuenta_bancaria(1,'ahorro', 100, 9);


-- 2. Actualiza la información personal de un cliente, como dirección, teléfono y correo electrónico, basado en el ID del cliente.

CREATE OR REPLACE FUNCTION actualizar_informacion_cliente(
    p_cliente_id INT,
    p_direccion VARCHAR,
    p_telefono VARCHAR,
    p_correo_electronico VARCHAR
) RETURNS VOID AS $$
BEGIN
    UPDATE Clientes
    SET direccion = p_direccion,
        telefono = p_telefono,
        correo_electronico = p_correo_electronico
    WHERE cliente_id = p_cliente_id;
END;
$$ LANGUAGE plpgsql;

select actualizar_informacion_cliente(2,'carrera test', '123456789', 'test@gmail.com');



-- 3. Elimina una cuenta bancaria específica del sistema, incluyendo la eliminación de todas las transacciones asociadas.

CREATE OR REPLACE FUNCTION eliminar_cuenta_bancaria(
    p_cuenta_id INT
) RETURNS VOID AS $$
BEGIN
    DELETE FROM Transacciones WHERE cuenta_id = p_cuenta_id;
    DELETE FROM Cuentas_Bancarias WHERE cuenta_id = p_cuenta_id;
END;
$$ LANGUAGE plpgsql;


select eliminar_cuenta_bancaria(23);


CREATE OR REPLACE FUNCTION transferir_fondos(
    p_cuenta_origen INT,
    p_cuenta_destino INT,
    p_monto NUMERIC
) RETURNS VOID AS $$
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
END;
$$ LANGUAGE plpgsql;


select transferir_fondos(17,18,50000);


-- 5. Registra una nueva transacción (depósito, retiro) en el sistema, actualizando el saldo de la cuenta asociada.

CREATE OR REPLACE FUNCTION registrar_transaccion(
    p_cuenta_id INT,
    p_tipo_transaccion VARCHAR,
    p_monto NUMERIC,
    p_descripcion VARCHAR
) RETURNS VOID AS $$
BEGIN
    -- Actualizar el saldo de la cuenta asociada
    IF p_tipo_transaccion = 'deposito' THEN
        UPDATE Cuentas_Bancarias
        SET saldo = saldo + p_monto
        WHERE cuenta_id = p_cuenta_id;
    ELSIF p_tipo_transaccion = 'retiro' THEN
        UPDATE Cuentas_Bancarias
        SET saldo = saldo - p_monto
        WHERE cuenta_id = p_cuenta_id;
    END IF;
    
    -- Registrar la transacción
    INSERT INTO Transacciones (cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion)
    VALUES (p_cuenta_id, p_tipo_transaccion, p_monto, CURRENT_DATE, p_descripcion);
END;
$$ LANGUAGE plpgsql;

select registrar_transaccion(19,'deposito', 100, 'deposito de 100');
select registrar_transaccion(19,'retiro', 50, 'retiro de 50');


-- 6. Calcula el saldo total combinado de todas las cuentas bancarias pertenecientes a un cliente específico.

CREATE OR REPLACE FUNCTION saldo_total_cliente(
    p_cliente_id INT
) RETURNS NUMERIC AS $$
DECLARE
    v_saldo_total NUMERIC;
BEGIN
    SELECT SUM(saldo) INTO v_saldo_total
    FROM Cuentas_Bancarias
    WHERE cliente_id = p_cliente_id;
    
    RETURN v_saldo_total;
END;
$$ LANGUAGE plpgsql;

select saldo_total_cliente(1);


-- 7. Genera un reporte detallado de todas las transacciones realizadas en un rango de fechas específico.

CREATE OR REPLACE FUNCTION reporte_transacciones(
    p_fecha_inicio TIMESTAMP,
    p_fecha_fin TIMESTAMP
) RETURNS TABLE (
    transaccion_id_r INT,
    cuenta_id_r INT,
    tipo_transaccion_r VARCHAR,
    monto_r NUMERIC,
    fecha_transaccion_r TIMESTAMP,
    descripcion_r VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT transaccion_id, cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion
    FROM transacciones
    WHERE fecha_transaccion BETWEEN p_fecha_inicio AND p_fecha_fin;
END;
$$ LANGUAGE plpgsql;

select reporte_transacciones('2024-07-24 00:00:00', '2024-09-01 00:00:00');