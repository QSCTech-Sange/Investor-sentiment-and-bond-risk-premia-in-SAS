/*You need to change the directory of the lib to replicate the project*/
%let Project = sentiment/;

/*A sas format of Fama_Bliss*/
data Fama_Bliss;
    infile "&Project/Fama_Bliss_price.txt" FIRSTOBS=2;
    input date YYMMDD8. price1 price2 price3 price4 price5;
    if _n_ > 1;
    format date YYMMDD10.;
run;

/**********************/
/*For counting y_t^(n)*/
/**********************/
%macro county;
%do i = 1 %to 5;
    data y_&i (keep = date y_&i);
        set Fama_Bliss;
        y_&i = - (1/&i)*log(price&i);
    run;
    
    %if &i = 1 %then %do;
        data y_all;
            set y_&i;
        run;
    %end;
    
    %else %do;
        data y_all;
            merge y_all y_&i;
            by date;
        run;
    %end;
    
%end;

%mend county;
%county;


/*****************************/
/*For counting f_t^{n to n+1}*/
/*****************************/
%macro countf;
%do i = 1 %to 4;
%let iplus = %eval(&i+1);
    data f_&i (keep = date f_&i);
        set Fama_Bliss;
        f_&i = price&i - price&iplus;
    run;
    
    %if &i = 1 %then %do;
        data f_all;
            set f_&i;
        run;
    %end;
    
    %else %do;
        data f_all;
            merge f_all f_&i;
            by date;
        run;
    %end;
    
%end;

%mend countf;
%countf;


/**************************/
/*For counting r_{t+1}^{n}*/
/**************************/
%macro countr;
%do i = 1 %to 4;
%let iplus = %eval(&i+1);
    data r_&i (keep = date r_&iplus);
        set Fama_Bliss;
        price_lag&iplus = lag(price&iplus);
        r_&iplus = price&i - price_lag&iplus;
    run;
    
    %if &i = 1 %then %do;
        data r_all;
            set r_&i;
        run;
    %end;
    
    %else %do;
        data r_all;
            merge r_all r_&i;
            by date;
        run;
    %end;
    
%end;

%mend countr;
%countr;


/***************************/
/*For counting rx_{t+1}^{n}*/
/***************************/
/*Need merge first*/
data Fama_Bliss_all;
    merge Fama_Bliss r_all y_all f_all;
    by date;
run;

%macro countrx;
%do i = 1 %to 4;
%let iplus = %eval(&i+1);
    data rx_&i (keep = date rx_&iplus);
        set Fama_Bliss_all;
        y_lag_1 = lag (y_1);
        rx_&iplus = r_&iplus - y_lag_1;
    run;
    
    %if &i = 1 %then %do;
        data rx_all;
            set rx_&i;
        run;
    %end;
    
    %else %do;
        data rx_all;
            merge rx_all rx_&i;
            by date;
        run;
    %end;
    
%end;

%mend countrx;
%countrx;


/*******************/
/*For counting rxba*/
/*******************/
data rxba (keep = rxba date);
    set rx_all;
    rxba = 1/4 * (rx_2 + rx_3 + rx_4 + rx_5);
run;


/*******************/
/*For counting CP_t*/
/*******************/
/*Merge data first*/
data Fama_Bliss_all;
    merge Fama_Bliss_all rxba;
    by date;
    y_lag_1 = lag (y_1);
    f_lag_1 = lag (f_1);
    f_lag_2 = lag (f_2);
    f_lag_3 = lag (f_3);
    f_lag_4 = lag (f_4);
run;

data for_reg;
    set Fama_Bliss_all(Firstobs=2);
run;
/*REG and get the fit value*/
proc model data = for_reg outparms=CP_t;
   parm b0-b5;
   rxba = b0 + b1 * y_lag_1 + b2 * f_lag_1 + b3 * f_lag_2 + b4 * f_lag_3 + b5 * f_lag_4;
   fit rxba;
run;
/*Get the Fitted Value*/
data CP_t;
    set CP_t;
    merge_temp = 1;
run;

data for_reg;
    set for_reg;
    merge_temp = 1;
run;

data fit;
    merge CP_t for_reg;
    by merge_temp;
run;

data CP(keep=CP date);
    set fit;
    CP = b0 + b1 * y_lag_1 + b2 * f_lag_1 + b3 * f_lag_2 + b4 * f_lag_3 + b5 * f_lag_4;
    if CP = . then delete;
run;


/*************/
/*Counting LN*/
/*************/
proc import datafile = "&Project/Updated_LN_Macro_Factors_2018AUG.xlsx" 
            OUT = LN 
            DBMS = xlsx replace;
run;
/*Change the date to be month*/
data rxba;
    set rxba;
    year = year (date);
    month = month (date);
run;

data LN;
    set LN;
    year = year (data);
    month = month (data);
run;
/*Merge and calculate LN*/
data for_reg;
    merge LN(in = a) rxba(in = b);
    by year month;
    if a=1 and b=1;
run;
data for_reg;
    set for_reg;
    F1_lag = lag (F1);
    F13_lag = lag (F13);
    F3_lag = lag (F3);
    F4_lag = lag (F4);
    F8_lag = lag (F8);
run;
proc model data = for_reg outparms=LN_t;
   parm b0-b5;
   rxba = b0 + b1 * F1_lag + b2 * F13_lag + b3 * F3_lag + b4 * F4_lag + b5 * F8_lag;
   fit rxba;
run;
/*Get the Fitted Value*/
data LN_t;
    set LN_t;
    merge_temp = 1;
run;

data for_reg;
    set for_reg;
    merge_temp = 1;
run;

data fit;
    merge LN_t for_reg;
    by merge_temp;
run;

data LN(keep=LN year month);
    set fit;
    LN = b0 + b1 * F1_lag + b2 * F13_lag + b3 * F3_lag + b4 * F4_lag + b5 * F8_lag;
    if LN = . then delete;
run;

data CP (keep = CP year month);
    set CP;
    year = year (date);
    month = month (date);
run;

/*************/
/*Counting BW*/
/*************/

proc import datafile = "&Project/Copy of Investor_Sentiment_Data_20160331_POST.xlsx" 
            OUT = BW
            DBMS = xlsx replace;
            Sheet = DATA;
run;

data BW;
    set BW;
    month = mod(yearmo,100);
    year = (yearmo - month ) / 100;
run;

data BW;
    merge BW(in=a) rxba(in=b);
    by year month;
    if a = 1 and b = 1;
run;

data for_reg;
    set BW;
    deltaSent = dif(SENT);
    SENT = lag(SENT);
    SENT2 = lag(SENT2);
    deltaSent = lag(deltaSent);
run;

proc model data = for_reg outparms=BW_t;
   parm b0-b3;
   rxba = b0 + b1 * SENT + b2 * SENT2 + b3 * deltaSENT;
   fit rxba;
run;
/*Get the Fitted Value*/
data BW_t;
    set BW_t;
    merge_temp = 1;
run;

data for_reg;
    set for_reg;
    merge_temp = 1;
run;

data fit;
    merge BW_t for_reg;
    by merge_temp;
run;

data BW(keep=BW year month);
    set fit;
    BW = b0 + b1 * SENT + b2 * SENT2 + b3 * deltaSENT;
    if BW = . then delete;
run;


/******************/
/*Final Regression*/
/******************/
data rx_all;
    set rx_all;
    year = year (date);
    month = month (date);
run;

data final(drop = date);
    merge CP(in = a) BW(in = b) LN(in = c) rx_all(in = d);
    by year month;
    if a = 1 and b = 1 and c = 1 and d = 1;
run;

%macro predict;
%do i = 2 %to 5;
    proc reg data = final outest = rx_predict_&i;
        model rx_&i = CP BW LN;
    run;
    
    %if i=2 %then %do;
        data rx_predict_all;
            set rx_predict_&i;
        run;
    %end;
    %else %do;
        data rx_predict_all;
            set rx_predict_all rx_predict_&i;
        run;
    %end;
%end;
%mend predict;
%predict;
   
proc export data=rx_predict_all 
            outfile="&Project/rx_predict_all.csv";
run;