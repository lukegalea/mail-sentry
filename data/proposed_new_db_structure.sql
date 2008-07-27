-- MySQL dump 10.10
--
-- Host: localhost    Database: mailsentry_dev
-- ------------------------------------------------------
-- Server version	5.0.27

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
CREATE TABLE `clients` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES (1,'Toronto Rehab');
/*!40000 ALTER TABLE `clients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `data_maps`
--

DROP TABLE IF EXISTS `data_maps`;
CREATE TABLE `data_maps` (
  `entity_id` int(11) unsigned NOT NULL,
  `field_id` int(11) unsigned NOT NULL,
  `value_id` int(15) unsigned NOT NULL,
  PRIMARY KEY  (`entity_id`,`field_id`,`value_id`),
  KEY `field_id` (`field_id`),
  KEY `value_id` (`value_id`),
  KEY `entity_id` (`entity_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `data_maps`
--

LOCK TABLES `data_maps` WRITE;
/*!40000 ALTER TABLE `data_maps` DISABLE KEYS */;
/*!40000 ALTER TABLE `data_maps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `entities`
--

DROP TABLE IF EXISTS `entities`;
CREATE TABLE `entities` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=20 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `entities`
--

LOCK TABLES `entities` WRITE;
/*!40000 ALTER TABLE `entities` DISABLE KEYS */;
/*!40000 ALTER TABLE `entities` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fields`
--

DROP TABLE IF EXISTS `fields`;
CREATE TABLE `fields` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `model_id` int(11) unsigned NOT NULL,
  `type_id` int(11) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `model_id` (`model_id`),
  KEY `type_id` (`type_id`),
  KEY `name` (`name`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `fields`
--

LOCK TABLES `fields` WRITE;
/*!40000 ALTER TABLE `fields` DISABLE KEYS */;
INSERT INTO `fields` VALUES (1,'mrn',1,1),(2,'lastname',1,1),(3,'firstname',1,1),(4,'healthcard',1,1);
/*!40000 ALTER TABLE `fields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `fulltext_values`
--

DROP TABLE IF EXISTS `fulltext_values`;
CREATE TABLE `fulltext_values` (
  `id` int(15) unsigned NOT NULL auto_increment,
  `value` varchar(1000) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `value` (`value`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Dumping data for table `fulltext_values`
--

LOCK TABLES `fulltext_values` WRITE;
/*!40000 ALTER TABLE `fulltext_values` DISABLE KEYS */;
/*!40000 ALTER TABLE `fulltext_values` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `models`
--

DROP TABLE IF EXISTS `models`;
CREATE TABLE `models` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  `client_id` int(11) unsigned NOT NULL,
  PRIMARY KEY  (`id`),
  KEY `client_id` (`client_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `models`
--

LOCK TABLES `models` WRITE;
/*!40000 ALTER TABLE `models` DISABLE KEYS */;
INSERT INTO `models` VALUES (1,'Patient',1);
/*!40000 ALTER TABLE `models` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `types`
--

DROP TABLE IF EXISTS `types`;
CREATE TABLE `types` (
  `id` int(11) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `types`
--

LOCK TABLES `types` WRITE;
/*!40000 ALTER TABLE `types` DISABLE KEYS */;
INSERT INTO `types` VALUES (1,'Text');
/*!40000 ALTER TABLE `types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `values`
--

DROP TABLE IF EXISTS `values`;
CREATE TABLE `values` (
  `id` int(15) unsigned NOT NULL auto_increment,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `value` (`value`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;

--
-- Dumping data for table `values`
--

LOCK TABLES `values` WRITE;
/*!40000 ALTER TABLE `values` DISABLE KEYS */;
/*!40000 ALTER TABLE `values` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'mailsentry_dev'
--
DELIMITER ;;
/*!50003 DROP PROCEDURE IF EXISTS `clean_values` */;;
/*!50003 SET SESSION SQL_MODE=""*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `clean_values`()
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
		DROP TEMPORARY TABLE IF EXISTS OrphanedValues;
		CREATE TEMPORARY TABLE OrphanedValues (
        	id INT(11) UNSIGNED NOT NULL PRIMARY KEY
        ) ENGINE=MEMORY;
                
        INSERT INTO OrphanedValues SELECT `values`.id FROM `values`
				LEFT JOIN data_maps ON data_maps.value_id = `values`.id
				WHERE value_id IS NULL;
				
		DELETE FROM `values` WHERE id IN ( SELECT id FROM OrphanedValues );
END */;;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE*/;;
/*!50003 DROP PROCEDURE IF EXISTS `clear_client` */;;
/*!50003 SET SESSION SQL_MODE=""*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `clear_client`(
    IN delete_client_id INT(11) UNSIGNED
)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
	
	DELETE FROM entities, data_maps 
		USING entities, data_maps, fields, models, clients
		WHERE data_maps.entity_id = entities.id AND
			  fields.id = data_maps.field_id AND
		      models.id = fields.model_id AND
			  clients.id = models.client_id AND
			  clients.id = delete_client_id;
END */;;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE*/;;
/*!50003 DROP PROCEDURE IF EXISTS `load_value` */;;
/*!50003 SET SESSION SQL_MODE=""*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `load_value`(
    IN value VARCHAR(255),
    IN field VARCHAR(255),
    IN entity VARCHAR(255),
    IN entity_id INT(11) UNSIGNED,
    IN model VARCHAR(255),
    IN client VARCHAR(255)
)
    MODIFIES SQL DATA
    SQL SECURITY INVOKER
BEGIN
    DECLARE field_id INT(11) UNSIGNED;
    DECLARE entity_id_out INT(11) UNSIGNED;
    DECLARE datamap_id INT(11) UNSIGNED;
    DECLARE value_id INT(15) UNSIGNED;
    
    SELECT fields.id INTO field_id FROM fields
        JOIN models ON models.id = fields.model_id
        JOIN clients on models.client_id = clients.id
        WHERE models.name = model AND clients.name = client AND fields.name = field;
    
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
    
    SELECT `values`.`id` INTO value_id FROM `values` WHERE `values`.`value` = value;
    IF value_id IS NULL THEN
        INSERT INTO `values` ( `value` ) VALUES ( value );
        SELECT @@IDENTITY INTO value_id;
    END IF;
    IF value_id IS NULL THEN
        CALL raise_error( 'Unable to locate or create value');
    END IF;
    
    SELECT data_maps.entity_id INTO datamap_id FROM data_maps
            WHERE data_maps.entity_id = entity_id_out AND data_maps.value_id = value_id AND data_maps.field_id = field_id;
    IF datamap_id is NULL THEN
        INSERT INTO data_maps ( entity_id, field_id, value_id ) VALUES ( entity_id_out, field_id, value_id );
        SELECT @@IDENTITY INTO datamap_id;
    END IF;
    IF datamap_id IS NULL THEN
        CALL raise_error( 'Unable to locate or create datamap');
    END IF;
    
    select entity_id_out;
END */;;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE*/;;
/*!50003 DROP PROCEDURE IF EXISTS `raise_error` */;;
/*!50003 SET SESSION SQL_MODE=""*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `raise_error`(msg VARCHAR(62))
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
END */;;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE*/;;
/*!50003 DROP PROCEDURE IF EXISTS `split_string` */;;
/*!50003 SET SESSION SQL_MODE=""*/;;
/*!50003 CREATE*/ /*!50020 DEFINER=`root`@`localhost`*/ /*!50003 PROCEDURE `split_string`(
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
END */;;
/*!50003 SET SESSION SQL_MODE=@OLD_SQL_MODE*/;;
DELIMITER ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2007-04-13 21:52:24
