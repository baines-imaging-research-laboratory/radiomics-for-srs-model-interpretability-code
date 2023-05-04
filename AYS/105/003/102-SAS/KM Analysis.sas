/* Import data from Excel that was exported from Matlab */
PROC IMPORT
	DATAFILE="E:\Users\ddevries\VUMC BM\Experiments\AYS\105\003\102 [2023-02-25_14.27.49]\Results\01 Analysis\SAS Analysis Export.xlsx"
	DBMS=xlsx
	OUT=work.KMData replace;

/* Open PDF to write results to */
ODS PDF FILE="E:\Users\ddevries\VUMC BM\Experiments\AYS\105\003\102-SAS\Results.pdf" style=Sapphire;

/* -------------------------------------------------------------------
   Code generated by SAS Task

   Generated on: Monday, March 28, 2022 at 1:35:58 PM
   By task: Life Tables 1

   Input Data: Local:WORK.KMDATA
   Server:  Local
   ------------------------------------------------------------------- */
ODS GRAPHICS ON;

%_eg_conditional_dropds(WORK.TMP0TempTableInput,
		WORK.TMP2TempTablePlot0);
/* -------------------------------------------------------------------
   Sort data set Local:WORK.KMDATA
   ------------------------------------------------------------------- */

PROC SQL;
	CREATE VIEW WORK.TMP0TempTableInput AS
		SELECT T."Time to Event (days)"n, T."Event is Censor"n, T.Group
	FROM WORK.KMDATA as T
;
QUIT;

/*-----------------------------------------------------
     Analysis Section
*/

TITLE;
TITLE1 "Life Tables Analysis";
FOOTNOTE;
FOOTNOTE1 "Generated by SAS (&_SASSERVERNAME, &SYSSCPL) on %TRIM(%QSYSFUNC(DATE(), NLDATE20.)) at %TRIM(%QSYSFUNC(TIME(), NLTIMAP25.))";

/*-----------------------------------------------------
     Run PROC LIFETEST to perform the analysis.
*/
PROC LIFETEST DATA=WORK.TMP0TempTableInput
	ALPHA=0.05
	PLOTS(ONLY)=SURVIVAL

;
	STRATA Group /Diff=all Adjust=bonferroni; /* Added tests between all strata w/ Bonferroni multiple test correction */
	TIME "Time to Event (days)"n * "Event is Censor"n (1);

RUN;TITLE; 
/* -------------------------------------------------------------------
   End of task code
   ------------------------------------------------------------------- */
RUN; QUIT;
%_eg_conditional_dropds(WORK.TMP0TempTableInput,
		WORK.TMP2TempTablePlot0);
TITLE; FOOTNOTE;
ODS GRAPHICS OFF;
ODS PDF CLOSE;