-- Identifying Adverse Drug Events (ADEs) with Stored Programs

use ade;

-- A stored procedure to process and validate prescriptions
-- Four things we need to check
-- a) Is patient a child and is medication suitable for children?
-- b) Is patient pregnant and is medication suitable for pregnant women?
-- c) Are there any adverse drug reactions

drop procedure if exists prescribe;

delimiter //
create procedure prescribe
(
    in patient_name_param varchar(255),
    in doctor_name_param varchar(255),
    in medication_name_param varchar(255),
    in ppd_param int -- pills per day prescribed
)
begin
		-- variable declarations
    declare patient_id_var int;
    declare age_var float;
    declare is_pregnant_var boolean;
    declare weight_var int;
    declare doctor_id_var int;
    declare medication_id_var int;
    declare take_under_12_var boolean;
    declare take_if_pregnant_var boolean;
    declare mg_per_pill_var double;
    declare max_mg_per_10kg_var double;

    declare message varchar(255); -- The error message
    declare ddi_medication varchar(255); -- The name of a medication involved in a drug-drug interaction

    -- select relevant values into variables
	SELECT patient_id, age, is_pregnant
    INTO patient_id_var, age_var, is_pregnant_var
    FROM patient
    WHERE patient_name = patient_name_param;
    
    -- check age of patient
	IF age_var < 12 AND NOT take_under_12_var THEN
        SET message = CONCAT(medication_name_param, ' cannot be prescribed to children under 12.');
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = message;
    END IF;

    -- check if medication ok for pregnant women
	IF is_pregnant_var AND NOT take_if_pregnant_var THEN
        SET message = CONCAT(medication_name_param, ' cannot be prescribed to pregnant women.');
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = message;
    END IF;

    -- Check for reactions involving medications already prescribed to patient
	SELECT m.medication_name
    INTO ddi_medication
    FROM prescription p
    JOIN medication m ON p.medication_id = m.medication_id
    WHERE p.patient_id = patient_id_var
        AND m.medication_name = medication_name_param
        AND m.interacts_with IS NOT NULL;

    IF ddi_medication IS NOT NULL THEN
        SET message = CONCAT(medication_name_param, ' interacts with ', ddi_medication, ' currently prescribed to ', patient_name_param);
        SIGNAL SQLSTATE 'HY000' SET MESSAGE_TEXT = message;
    END IF;

    -- No exceptions thrown, so insert the prescription record
	INSERT INTO prescription (patient_id, doctor_name, medication_id, pills_per_day, date_assigned)
    VALUES (patient_id_var, doctor_name_param, medication_id_var, ppd_param, NOW());

END //
DELIMITER ;

-- Trigger

DROP TRIGGER IF EXISTS patient_after_update_pregnant;

DELIMITER //

CREATE TRIGGER patient_after_update_pregnant
	AFTER UPDATE ON patient
	FOR EACH ROW
BEGIN
	-- Patient became pregnant
	IF NEW.is_pregnant = 1 THEN
        -- Add pre-natal recommendation
        INSERT INTO recommendation (patient_id, message)
        VALUES (NEW.patient_id, 'Take pre-natal vitamins');
        -- Delete any prescriptions that shouldn't be taken if pregnant
        DELETE FROM prescription
        WHERE patient_id = NEW.patient_id
			AND medication_id IN (
				SELECT medication_id
				FROM medication
				WHERE take_if_pregnant = FALSE
			);
    ELSE
		-- Patient is no longer pregnant
        -- Remove pre-natal recommendation
        DELETE FROM recommendation
        WHERE patient_id = NEW.patient_id
			AND message = 'Take pre-natal vitamins';
    END IF;

END //

DELIMITER ;

-- --------------------------                  TEST CASES                     -----------------------
-- -------------------------- DONT CHANGE BELOW THIS LINE! -----------------------
-- Test cases
truncate prescription;

-- These prescriptions should succeed
call prescribe('Jones', 'Dr.Marcus', 'Happyza', 2);
call prescribe('Johnson', 'Dr.Marcus', 'Forgeta', 1);
call prescribe('Williams', 'Dr.Marcus', 'Happyza', 1);
call prescribe('Phillips', 'Dr.McCoy', 'Forgeta', 1);

-- These prescriptions should fail
-- Pregnancy violation
call prescribe('Jones', 'Dr.Marcus', 'Forgeta', 2);

-- Age restriction
call prescribe('BillyTheKid', 'Dr.Marcus', 'Muscula', 1);

-- Drug interaction
call prescribe('Williams', 'Dr.Marcus', 'Sadza', 1);

-- Testing trigger
-- Phillips (patient_id=4) becomes pregnant
-- Verify that a recommendation for pre-natal vitamins is added
-- and that her prescription for
update patient
set is_pregnant = True
where patient_id = 4;

select * from recommendation;
select * from prescription;

-- Phillips (patient_id=4) is no longer pregnant
-- Verify that the prenatal vitamin recommendation is gone
-- Her old prescription does not need to be added back

update patient
set is_pregnant = False
where patient_id = 4;

select * from recommendation;
