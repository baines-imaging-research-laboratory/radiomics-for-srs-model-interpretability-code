%macro magree(version,
   data=_last_,
   items=,
   raters=,
   response=,
   stat=ALL,
   alpha=0.05,
   weight=, wtparm=,
   options=PRINT WEIGHTS NOCOUNTS SUMMARY Z NOFIXRATERONLY NOPERCATEGORY NOWCL NOITEMEFFECTS NORATEREFFECTS
   ) / minoperator;

%let time = %sysfunc(datetime());
%let _version=3.91;
%if &version ne %then %put NOTE: &sysmacroname macro Version &_version;
%if &data=_last_ %then %let data=&syslast;
%local notesopt; 
%let notesopt = %sysfunc(getoption(notes));
%let newchk=1;
%let version=%upcase(&version);
%if %index(&version,DEBUG) %then %do;
  options notes mprint
    %if %index(&version,DEBUG2) %then mlogic symbolgen;
  ;  
  ods select all;
  %put _user_;
%end;
%else %do;
  %if %index(&version,NOCHK) %then %let newchk=0;
  options nonotes nomprint nomlogic nosymbolgen;
  ods exclude all;
%end;


/* Check for newer version
 ======================================================================*/
%if &newchk %then %do;
   %let _notfound=0;
   filename _ver url 'http://ftp.sas.com/techsup/download/stat/versions.dat' 
            termstr=crlf;
   data _null_;
     infile _ver end=_eof;
     input name:$15. ver;
     if upcase(name)="&sysmacroname" then do;
       call symput("_newver",ver); stop;
     end;
     if _eof then call symput("_notfound",1);
     run;
   options notes;
   %if &syserr ne 0 or &_notfound=1 or &_newver=0 %then
     %put NOTE: Unable to check for newer version of &sysmacroname macro.;
   %else %if %sysevalf(&_newver > &_version) %then %do;
     %put NOTE: A newer version of the &sysmacroname macro is available at;
     %put NOTE- this location: http://support.sas.com/ ;
   %end;
   %if %index(&version,DEBUG)=0 %then options nonotes;;
%end;


/* Check inputs
 ======================================================================*/
%let data=%upcase(&data);
%let stat=%upcase(&stat);
%let weight=%upcase(&weight);
%let options=%upcase(&options);
%let items=%upcase(&items);
%let raters=%upcase(&raters);
%let response=%upcase(&response);
%let wtmat=; %let wtpow=;

/* Verify DATA= is specified and the data set exists */
%if &data ne %then %do;
  %if %sysfunc(exist(&data)) ne 1 %then %do;
    %put ERROR: DATA= data set, &data, not found.;
    %goto exit;
  %end;
%end;
%else %do;
  %put ERROR: The DATA= parameter is required.;
  %goto exit;
%end;

/* Verify required parameters were specified */
%if &items= %then %do;
  %put ERROR: The ITEMS= parameter is required.;
  %goto exit;
%end;
%if &raters= %then %do;
  %put ERROR: The RATERS= parameter is required.;
  %goto exit;
%end;
%if &response= %then %do;
  %put ERROR: The RESPONSE= parameter is required.;
  %goto exit;
%end;

/* Verify valid STAT= and OPTIONS= values */
%let validstats=KAPPA KENDALL GWET GLMM ALL NOMINAL ORDINAL;
%let kappa=0; %let kendall=0; %let gwet=0; %let glmm=0;
%let ord=0; %let nom=0;
%if (NOMINAL in &stat) and (ORDINAL in &stat) %then %let stat=ALL;
%if (NOMINAL in &stat) %then %do;
  %let nom=1; %let stat=KAPPA GWET;
  %let kappa=1; %let kendall=0; %let gwet=1; %let glmm=0;
%end;
%else %if (ORDINAL in &stat) %then %do;
  %let ord=1; %let stat=KENDALL GWET GLMM;
  %let kappa=0; %let kendall=1; %let gwet=1; %let glmm=1;
%end;
%else %do;
   %let i=1;
   %do %while (%scan(&stat,&i) ne %str() );
      %let stat&i=%upcase(%scan(&stat,&i));
      %if &&stat&i=ALL %then %do;
        %let kappa=1; %let kendall=1; %let gwet=1; %let glmm=1;
      %end;
      %else %if &&stat&i=KAPPA %then %let kappa=1;
      %else %if &&stat&i=KENDALL %then %let kendall=1;
      %else %if &&stat&i=GWET %then %let gwet=1;
      %else %if &&stat&i=GLMM %then %let glmm=1;
      %else %do;
       %let chk=%eval(&&stat&i in &validstats);
       %if not &chk %then %do;
         %put ERROR: Valid values of STAT= are &validstats..;
         %goto exit;
       %end;
      %end;
      %let i=%eval(&i+1);
   %end;
%end;

%let validopts=PRINT NOPRINT WEIGHTS NOWEIGHTS COUNTS NOCOUNTS SUMMARY NOSUMMARY T Z FIXRATERONLY NOFIXRATERONLY PERCATEGORY NOPERCATEGORY WCL NOWCL ITEMEFFECTS NOITEMEFFECTS RATEREFFECTS NORATEREFFECTS;
%let print=1; %let wttab=1; %let cnttab=0; %let ratsumm=1; %let t=0; %let jack=1;
%let percat=0; %let wcl=0; %let effi=0; %let effr=0;
%let i=1;
%do %while (%scan(&options,&i) ne %str() );
   %let option&i=%upcase(%scan(&options,&i));
   %if &&option&i=NOPRINT %then %let print=0;
   %else %if &&option&i=NOWEIGHTS %then %let wttab=0;
   %else %if &&option&i=COUNTS %then %let cnttab=1;
   %else %if &&option&i=NOSUMMARY %then %let ratsumm=0;
   %else %if &&option&i=T %then %let t=1;
   %else %if &&option&i=FIXRATERONLY %then %let jack=0;
   %else %if &&option&i=PERCATEGORY %then %let percat=1;
   %else %if &&option&i=WCL %then %let wcl=1;
   %else %if &&option&i=ITEMEFFECTS %then %let effi=1;
   %else %if &&option&i=RATEREFFECTS %then %let effr=1;
   %else %do;
    %let chk=%eval(&&option&i in &validopts);
    %if not &chk %then %do;
      %put ERROR: Valid values of OPTIONS= are &validopts..;
      %goto exit;
    %end;
   %end;
   %let i=%eval(&i+1);
%end;

/* Check for existence of variable names, get response variable type */
%let dsid=%sysfunc(open(&data));
%if &dsid %then %do;
  %let chkitem=%sysfunc(varnum(&dsid,&items));
  %let chkrate=%sysfunc(varnum(&dsid,&raters));
  %let chkresp=%sysfunc(varnum(&dsid,&response));
  %let ytype=%sysfunc(vartype(&dsid,&chkresp));
  %let rc=%sysfunc(close(&dsid));
%end;
%else %do;
  %put ERROR: Could not open DATA= data set.;
  %goto exit;
%end;
%if &chkitem=0 %then %do;
  %put ERROR: Variable &items not found.;
  %goto exit;
%end;
%if &chkrate=0 %then %do;
  %put ERROR: Variable &raters not found.;
  %goto exit;
%end;
%if &chkresp=0 %then %do;
  %put ERROR: Variable &response not found.;
  %goto exit;
%end;

title2 "The MAGREE macro";

/* Remove missing values. Rename ITEMS, RATERS, or RESPONSE variable 
 * to avoid collision with FREQ OUT= names COUNT or PERCENT
 ======================================================================*/
data _nomiss; 
  set &data(where=(not missing(&items) and 
                   not missing(&raters) and 
                   not missing(&response))); 
  
  %if &items=COUNT %then %do;
    _ITEMS=count; %let items=_ITEMS; drop count;
  %end;
  %if &items=PERCENT %then %do;
    _ITEMS=percent; %let items=_ITEMS; drop percent;
  %end;
  %if &raters=COUNT %then %do;
    _RATERS=count; %let raters=_RATERS; drop count;
  %end;
  %if &raters=PERCENT %then %do;
    _RATERS=percent; %let raters=_RATERS; drop percent;
  %end;
  %if &response=COUNT %then %do;
    _RESPONSE=count; label _response="&response";
    %let response=_RESPONSE; drop count;
  %end;
  %if &response=PERCENT %then %do;
    _RESPONSE=percent; label _response="&response";
    %let response=_RESPONSE; drop percent;
  %end;
  run;

/* Get numbers of items, raters, and response categories
 ======================================================================*/
proc freq data=_nomiss nlevels;
  table &items*&raters   / sparse out=_balance;
  table &items           / out=_Ri(drop=percent rename=(count=Ri));
  table &response;
  ods output nlevels=_nlvls;
  run;
data _null_;
  set _nlvls;
  if upcase(TableVar)="&raters"   then call symput('m',cats(nlevels));
  if upcase(TableVar)="&items"    then call symput('n',cats(nlevels));
  if upcase(TableVar)="&response" then call symput('ncat',cats(nlevels));
  run;
data _TRi; /* save for later printing */
  set _Ri; 
  run;

/* Check for conditions when statistics cannot be computed
 ======================================================================*/
%if &m=1 or &n=1 %then %do;
  %put ERROR: There must be more than one rater and more than one item.;
  %put ERROR- No statistics are computed.;
  %goto exit;
%end;

%if &ncat=1 %then %do;
  %put ERROR: Only one response category. All ratings are the same.;
  %put ERROR- No statistics are computed.;
  %goto exit;
%end;

%if &ytype ne C %then %do;
   proc summary data=_nomiss nway; 
     var &response; class &items; 
     output out=_vars var=var; 
     run;
   proc sql noprint; 
     select sum(var) into :var from _vars; 
     quit;
   %if %sysevalf(&var < 1e-8) %then %do;
     %put ERROR: All ratings identical in each subject. No variability.;
     %put ERROR- No statistics are computed.;
     %goto exit;
   %end;
%end;

%let kaptest=1; %let kap1rate=0; %let multrate=0; %let kenmissrate=0; 
%let glmmnoprod=0; %let kennoprod=0;

data _null_;
  set _balance nobs=_nobs;
  if count ne 1 then do;
     call symput('kenmissrate',1);
     call symput('kaptest',0);
  end;
  if count>1 then call symput('multrate',1);
  run;
%if &multrate %then %do;
  %put ERROR: No rater may rate any item more than once.;
  %put ERROR- No statistics are computed.;
  %goto exit;
%end;

data _null_;
  set _Ri;
  if Ri<=1 then call symput('kap1rate',1);
  run;
%if &glmm and (%sysprod(iml)=0 or %sysprod(stat)=0) %then call symput('glmmnoprod',1);
%if &kendall and %sysprod(stat)=0 %then call symput('kennoprod',1);

/* Notes */
options notes;
%if &kappa %then %do;
   %if &kap1rate %then %do;
     %let kappa=0;
     %put NOTE: One or more items have only one rating. Kappa statistics not computed.;
   %end;
   %if &weight ne %then %do;
     %let kappa=0;
     %put NOTE: Kappa statistics not computed when weights are specified.;
   %end;
   %if &kappa and &kaptest=0 %then %do;
     %put NOTE: Tests for kappa are only available when all items have an equal;
     %put NOTE- number of ratings.;
   %end;
%end;
%if &gwet %then %do;
   %if &m<3 %then %do;
     %put NOTE: For Gwet statistics, unconditional and fixed items standard errors;
     %put NOTE- require 3 raters or more.;
   %end;
%end;
%if &kendall %then %do;
   %if &kenmissrate %then %do;
     %let kendall=0;
     %put NOTE: To compute the Kendall statistic, each rater must rate each; 
     %put NOTE- item exactly once. Kendall statistics not computed.;
   %end;
   %if &ytype=C %then %do;
     %let kendall=0;
     %put NOTE: The Kendall statistic requires a numeric, ordinal response.;
     %put NOTE- Kendall statistics not computed.;
   %end;
   %if &weight ne %then %do;
     %let kendall=0;
     %put NOTE: Kendall statistic not computed when weights are specified.;
   %end;
   %if &kennoprod %then %do;
     %let kendall=0;
     %put NOTE: The Kendall statistic requires SAS/STAT.;
     %put NOTE- Kendall statistics not computed.;
   %end;
%end;
%if &glmm %then %do;
   %if &m<3 %then %do;
     %let glmm=0;
     %put NOTE: GLMM-based statistics require 3 raters or more.;
     %put NOTE- GLMM-based statistics not computed.;
   %end;
   %if &ytype=C %then %do;
     %let glmm=0;
     %put NOTE: The GLMM-based statistics requires a numeric, ordinal response.;
     %put NOTE- GLMM-based statistics not computed.;
   %end;
   %if &glmmnoprod %then %do;
     %let glmm=0;
     %put NOTE: The GLMM-based statistics require SAS/IML and SAS/STAT.;
     %put NOTE- GLMM-based statistics not computed.;
   %end;
%end;
%if &ord and &weight= %then %do;
  %let gwet=0;
  %put NOTE: With an ordinal response, WEIGHT= is required for the Gwet statistic.;
%end;
%if &nom and &weight ne %then %do;
  %let weight=;
  %put NOTE: With an nominal response, WEIGHT= is ignored for the Gwet statistic.;
%end;
%if &weight ne %then %do;
   %let wterr=0;
   %if &gwet=0 and &glmm=0 %then %do;
     %put NOTE: WEIGHT= is ignored unless GWET, GLMM, ORDINAL, or ALL is specified in STAT=.;
   %end;
   %else %do;
      %if &weight=LINEAR %then %let wtpow=1; 
      %else %if &weight=QUADRATIC %then %let wtpow=2; 
      %else %if &weight=SQRT %then %let wtpow=0.5; 
      %else %if %sysevalf(&weight>=.01 and &weight<=5) %then %let wtpow=&weight;
      %else %if %sysfunc(exist(&weight)) %then %do;
         %let wtmat=&weight; %let weight=USER; 
      %end;
      %else %if &weight ne ID %then %do;
         %put ERROR: Valid values of WEIGHT= are LINEAR, QUADRATIC, SQRT, ID, a real;
         %put ERROR- value between 0.01 and 5, or a data set name containing a valid;
         %put ERROR- weight matrix.;
         %goto exit;
      %end;
   %end;
%end;
%if &wtparm ne %then %do;
  %if &weight= or &weight=USER or (&gwet=0 and &glmm=0) %then %do;
     %put NOTE: WTPARM= is ignored since weight computation was not requested;
     %put NOTE- or GWET, GLMM, ORDINAL, or ALL was not specified in STAT=.;
  %end;
  %else %if %sysevalf(&wtparm<.01 or &wtparm>A) %then %do;
     %put ERROR: WTPARM must be a real number greater than or equal to 0.01.;
     %goto exit;
  %end;
%end;
%if %index(&version,DEBUG)=0 %then options nonotes;;

/* Errors */
%if (&gwet or &glmm) and &weight=USER %then %do;
  data _null_;
    set &wtmat end=eof;
    array w (*) _numeric_;
    do i=1 to dim(w);
      if w(i)<0 then do;
        call symput('gwet',0); call symput('glmm',0);
      end;
      if i=_n_ then if w(i) ne 1 then do;
        call symput('gwet',0); call symput('glmm',0);
      end;
    end;
    if eof then do;
      if _n_ ne dim(w) then do;
        call symput('gwet',0); call symput('glmm',0);
      end;
      if dim(w) ne &ncat then do;
        call symput('gwet',0); call symput('glmm',0);
      end;
    end;
    run;
  %if &gwet=0 and &glmm=0 %then %do;
    %put ERROR: The symmetric matrix specified in WEIGHT= must have &ncat rows and;
    %put ERROR- columns and all values must be positive with 1 on the diagonal.;
    %put ERROR- Gwet and GLMM-based statistics will not be computed.;
    %goto exit;
  %end;
%end;

/* Delete old data sets to avoid append problem */
proc datasets nolist nowarn;
  delete _kappas _gacJack;
  run; quit;

/* Code the response levels in sorted order as _LEVEL=1,2,... */
%if &kappa or &gwet or &glmm %then %do;
   proc sort data=_nomiss out=_kapnomiss;
     by &response;
     run;
   data _kapnomiss;
     set _kapnomiss;
     by &response;
     if first.&response then _code+1;
     _level=_code;
     run;  
%end;

/* For Gwet or GLMM: Generate weights and get sum of weights */
      %if (&gwet or &glmm) and &weight ne and &weight ne USER %then %do;
         %if &ytype=N %then %let cats=&response; 
         %else %let cats=_level;
         proc freq data=_kapnomiss;
            table &cats / noprint out=_wtcats;
            run;
         proc transpose data=_wtcats out=_wtcats(keep=col:);
            var &cats;
            run;
         data _gwts;
            set _wtcats;
            array cat (&ncat) col:;
            array w (&ncat);
            keep w:;
            do i=1 to &ncat;
              do j=1 to &ncat;
                %if &wtpow ne %then %do;
                  p=1-(abs(cat(i)-cat(j))/(cat(&ncat)-cat(1)))**&wtpow; 
                %end;
                %else %if &weight=ID %then %do; p=(i=j); %end;
                %if &wtparm ne %then %do;
                  p=min(max(p,1e-8),1-1e-8);
                  w(j)=max(0,1-quantile("exponential",1-p,&wtparm));
                %end;
                %else w(j)=p %str(;);
              end;
              output;
            end;
            run;
         %let wtmat=_gwts;
      %end;
      data _null_; 
        set &wtmat end=eof;
        _rowsum+sum(of _numeric_)-_rowsum;
        if eof then call symputx('sumwt',_rowsum);
        run;

/********************  Compute Fleiss' kappas  *************************/
/***********************************************************************/

%if &kappa %then %do;

   /* Compute kappa statistics for each response level and overall */
   %do i=1 %to &ncat+1;
      data _sub;
        set _kapnomiss;
        %if &percat=0 %then %let i=%eval(&ncat+1);
        %if &i < &ncat+1 %then %do;
          if _code = &i then _level=1;
          else _level=2;
        %end;
        run;
      proc freq data=_sub;
        table &items*_level / out=_nij(drop=percent rename=(count=nij));
        run;
      data _nij2; 
        merge _nij _Ri; 
        by &items; 
        run;
      data _pj; 
        set _nij2;
        pij=nij/(&n*Ri);
        run;
      proc summary data=_pj nway;
        class _level; var pij;
        output out=_pj sum=pj;
        run;
      data _Spj3(keep=Spj3);
        set _pj end=eof;
        Spj3 + pj**3;
        if eof then output;
        run;
      proc sort data=_nij2; 
        by _level; 
        run;
      data _nij3; 
        merge _nij2 _pj; by _level; 
        Peij=nij*pj/Ri;
        Poij=nij*(nij-1)/(Ri*(Ri-1));
        run;
      proc summary data=_nij3 nway;
        class &items; var Poij Peij;
        output out=_Poei sum=Poi Pei;
        run;
      proc summary data=_Poei;
        var Poi Pei;
        output out=_Poe mean=Po Pe;
        run;
      data _flkappa;
        set _Poei end=eof;
        if _n_=1 then do; 
          set _Poe; set _Spj3; 
        end;
        left + ((1-Pe)*Poi-2*(1-Po)*Pei)**2;
        if eof then do;
          kapp = (Po-Pe)/(1-Pe);
          var + ( left/&n - (Po*Pe-2*Pe+Po)**2 ) / (&n*(1-Pe)**4);
          stderr = sqrt(var);
          %if &kaptest %then %do;
            stderrH0 = sqrt( 2*((1-Pe)**2+3*Pe-1-2*Spj3) / ((1-Pe)**2*&n*&m*(&m-1)) );
          %end;
          %else stderrH0=.;;
          z = kapp/stderrH0;
          prob = 1-probnorm(z);
          lcl = kapp - probit(1-&alpha/2)*stderr;
          ucl = kapp + probit(1-&alpha/2)*stderr;
          keep kapp stderrH0 z prob Po Pe stderr lcl ucl;
          output;
        end;
        run;
      proc append base=_kappas data=_flkappa;
        run;
   %end; 
   %if &percat %then %do;
      proc freq data=_kapnomiss; 
        table &response / out=_respvals(keep=&response); 
        run;
      data _kappas; 
        merge _kappas _respvals; 
        run;
   %end;
   %else %do;
      %let ytype=N;
      data _kappas; 
        set _kappas; 
        &response=.;
        run;
   %end;   
%end; 


/*********************  Compute Gwet Statistic  ************************/
/***********************************************************************/

%if &gwet %then %do;

 proc sort data=_kapnomiss out=_gnomiss;
   by &raters;
   run;
 /* Code the raters as _RATER=1,2,... */
 data _gnomiss;
   set _gnomiss;
   by &raters;
   if first.&raters then _RATER+1;
   run;  
 proc datasets nolist nowarn;
   delete _gac;
   run; quit;

 %let var0=0;
 %do cat=1 %to &ncat+1;
   %if &percat=0 %then %let cat=%eval(&ncat+1);
   %else %do;
     data _gnomiss;
       set _gnomiss;
       _level=_code;
       %if &cat<&ncat+1 %then if _code ne &cat then _level=0 %str(;);
       run;
   %end;

   /* Jackknife loop for Var(gac|raters fixed)
    * jiter=1 computes overall gac, 2 thru m+1 drops one rater each
    ======================================================================*/
   proc datasets nolist nowarn;
     delete _gacJack;
     run; quit;
   %if &jack %then %let jstop=%eval(&m+1);   
   %else %let jstop=2;
   %do jiter=1 %to &jstop;
   data _sub; 
     set _gnomiss;
     %if &jiter>1 %then where _rater ne %eval(&jiter-1)%str(;);
     run;
   proc freq data=_sub;
     table &items / noprint out=_Ri(drop=percent rename=(count=Ri));
     table &items*_level / noprint sparse out=_nij(drop=percent rename=(count=nij));
     run;
   %if &weight ne and &cat=&ncat+1 %then %do;
      %if &jiter=1 %then %do;
        data _fullnij0;
          set _nij;
          nij=0;
          run;
        data _fullRi;
          set _TRi;
          Ri=0;
          run;
      %end;
      %else %do;
        data _nij;
          merge _fullnij0 _nij;
          by &items _level;
          run;
        data _Ri;
          merge _fullRi _Ri;
          by &items;
          run;
      %end;
      proc transpose data=_nij out=_catcnts(keep=__:) prefix=__;
        var nij; by &items; id _level;
        run;
      proc fcmp;
         * Define matrix nij;
        array nij[&n,&ncat]/nosymbols;
        rc=read_array('_catcnts',nij);
         * Define full weight matrix w;
        array w[&ncat,&ncat]/nosymbols;
        rc=read_array("&wtmat",w);
         * Define nij transpose, nijt;
        array nijt[&ncat,&n]/nosymbols;
        call transpose(nij,nijt);
         * Compute weighted counts: wnijt = w * nijt;
        array wnijt[&ncat,&n]/nosymbols;
        call mult(w,nijt,wnijt);
         * Define wnijt transpose, wnij;
        array wnij[&n,&ncat]/nosymbols;
        call transpose(wnijt,wnij);
         * Save weighted counts in data set _wcnts;
        rc=write_array('_wcnts',wnij);
        run;
      data _wnij; 
        merge _wcnts _Ri(keep=&items);
        keep &items _level wnij;
        %do j=1 %to &ncat;
           _level=&j;
           wnij=wnij&j; 
           output;
        %end;
        run;
   %end;
   data _nij; 
     merge _nij 
       %if &weight ne and &cat=&ncat+1 %then _wnij;
       _Ri; 
     by &items; 
     %if &weight ne and &cat=&ncat+1 %then 
           nn1ij=nij*(wnij-1) %str(;);
     %else nn1ij=nij*(nij-1)  %str(;);
     if Ri=0 then propij=.;
     else propij=nij/Ri;
     run;
   proc summary data=_nij nway;
     class &items; var nn1ij;
     output out=_sumnn sum=;
     run;
   data _pai; 
     merge _sumnn _Ri; 
     if Ri<=1 then pai=.;
        else pai=nn1ij/(Ri*(Ri-1));
     run;
   proc summary data=_pai;
     var pai;
     output out=_pa mean=pa n=ncontrib;
     run;
   proc summary data=_nij nway;
     class _level; var propij;
     output out=_pj mean=pj;
     run;
   data _pe;
     set _pj end=eof;
     %if &weight ne and &cat=&ncat+1 %then 
           pe + &sumwt*pj*(1-pj)/(&ncat*(&ncat-1)) %str(;);
     %else pe + pj*(1-pj)/(&ncat-1) %str(;);
     if eof then output;
     run;
   data _gacsub;
     merge _pa _pe;
     gac=(pa-pe)/(1-pe);
     run;
   %if &jiter=1 %then %do; 
     proc transpose data=_pj out=_pjt(drop=_name_) prefix=__;
       var pj; id _level; 
       run;
     data _nij; 
       set _nij;
       if _n_=1 then set _pjt; 
       array apj (*) __:;
       %if &cat<&ncat+1 %then %do;
         if _level=0 then __pickpj=1;
         else             __pickpj=2;
       %end;
       %else __pickpj=_level %str(;);
       pj=apj(__pickpj);
       %if &weight ne and &cat=&ncat+1 %then
             pei=&sumwt*nij*(1-pj)/(Ri*&ncat*(&ncat-1)) %str(;);
       %else %do;
         %if &cat=&ncat+1 %then pei=nij*(1-pj)/(Ri*(&ncat-1)) %str(;);
         %else pei=nij*(1-pj)/Ri %str(;);
       %end;
       drop __:;
       run;
     proc summary data=_nij nway;
       var pei; class &items;
       output out=_pei sum=;
       run;
     data _gacAllN;
       merge _pai _pei end=eof; 
       if _n_=1 then set _gacsub (rename=(gac=gacAllN));
       gacihat=(&n/(ncontrib))*(pai-pe)/(1-pe);
       if gacihat=. then gacihat=0;
       gaci=gacihat-2*(1-gacAllN)*(pei-pe)/(1-pe);
       ssdiff+(gaci-gacAllN)**2;
       if eof then do;
          gacVs=ssdiff/(&n*(&n-1));
          keep gacAllN gacVs;
          output;
       end;
       run;
   %end;
   %else %do;
     proc append base=_gacJack data=_gacsub;
       run;
   %end;
 %end; /* end jackknife loop */

 proc summary data=_gacJack vardef=n;
   var gac; 
   output out=_gacVr var=gacVr;
   run;
 data _gaccat;
   set _gacAllN; set _gacVr;
   _level=&cat;
   gacVr=(&m-1)*gacVr;
   df=&n-1;
   keep _level Fixed gacAllN gacSE stat df p l u;
   label
       %if &weight= %then gacAllN="AC1";
       %else              gacAllN="AC2";
   ;
   gacSE=sqrt(gacVs);
   Fixed="Raters";
   stat=.; p=.; l=.; u=.;
   if gacSE ne 0 then do;
      stat=gacAllN/gacSE;
      %if &t %then %do;
        q=quantile("t",1-(&alpha/2),df);
        pr=probt(stat,df);
      %end;
      %else %do;
        q=quantile("normal",1-(&alpha/2));
        pr=probnorm(stat);
      %end;
      p=2*(1-pr); 
      l=max(-1,gacAllN-q*gacSE); 
      u=min(1,gacAllN+q*gacSE);
   end;
   else call symput("var0","1");
   output;
   %if &jack and &m>2 %then %do;
      gacSE=sqrt(gacVr);
        Fixed="Items ";
        stat=.; p=.; l=.; u=.;
        if gacSE ne 0 then do;
           stat=gacAllN/gacSE;
           %if &t %then %do;
             q=quantile("t",1-(&alpha/2),df);
             pr=probt(stat,df);
           %end;
           %else %do;
             q=quantile("normal",1-(&alpha/2));
             pr=probnorm(stat);
           %end;
           p=2*(1-pr); 
           l=max(-1,gacAllN-q*gacSE); 
           u=min(1,gacAllN+q*gacSE);
        end;
        else call symput("var0","1");
        output;
      gacSE=sqrt(gacVs+gacVr);
        Fixed=" ";
        stat=.; p=.; l=.; u=.;
        if gacSE ne 0 then do;
           stat=gacAllN/gacSE;
           %if &t %then %do;
             q=quantile("t",1-(&alpha/2),df);
             pr=probt(stat,df);
           %end;
           %else %do;
             q=quantile("normal",1-(&alpha/2));
             pr=probnorm(stat);
           %end;
           p=2*(1-pr); 
           l=max(-1,gacAllN-q*gacSE); 
           u=min(1,gacAllN+q*gacSE);
        end;
        else call symput("var0","1");
        output;
   %end;
   run;
   proc append base=_gac data=_gaccat;
     run;
 %end; /* end per category loop */  
 %if &percat %then %do;
    proc freq data=_kapnomiss;
      table _level*&response/noprint out=_levlab;
      run;
    data _gac;
      merge _gac _levlab;
      by _level;
      drop count percent _level;
      run;
 %end;
%end;   

/******************* Compute GLMM-based statistics *********************/
/***********************************************************************/

%if &glmm %then %do;
   proc glimmix data=_kapnomiss method=laplace;
      class &items &raters;
      model _level(descending)= / dist=mult link=cumprobit;
      random int/subject=&items
        %if &effi %then solution cl;
        ;
      random int/subject=&raters
        %if &effr %then solution cl;
        ;
      ods output covparms=_covparms convergencestatus=_cs;
      %if &effi %then 
        ods output solutionr=_glmmui(where=(upcase(subject) ? "&items") drop=effect);
        ;
      %if &effr %then 
        ods output solutionr=_glmmvi(where=(upcase(subject) ? "&raters") drop=effect);
        ;
      run;
  %let glmmerr=&syserr; 
  proc sql noprint;
     select status into :convstat from _cs;
     select pdg into :npdstat from _cs;
     quit;
  %if &glmmerr or &convstat>0 or &npdstat=0 %then %let glmmerr=1;
  %if &glmmerr=0 %then %do;
   %let quaderr=0;
   proc iml;
   use _covparms;
   read all var {Estimate} into var;
   rho=var[1]/(var[1]+var[2]+1);
   rho_se=sqrt(
       (2*var[1]##2*(var[2]+1)##2)/(&n*(var[1]+var[2]+1)##4) + 
       (2*var[2]##2*var[1]##2)/(&m*(var[1]+var[2]+1)##4)
        );
   call symput("rho",cats(rho));
   %if &weight= %then %do;
      /* k_m */
      c=1:(&ncat-1);
      start kmint(t) global(c, rho);
         p=probnorm(((quantile('normal',c/&ncat)-t*sqrt(rho))/sqrt(1-rho)));
         p1=p||1; p2=0||p; ssdif=((p1-p2)##2)[+];
         v = ssdif*pdf('normal',t);
         return(v);
      finish;
      lims = {.M  .P};
      call quad(z, "kmint", lims,,,,"NO");
      if z=. then call symput("quaderr","1");
      km=z*&ncat/(&ncat-1)-(1/(&ncat-1));
      /* k_m stderr */
      start kmseint(t) global(c, rho);
         q=(quantile('normal',c/&ncat)-t*sqrt(rho))/sqrt(1-rho);
         p=probnorm(q); p1=p||1; p2=0||p; pdif=p1-p2; 
         phi=pdf('normal',q)#( -t/(2*sqrt(rho*(1-rho))) + 
             (quantile('normal',c/&ncat)-t*sqrt(rho))/(2*(1-rho)##(3/2)) );
         phi1=phi||0; phi2=0||phi; 
         sumvdif=(2*pdif#(phi1-phi2))[+];
         v = sumvdif*pdf('normal',t);
         return(v);
      finish;
      if rho > 1e-8 then do;
         call quad(z, "kmseint", lims,,,,"NO");
         if z=. then call symput("quaderr","2");
         km_se=z*rho_se*(&ncat/(&ncat-1));
         km_lcl=km-probit(1-&alpha/2)*km_se;
         km_ucl=km+probit(1-&alpha/2)*km_se;
      end;
      else do;
         km_se=.; km_lcl=.; km_ucl=.;
      end;
      glmm=km||km_se||km_lcl||km_ucl||rho||rho_se;
      cname="Km"||"KmSE"||"KmLCL"||"KmUCL"||"Rho"||"RhoSE";
      create _glmm from glmm[colname=cname];
      append from glmm;
      close _glmm;
   %end;

   %else %do;
      use &wtmat;
      read all into wt;
      /* k_ma */
      a=(1:(&ncat-1))*1e-5;
      start kmaint(t) global(a, wt, rho);
         p=probnorm(((a-t*sqrt(rho))/sqrt(1-rho)));
         p1=p||1; p2=0||p; 
         x=(p1-p2)`*(p1-p2);
         v = sum(wt#x)*pdf('normal',t);
         return(v);
      finish;
      lims = {.M  .P};
      call quad(z, "kmaint", lims,,,,"NO");
      if z=. then call symput("quaderr","3");
      kma=2*z-1;
      /* k_ma stderr */
      start kmaseint(t) global(a, wt, rho);
         pa=(a-t*sqrt(rho))/sqrt(1-rho);
         pb=(a-t*sqrt(rho))/(2*(1-rho)##(3/2));
         p=probnorm(pa);
         p1=p||1; p2=0||p; pdif=p1-p2;
         phi=pdf('normal',pa)#( -t/(2*sqrt(rho*(1-rho))) + pb );
         phi1=phi||0; phi2=0||phi; phidif=phi1-phi2;
         sumarg=wt#(pdif`*phidif + phidif`*pdif);
         v = sum(sumarg)*pdf('normal',t);
         return(v);
      finish;
      if rho > 1e-8 then do;
         call quad(z, "kmaseint", lims,,,,"NO");
         if z=. then call symput("quaderr","4");
         kma_se=2*rho_se*z;
         kma_lcl=kma-probit(1-&alpha/2)*kma_se;
         kma_ucl=kma+probit(1-&alpha/2)*kma_se;
      end;
      else do;
         kma_se=.; kma_lcl=.; kma_ucl=.;
      end;
      glmm=kma||kma_se||kma_lcl||kma_ucl||rho||rho_se;
      cname="Kma"||"KmaSE"||"KmaLCL"||"KmaUCL"||"Rho"||"RhoSE";
      create _glmm from glmm[colname=cname];
      append from glmm;
      close _glmm;
   %end;
   quit;
   %if &quaderr %then %do;
     %put ERROR: Could not compute the GLMM-based statistic or standard error.;
   %end;
   %if %sysevalf(&rho<1e-8) %then %do;
     %put ERROR: Rho = 0. Could not compute the GLMM-based standard error.;
   %end;
  %end;
  %else %do;
    %if &npdstat=0 %then %do;
      %put ERROR: G matrix is not positive definite. Item and/or rater;
      %put ERROR- variability might be too small to estimate effects.;
    %end;
    %put ERROR: Unable to fit GLMM model for GLMM-based statistics.;
  %end;
%end;

/*********** Compute Kendall's Coefficient of Concordance, W ***********/
/***********************************************************************/

%if &kendall %then %do;

/* Rank the data using average ranks for ties (no change if data are ranks) */
proc sort data=_nomiss out=_sortr;
  by &raters;
  run;
proc rank data=_sortr out=_ranked;
  by &raters; 
  var &response;
  run;
/* R-square from one-way ANOVA is Kendall's W */
proc anova data=_ranked outstat=_anova plots=none; 
  class &items; 
  model &response = &items; 
  run;
/* Compute F statistic and p-value for testing W=0 */
data _concord; 
  set _anova;
  retain SSsubj;
  if _n_=2 then do;
     numdf=&n-1-2/&m;
     dendf=(&m-1)*numdf;
     if ss=0 and SSsubj=0 then do;
       w=1; f=.; prob=.;
     end;
     else do;
       w=ss/(ss+SSsubj);
       if w=1 then do;
         f=.I; prob=0;
       end;
       else do;
         f=(&m-1)*w/(1-w);
         prob=1-probf(f,numdf,dendf);
       end;
     end;
     keep w f numdf dendf prob; 
     output;
  end;
  SSsubj=ss;
  run;     

/* Jackknife for Var(W)
 ======================================================================*/
%if &wcl %then %do;
   proc sort data=_nomiss out=_wnomiss;
     by &items;
     run;
   data _wnomiss;
     set _wnomiss;
     by &items;
     if first.&items then _item+1;
     run;
   proc sort data=_wnomiss out=_sortr;
     by &raters;
     run;
   proc datasets nolist nowarn;
     delete _wjack;
     run; quit;
   %if %index(&version,DEBUG2)=0 %then ods exclude all %str(;);
   %do i=1 %to &n;
      proc rank data=_sortr out=_ranked;
        where _item ne &i;
        by &raters; 
        var &response;
        run;
      proc anova data=_ranked outstat=_anova; 
        class &items; 
        model &response = &items; 
        run;
      data _wsub;
        set _anova;
        retain SSsubj;
        if _n_=2 then do;
           if ss=0 and SSsubj=0 then w=1;
           else w=ss/(ss+SSsubj);
           keep w;
           output;
        end;
        SSsubj=ss;
        run;     
      proc append base=_wjack data=_wsub;
        run;
   %end; /* jackknife loop */
   proc summary data=_wjack vardef=n;
     var w; 
     output out=_wvar var=wvar;
     run;
   data _concord;
     set _concord;
     set _wvar;
     drop _type_ _freq_ wvar;
     wSE=sqrt((&n-1)*wvar);
     %if &t %then q=quantile("t",1-(&alpha/2),&n-1) %str(;);
     %else        q=quantile("normal",1-(&alpha/2)) %str(;);
     l=max(0,w-q*wSE); 
     u=min(1,w+q*wSE);
     run;
%end; /* WCL */
%end; /* Kendall */


ods select all;
%if &print %then %do;

/* Print table to assess balance across items on number of ratings 
 ======================================================================*/
%if &ratsumm %then %do;
   proc freq data=_TRi noprint; 
     table Ri/out=_Risumm;
     run;
   proc print data=_Risumm label;
     id Ri; var count;
     label Ri="Ratings Count"
           count="Items";
     title3 "Ratings Summary";
     run;
%end;

/* Print table of table of rating counts per item
 ======================================================================*/
%if &cnttab %then %do;
   proc freq data=_nomiss;
     table &items*&response / nocol norow nopercent;
     title3 "Rating counts per item";
     run;
%end;

proc format;
   value  
     %if &ytype=C %then %do;
       $_yfmt " "="Overall";
     %end;
     %else %do;
       _yfmt    .="Overall";
     %end;
   run;

/* Print kappa statistics
 ======================================================================*/
%if &kappa and %sysfunc(exist(_kappas)) %then %do;
   proc print data=_kappas label split="/";
     format prob pvalue. 
            &response %if &ytype=C %then $_yfmt.; %else _yfmt.; 
            ;
     id &response;
     var kapp 
         %if &kaptest %then stderrH0 z prob; 
         stderr lcl ucl;
     label kapp="Kappa" stderrH0="Standard/Error|H0" z="Z" prob="Prob>|Z|" 
           stderr="Standard/Error" lcl="Lower/Confidence/Limit" 
           ucl="Upper/Confidence/Limit";
     title3 "Kappa statistics for nominal response";
     run;
%end;

/* Print weight matrix for Gwet and/or GLMM statistics
 ======================================================================*/
%if (&gwet or &glmm) and (%sysfunc(exist(_gac)) or %sysfunc(exist(_glmm))) 
  and &wttab and &weight ne %then %do;
     ods escapechar='^';
     proc print data=&wtmat noobs;
     title3 "Weight matrix for Gwet's AC^{sub 2} and/or GLMM Kappa^{sub ma}";
     run;
%end;

/* Print Gwet statistics
 ======================================================================*/
%if &gwet and %sysfunc(exist(_gac)) %then %do;
   %if &var0 %then %do;
       options notes;
       %put NOTE: Zero variance detected. Some statistics set to missing.;
       %if %index(&version,DEBUG)=0 %then options nonotes;;
   %end;
   proc print data=_gac label split="/"; 
     format p pvalue. 
         %if &percat %then %do;
            &response   %if &ytype=C %then $_yfmt.; %else _yfmt.; 
         %end;
         ;
     id %if &percat %then &response;
        Fixed;
     var gacAllN
       %if &t %then df;
       gacSE stat p l u;
     label 
       gacSE="Standard/Error" 
       %if &t %then %do;
         stat="t Value" df="DF" p="Pr > |t|"
       %end;
       %else %do;
         stat="Z Value" p="Pr > |Z|"
       %end;
       l="Lower/Confidence/Limit" u="Upper/Confidence/Limit";
     title3 "Gwet's Agreement Coefficient";
     run;
%end;

/* Print GLMM statistics
 ======================================================================*/
%if &glmm %then %do;
 %if &glmmerr=0 and %sysfunc(exist(_glmm)) %then %do;
   ods escapechar='^';
   proc print data=_glmm noobs label split='/';
     %if &weight= %then %do;
       title3 "GLMM-based ordinal measure Kappa^{sub m}";
       label Km="Kappa_m" KmSE="Standard/Error" KmLCL="Lower/Confidence/Limit" 
             KmUCL="Upper/Confidence/Limit" RhoSE="Rho/Standard/Error";
     %end;
     %else %do;
       title3 "Weighted GLMM-based ordinal measure Kappa^{sub ma}";
       label Kma="Kappa_ma" KmaSE="Standard/Error" KmaLCL="Lower/Confidence/Limit" 
             KmaUCL="Upper/Confidence/Limit" RhoSE="Rho/Standard/Error";
     %end;
     run;
   %if &effi and %sysfunc(exist(_glmmui)) %then %do;
      proc print data=_glmmui label split='/';
        id subject;
        label subject="Item" stderrpred="Standard/Error"
              upper="Upper/Confidence/Limit" lower="Lower/Confidence/Limit";
        title3 "Estimated Item (&items) random effects";
        run;
   %end;
   %if &effr and %sysfunc(exist(_glmmvi)) %then %do;
      proc print data=_glmmvi label split='/';
        id subject;
        label subject="Rater" stderrpred="Standard/Error"
              upper="Upper/Confidence/Limit" lower="Lower/Confidence/Limit";
        title3 "Estimated Rater (&raters) random effects";
        run;
   %end;
 %end;
 %if &npdstat=0 and %sysfunc(exist(_covparms)) %then %do;
   proc print data=_covparms noobs;
     title "GLMM Variance components";
     run;
 %end;
%end;

/* Print Kendall's coefficient of concordance and test
 ======================================================================*/
%if &kendall and %sysfunc(exist(_concord)) %then %do;
   proc format;
     value _fval .i='Infty';
     run;
   proc print data=_concord label split="/";
     id w;
     var f numdf dendf prob 
       %if &wcl %then wSE l u;
     ;
     format prob pvalue. f _fval.;
     label 
       w="Coefficient/of/Concordance" numdf="Num DF" dendf="Den DF" 
       prob="Prob>F" 
       %if &wcl %then wSE="Standard/Error" 
           l="Lower/Confidence/Limit" u="Upper/Confidence/Limit";
       ;
     title3 "Kendall's Coefficient of Concordance for ordinal response";
     run;
%end;

%end;

/* Clean up and exit
 ======================================================================*/
%exit:
%if %index(&version,DEBUG)=0 %then %do;  
   options nonotes;;
   proc datasets nolist nowarn;
     delete _nomiss _nlvls _balance _Ri _sub _nij: _pj _Spj3 _Poei _Poe 
     _flkappa _respvals _sortr _ranked _anova _Risumm _sumnn _pai _pei 
     _pa _pe _catcnts _wcnts _wnij _gacsub _gacAllN _gacJack _pjt _gwts
     _gacvr _gnomiss _kapnomiss _TRi _fullnij0 _fullRi _wtcats _gaccat
     _levlab _wvar _wsub _wjack _wnomiss _covparms _vars _cs;
     run; quit;
%end;
%if %index(&version,DEBUG) %then %do;
   options nomprint nomlogic nosymbolgen;
   %put _user_;
%end;
ods select all;
options &notesopt;
title;
%let time = %sysfunc(round(%sysevalf(%sysfunc(datetime()) - &time), 0.01));
%put NOTE: The &sysmacroname macro used &time seconds.;
%mend magree;

