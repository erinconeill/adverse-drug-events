-- HW5: Identifying Adverse Drug Events (ADEs) with Stored Programs
-- Prof. Rachlin
-- CS 3200 / CS5200: Databases

-- We've already setup the ade database by running ade_setup.sql
-- First, make ade the active database.  Note, this database is actually based on
-- the emr_sp schema used in the lab, but it included some extra tables.

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

    -- check age of patient


    -- check if medication ok for pregnant women


    -- Check for reactions involving medications already prescribed to patient


    -- No exceptions thrown, so insert the prescription record

end //
delimiter ;




-- Trigger

DROP TRIGGER IF EXISTS patient_after_update_pregnant;

DELIMITER //

CREATE TRIGGER patient_after_update_pregnant
	AFTER UPDATE ON patient
	FOR EACH ROW
BEGIN

    -- Patient became pregnant
    -- Add pre-natal recommenation
    -- Delete any prescriptions that shouldn't be taken if pregnant


    -- Patient is no longer pregnant
    -- Remove pre-natal recommendation


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
