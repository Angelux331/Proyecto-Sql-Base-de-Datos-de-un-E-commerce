/*
Por motivos de seguridad y cumplimiento, la empresa necesita un registro detallado de cualquier cambio realizado en la información sensible de los clientes, como el email o la direccion_envio.

Tarea: Implementa un trigger llamado trg_audit_cliente_after_update que se dispare después de que se actualice un registro en la tabla Clientes.



Primero, crea una tabla de auditoría llamada Auditoria_Clientes con campos como id_auditoria, id_cliente, campo_modificado, valor_antiguo, valor_nuevo y fecha_modificacion.
El trigger debe activarse solo si el valor del campo email o direccion_envio ha cambiado.
Cuando se dispare, el trigger debe insertar un nuevo registro en la tabla Auditoria_Clientes, almacenando el valor antiguo y el nuevo del campo que fue modificado.


Resultado esperado

Un repositorio privado en github.
Un único script .sql que incluya el CREATE TABLE para Auditoria_Clientes y el CREATE TRIGGER para trg_audit_cliente_after_update.
Comentarios que expliquen la lógica.

*/
USE E_commerce;

-- Tabla que almacena el historial de modificaciones realizadas a los clientes
CREATE TABLE IF NOT EXISTS Auditoria_Clientes (
    id_auditoria INT PRIMARY KEY AUTO_INCREMENT NOT NULL,
    id_cliente INT NOT NULL,
    campo_modificado VARCHAR(255) NOT NULL DEFAULT 'email',
    valor_antiguo VARCHAR(255),
    valor_nuevo VARCHAR(255) NOT NULL,
    fecha_modificacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP()
);

-- Trigger que se ejecuta después de actualizar un cliente
CREATE TRIGGER trg_audit_cliente_after_update
AFTER UPDATE ON Clientes
FOR EACH ROW
BEGIN

    -- Compara el correo anterior con el nuevo.
    -- Si hubo un cambio, guarda el registro en la tabla de auditoría.
    IF OLD.email <> NEW.email THEN
        INSERT INTO Auditoria_Clientes
            (id_cliente, campo_modificado, valor_antiguo, valor_nuevo)
        VALUES
            (NEW.id_cliente, 'EMAIL', OLD.email, NEW.email);
    END IF;

    -- Compara la dirección de envío anterior con la nueva.
    -- Si hubo un cambio, registra la modificación en la auditoría.
    IF OLD.direccion_envio <> NEW.direccion_envio THEN
        INSERT INTO Auditoria_Clientes
            (id_cliente, campo_modificado, valor_antiguo, valor_nuevo)
        VALUES
            (NEW.id_cliente, 'DIRECCION DE ENVIO',
             OLD.direccion_envio, NEW.direccion_envio);
    END IF;

END;