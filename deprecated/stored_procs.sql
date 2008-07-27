DELIMITER $

DROP PROCEDURE IF EXISTS split_string$
DROP PROCEDURE IF EXISTS load_value$
DROP PROCEDURE IF EXISTS load_value_ex$
DROP PROCEDURE IF EXISTS priv_load_value_and_map$
DROP PROCEDURE IF EXISTS raise_error$
DROP PROCEDURE IF EXISTS clear_client$
DROP PROCEDURE IF EXISTS clean_values$

CREATE PROCEDURE split_string (
     IN input TEXT,
     IN delimiter VARCHAR(10)
  )
      SQL SECURITY INVOKER
      BEGIN
      DECLARE cur_position INT DEFAULT 1 ;
      DECLARE remainder TEXT;
      DECLARE cur_string VARCHAR(1000);
      DECLARE delimiter_length TINYINT UNSIGNED;
      DROP TEMPORARY TABLE IF EXISTS SplitValues;
      CREATE TEMPORARY TABLE SplitValues (
        value VARCHAR(1000) NOT NULL PRIMARY KEY
        ) ENGINE=MEMORY;
      SET remainder = input;
      SET delimiter_length = CHAR_LENGTH(delimiter);

       WHILE CHAR_LENGTH(remainder) > 0 AND cur_position > 0 DO
        SET cur_position = INSTR(remainder, delimiter);

      IF cur_position = 0 THEN
        SET cur_string = remainder;
     ELSE
        SET cur_string = LEFT(remainder, cur_position - 1);
        END IF;

      IF TRIM(cur_string) != '' THEN
        INSERT INTO SplitValues VALUES (cur_string);
     END IF;

      SET remainder = SUBSTRING(remainder, cur_position +
delimiter_length);

      END WHILE;

      SELECT * FROM SplitValues;
END$

CREATE PROCEDURE raise_error(msg VARCHAR(62))
	SQL SECURITY INVOKER
    BEGIN
    DECLARE Tmsg VARCHAR(80);
    SET Tmsg = msg;
    IF (CHAR_LENGTH(TRIM(Tmsg)) = 0 OR Tmsg IS NULL) THEN
    SET Tmsg = 'ERROR GENERADO';
    END IF;
    SET Tmsg = CONCAT('@@MyError', Tmsg, '@@MyError');
    SET @MyError = CONCAT('INSERT INTO', Tmsg);
    PREPARE stmt FROM @MyError;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END$

CREATE PROCEDURE clear_client (
    IN delete_client_id INT(11) UNSIGNED
)
	NOT DETERMINISTIC
	SQL SECURITY INVOKER
	MODIFIES SQL DATA 
	BEGIN
	
	DELETE FROM entities, data_maps 
		USING entities, data_maps, fields, models, clients
		WHERE data_maps.entity_id = entities.id AND
			  fields.id = data_maps.field_id AND
		      models.id = fields.model_id AND
			  clients.id = models.client_id AND
			  clients.id = delete_client_id;
END$

CREATE PROCEDURE clean_values()
	NOT DETERMINISTIC
	SQL SECURITY INVOKER
	MODIFIES SQL DATA 
	BEGIN
		DROP TEMPORARY TABLE IF EXISTS OrphanedValues;
		CREATE TEMPORARY TABLE OrphanedValues (
        	id INT(11) UNSIGNED NOT NULL PRIMARY KEY
        ) ENGINE=MEMORY;
                
        INSERT INTO OrphanedValues SELECT `values`.id FROM `values`
				LEFT JOIN data_maps ON data_maps.value_id = `values`.id
				WHERE value_id IS NULL;
				
		DELETE FROM `values` WHERE id IN ( SELECT id FROM OrphanedValues );
END$

CREATE PROCEDURE load_value_ex (
    IN fulltext_value VARCHAR(1000),
    IN field VARCHAR(255),
    IN entity VARCHAR(255),
    IN entity_id INT(11) UNSIGNED,
    IN model VARCHAR(255),
    IN client VARCHAR(255)
)
	NOT DETERMINISTIC
	SQL SECURITY INVOKER
	MODIFIES SQL DATA 
    BEGIN

    DECLARE field_id INT(11) UNSIGNED;
    DECLARE entity_id_out INT(11) UNSIGNED;
    DECLARE datamap_id INT(11) UNSIGNED;
    DECLARE fulltext_value_id INT(15) UNSIGNED;

    /* Locate field */
    SELECT fields.id INTO field_id FROM fields
        JOIN models ON models.id = fields.model_id
        JOIN clients on models.client_id = clients.id
        WHERE models.name = model AND clients.name = client AND fields.name = field;

    /* Locate or create entity and store created id */
    IF entity_id IS NOT NULL THEN
        SELECT entities.id INTO entity_id_out FROM entities
            WHERE entities.name = entity AND entities.id = entity_id;
    END IF;

    IF entity_id_out IS NULL THEN
        INSERT INTO entities ( name ) VALUES( entity );
        SELECT @@IDENTITY INTO entity_id_out;
    END IF;

    IF entity_id_out IS NULL THEN
        CALL raise_error( 'Unable to locate or create entity');
    END IF;
    
    /* Locate or create fulltext_value */
    SELECT `fulltext_values`.`id` INTO fulltext_value_id FROM `fulltext_values` WHERE `fulltext_values`.`fulltext_value` = fulltext_value;

    IF fulltext_value_id IS NULL THEN
        INSERT INTO `fulltext_values` ( `fulltext_value` ) VALUES ( fulltext_value );
        SELECT @@IDENTITY INTO fulltext_value_id;
    END IF;

    IF fulltext_value_id IS NULL THEN
        CALL raise_error( 'Unable to locate or create fulltext value');
    END IF;

    /* Locate or create all the tokens in the fulltext_value and create a data_map entry for each */
    CALL priv_split_fulltext_value_and_load( fulltext_value, field_id, entity_id_out, fulltext_value_id );

    /* Return new entity */
    select entity_id_out;
END$

CREATE PROCEDURE priv_load_value_and_map (
	IN value VARCHAR(255),
	IN field_id INT(11) UNSIGNED,
    IN entity_id INT(11) UNSIGNED,
    IN fulltext_value_id INT(15) UNSIGNED
)
	NOT DETERMINISTIC
	SQL SECURITY INVOKER
	MODIFIES SQL DATA 
    BEGIN
    
    DECLARE datamap_id INT(11) UNSIGNED;
    DECLARE value_id INT(15) UNSIGNED;
    
    /* Locate or create value */
    SELECT `values`.`id` INTO value_id FROM `values` WHERE `values`.`value` = value;

    IF value_id IS NULL THEN
        INSERT INTO `values` ( `value` ) VALUES ( value );
        SELECT @@IDENTITY INTO value_id;
    END IF;

    IF value_id IS NULL THEN
        CALL raise_error( 'Unable to locate or create value');
    END IF;

    /* locate or create data_map */
    SELECT data_maps.entity_id INTO datamap_id FROM data_maps
            WHERE data_maps.entity_id = entity_id_out AND data_maps.value_id = value_id AND data_maps.field_id = field_id AND data_maps.fulltext_value_id = fulltext_value_id;

    IF datamap_id is NULL THEN
        INSERT INTO data_maps ( entity_id, field_id, value_id, fulltext_value_id ) VALUES ( entity_id_out, field_id, value_id, fulltext_value_id );
        SELECT @@IDENTITY INTO datamap_id;
    END IF;

    IF datamap_id IS NULL THEN
        CALL raise_error( 'Unable to locate or create datamap');
    END IF;
END$

CREATE PROCEDURE priv_split_fulltext_value_and_load (
	IN fulltext_value VARCHAR(1000),
	IN field_id INT(11) UNSIGNED,
    IN entity_id INT(11) UNSIGNED,
    IN fulltext_value_id INT(15) UNSIGNED
)
	NOT DETERMINISTIC
	SQL SECURITY INVOKER
	MODIFIES SQL DATA 
    BEGIN
    
    DECLARE done INT DEFAULT 0;
    DECLARE val VARCHAR(255);
    DECLARE cur1 CURSOR FOR SELECT * FROM ( CALL split_string ( fulltext_value, '~' ) );
    DECLARE CONTINUE HANDLER FOR SQLSTATE '02000' SET done = 1;
    
    OPEN cur1;
    
    REPEAT
    	FETCH cur1 INTO val;
    	IF NOT done THEN
    		CALL priv_load_value_and_map ( val, field_id, entity_id, fulltext_value_id );
    	END IF;
    UNTIL done END REPEAT;
    	
    CLOSE cur1;
END$


CREATE PROCEDURE load_value (
    IN value VARCHAR(255),
    IN field VARCHAR(255),
    IN entity VARCHAR(255),
    IN entity_id INT(11) UNSIGNED,
    IN model VARCHAR(255),
    IN client VARCHAR(255)
)
	NOT DETERMINISTIC
	SQL SECURITY INVOKER
	MODIFIES SQL DATA 
    BEGIN

    DECLARE field_id INT(11) UNSIGNED;
    DECLARE entity_id_out INT(11) UNSIGNED;
    DECLARE datamap_id INT(11) UNSIGNED;
    DECLARE value_id INT(15) UNSIGNED;

    /* Locate field */
    SELECT fields.id INTO field_id FROM fields
        JOIN models ON models.id = fields.model_id
        JOIN clients on models.client_id = clients.id
        WHERE models.name = model AND clients.name = client AND fields.name = field;

    /* Locate or create entity and store created id */
    IF entity_id IS NOT NULL THEN
        SELECT entities.id INTO entity_id_out FROM entities
            WHERE entities.name = entity AND entities.id = entity_id;
    END IF;

    IF entity_id_out IS NULL THEN
        INSERT INTO entities ( name ) VALUES( entity );
        SELECT @@IDENTITY INTO entity_id_out;
    END IF;

    IF entity_id_out IS NULL THEN
        CALL raise_error( 'Unable to locate or create entity');
    END IF;

    /* Locate or create value */
    SELECT `values`.`id` INTO value_id FROM `values` WHERE `values`.`value` = value;

    IF value_id IS NULL THEN
        INSERT INTO `values` ( `value` ) VALUES ( value );
        SELECT @@IDENTITY INTO value_id;
    END IF;

    IF value_id IS NULL THEN
        CALL raise_error( 'Unable to locate or create value');
    END IF;

    /* locate or create data_map */
    SELECT data_maps.entity_id INTO datamap_id FROM data_maps
            WHERE data_maps.entity_id = entity_id_out AND data_maps.value_id = value_id AND data_maps.field_id = field_id;

    IF datamap_id is NULL THEN
        INSERT INTO data_maps ( entity_id, field_id, value_id ) VALUES ( entity_id_out, field_id, value_id );
        SELECT @@IDENTITY INTO datamap_id;
    END IF;

    IF datamap_id IS NULL THEN
        CALL raise_error( 'Unable to locate or create datamap');
    END IF;

    /* Return new entity */
    select entity_id_out;
END$

DELIMITER ;
