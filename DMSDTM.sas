/*************************************************************************
*** Program Name : DMSDTM.sas
*** Author       : Fatima Rawoof
*** Date         : Feb-2021
*** Purpose      : Mapping DM-SDTM variable as per the CDISC
****************************************************************************/

data rawdm;
   set finalraw.dm1;
run;


data rawae;
   set finalraw.ae2;
run;


data rawiconsent;
   set finalraw.iconsent;
run;


data rawtrtend;
   set finalraw.trtend;
run;


data rawtrtstart;
  set finalraw.trtstart;
run;


proc sort data=rawdm out=dm1;
  by subject;
run;

/* To derive STUDYID USUBJID SUBJID DOMAIN COUNTRY BRTHDTC*/

data dm2  (drop = birthdtyy  studyid1 race1 ethnic1 race1 sex1 siteid1);

   set dm1   (rename = (studyid=studyid1 ethnic=ethnic1 race=race1  sex=sex1 siteid=siteid1));

      studyid=studyid1;
      usubjid=compress(studyid1)||'-'|| strip(subject);
      subjid=strip(subject);
      if datapagename='Demographics' then domain='DM';
      siteid=strip(siteid1);
      race=upcase(race1);
      country='USA';
      brthdtc=put(birthdtyy,4.);
run;

/* To identify Subjects that died during the Trial from Adverse Event */
data death1  (keep=subjid dthdtc dthfl);

   set rawae;
   subjid= strip(subject);
   if aeout=5 or saeth=1;
     dthfl='y';
   if not(AESTdtYy=. and  AESTdtmm="" and AESTDT="") then  
   do;
       dthdtc=put(aestdtyy,z4.)||'-'||strip(aestdtmm)||'-'||strip(aestdtdd);
   end;
run;


proc sort data=dm2;
  by subjid;
run;


proc sort data=death1;
  by subjid;
run;


/* to map RFICDTC from informed consent dataset*/


data icdate(keep=subjid rficdtc);

   length subjid $20;
   set rawiconsent;
   subjid=strip(subject);
   rficdtc=put(icdt,yymmdd10.);
   run;
   
proc sort data=icdate;
  by subjid;
run;
   

/* to derive RFSTDTC RFXSTDTC*/

proc sort data=rawtrtstart out=start;
  by subject trtstdt trtsttm;
run;  


/* to keep only first subject and derive ARMCD AND ARM variable */

data start1;
  length armcd $8 arm $100;
  set start;
  by subject trtstdt trtsttm;
  if first.subject;

  if dose=150 then 
  do;
    armcd='MAXLTAB';
    arm='Maxl Tablet';
  end;

  if dose=80 then 
  do;
    armcd='MAXLCAP';
    arm='Maxl Capsule';
  end;


  if dose=. then 
  do;
    armcd='SCRNFAIL';
    arm='Screen Failure';
  end;

  drop dose doseu;
run;


data start2 (keep=subjid rfstdtc rfxstdtc  armcd arm);
  set start1;
  subjid=strip(subject);
  rfstdtc=put(trtstdt,yymmdd10.);
  rfxstdtc=rfstdtc;
run;



/* to derive rfendtc, rfxendtc from rawtrtend*/
proc sort data=rawtrtend out=end ;
  by subject trtendt trtentm;
run;


/* to keep only first subject*/
data end1;
  set end;
  by subject trtendt trtentm;
  if first.subject;
run;


data end2(keep=subjid rfendtc rfxendtc);
  set end1;
  subjid=strip(subject);
  rfendtc=put(trtendt,yymmdd10.);
  rfxendtc=rfendtc;
run;

/* to combine all the dataset together */

data dm3;
  merge dm2 icdate death1 start2 end2;
  by subjid;
  actarmcd=armcd;
  actarm=arm;


/* as only birthyear was present so age is derived from rfstdtc and 
brthdtc as below*/

  if rfstdtc ne ""  and  brthdtc ne "" then 
  do;
    age=input(substr(rfstdtc,1,4),best.)-input(brthdtc,best.);
  end;
run;


options validvarname=upcase;
options nofmterr;
 
 
data sdtmdm;
  attrib 
      STUDYID     LABEL='Study Identifier'                      LENGTH= $ 10  
      DOMAIN      LABEL='Domain Abbreviation'
      USUBJID     LABEL='Unique Subject Identifier '            LENGTH= $ 18
      SUBJID      LABEL='Subject Identifier for the Study'      LENGTH= $ 8
      DTHDTC      LABEL='Date/Time of Death'
      DTHFL       LABEL='Subject Death Flag'
      RFSTDTC     LABEL='Subject Reference Start Date/Time'     LENGTH= $ 19
      RFENDTC     LABEL='Subject Reference End Date/Time'       LENGTH= $ 19
      RFXSTDTC    LABEL='Date/Time of First Study Treatment'    LENGTH= $ 19
      RFXENDTC    LABEL='Date/Time of Last Study Treatment '    LENGTH= $ 19 
      RFICDTC     LABEL='Date/Time of Informed Consent'         LENGTH= $ 19
      SITEID      LABEL='Study Site Identifier'                 LENGTH= $ 3
      BRTHDTC     LABEL='Date/Time of Birth'
      AGE         LABEL='Age'
      AGEU        LABEL='Age Units'
      SEX         LABEL='Sex'
      RACE        LABEL='Race'                                  LENGTH= $ 41
      ETHNIC      LABEL='Ethnicity'
      ARMCD       LABEL='Planned Arm Code'                      LENGTH= $ 20
      ARM         LABEL='Description Of Planned Arm'            LENGTH= $ 60
      COUNTRY     LABEL='Country'                               LENGTH= $ 3
      ACTARM      LABEL='Description of Actual Arm'             LENGTH= $ 60            
      ACTARMCD    LABEL='Actual Arm Code'                       LENGTH= $ 20
 ;
 
  set dm3;
 
 
  keep STUDYID DOMAIN USUBJID SUBJID SITEID SEX RACE ETHNIC AGE AGEU COUNTRY
       BRTHDTC RFICDTC DTHDTC  DTHFL RFSTDTC RFENDTC RFXSTDTC RFXENDTC ARM
       ARMCD ACTARM ACTARMCD;
run;     
 
 
proc print data=sdtmdm;
run;
 
 
proc contents data=sdtmdm varnum;
run;
 

