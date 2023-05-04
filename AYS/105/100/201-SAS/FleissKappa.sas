PROC IMPORT
	DATAFILE="E:\Users\ddevries\VUMC BM\Experiments\AYS\105\100\201 [2023-03-21_11.10.41]\Results\01 Analysis\SAS Export.xlsx"
	DBMS=xlsx
	OUT=work.ObserverData replace;

/* Open PDF to write results to */
ODS PDF FILE="E:\Users\ddevries\VUMC BM\Experiments\AYS\105\100\201-SAS\Results.pdf" style=Sapphire;

%inc "E:\Users\ddevries\VUMC BM\Experiments\AYS\105\100\201-SAS\magree.sas";

%magree(data=ObserverData,
              items=s, raters=r, response=y,
              stat=nominal, options=counts)