create or replace PACKAGE PKG_CLEANUP_ARGUS
AS

PROCEDURE P_CLEANUP 	
					(
						PI_BATCH_NO NUMBER,pi_case_number varchar2 default null
					);


END PKG_CLEANUP_ARGUS;

/



