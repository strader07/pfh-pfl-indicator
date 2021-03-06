
string email_indicator = "";
int Days_count = 40;
bool Correct_sunday = true;
bool UseADRcalculating = true;
string __descr = "need to choise UseADRcalculating or UseATRcalculating to true";
bool UseATRcalculating = false;
int Days_period = 5; // для ADR
extern bool Show_day_last_PF = true; // Show_day_last_PF-test-option-to-find-last-PF
extern bool Hide_chart = true;

extern int height = 18; // Ceil height
extern int width = 110; // Ceil width
extern int font_size = 8; // Ceil font

bool AllSymbols  =  true;
// Для файлов значения
string file_key = "berk.txt";

string shortname;
double bufferADR[];
double bufferPFH[];
double bufferPFL[];
string adr_text;
bool isinit = false;
int total_s; 
double symb_arr[100][5][50];
datetime curdate;
string parse_file[100];
bool already_day_calculated = false; // тру если посчитали все дневные рассчтеы
/*
описание данного массива
1 измерение - [i][0][0] количество символов в окне рынка
2 измерение - [i][1][0-50] - adr для 0-50 баров
2 измерение - [i][2][0-50] - PFH для 0-50 баров
2 измерение - [i][3][0-50] - PFL для 0-50 баров
2 измерение - [i][4][0]    - close_price - последняя известная цена по инструменту (например бид, т.к. он влияет на график или Close[0])
3 измерение - количество баров для анализа и записи 

*/

//-------------------------------------------------------------
// Описание по версиям
// 1.0  - версия дешборда где все символы показывают PFH & PFL 
// 1.10 - добавил лицензии через сайт, онлайн импульсы, текст около номера дня, мелкие недочеты
// 1.20 - мелкие недочеты убрал
// 1.30 - поставил проверку на перебой последней вершики и возврат (вершинка тогда не считается)+проверку адр по Д1+скрыть/открыть график для удобства тестирования
// 1.33 - увеличил количество дней поиска до 40
// 1.34 - обновление значений pfh pfl 1 раз в сутки и не зависит от того, был ли перебит текущий pfl|pfh
// 1.35 - убрал ошибку, когда из за воскресенья неправильно рассчитывается pfl|pfh  https://gyazo.com/4c1008c1e8dca3f90084805f7c657ea5
//-------------------------------------------------------------

#define FALSE 0

#define HINTERNET int
#define BOOL int
#define INTERNET_PORT int
#define LPINTERNET_BUFFERS int
#define DWORD int
#define DWORD_PTR int
#define LPDWORD int&
#define LPVOID uchar& 
#define LPSTR string
#define LPCWSTR	string&
#define LPCTSTR string&
#define LPTSTR string&

#define OPEN_TYPE_PRECONFIG		0   // use default configuration
#define INTERNET_SERVICE_FTP						1 // Ftp service
#define INTERNET_SERVICE_HTTP						3	// Http service 
#define HTTP_QUERY_CONTENT_LENGTH 			5

#define INTERNET_FLAG_PRAGMA_NOCACHE						0x00000100  // no caching of page
#define INTERNET_FLAG_KEEP_CONNECTION						0x00400000  // keep connection
#define INTERNET_FLAG_SECURE            				0x00800000
#define INTERNET_FLAG_RELOAD										0x80000000  // get page from server when calling it
#define INTERNET_OPTION_SECURITY_FLAGS    	     31

#define ERROR_INTERNET_INVALID_CA								12045
#define INTERNET_FLAG_IGNORE_CERT_DATE_INVALID  0x00002000
#define INTERNET_FLAG_IGNORE_CERT_CN_INVALID    0x00001000
#define SECURITY_FLAG_IGNORE_CERT_CN_INVALID    INTERNET_FLAG_IGNORE_CERT_CN_INVALID
#define SECURITY_FLAG_IGNORE_CERT_DATE_INVALID  INTERNET_FLAG_IGNORE_CERT_DATE_INVALID
#define SECURITY_FLAG_IGNORE_UNKNOWN_CA         0x00000100
#define SECURITY_FLAG_IGNORE_WRONG_USAGE        0x00000200



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()  {
   isinit = false; 
   total_s = 0;
   already_day_calculated = false;
   int numMissing = CheckMissing(), i ;
   NumMissing1 = NumMissing2 = SymbolsTotal(AllSymbols);
   ArrayResize(MissingSmb1, NumMissing1); 
   for(i=0; i<NumMissing1; i++) MissingSmb1[i] = SymbolName(i, AllSymbols);
   Print(WindowExpertName(), " V=", __VERSION__, " D=", __DATETIME__, " Missing SMB=", numMissing, " TradeAllowed=", IsTradeAllowed());
   delete_objects();
   ResetLastError();
   bool success = EventSetTimer(30);
   if(!success) {
      Print(ERROR);
      return INIT_FAILED;
   }
   ArrayResize(symb_arr,SymbolsTotal(AllSymbols),SymbolsTotal(AllSymbols)+5);
   
   
   // изменяет чарт если нужно
   if(Hide_chart==true){
      ChartSetInteger(0,CHART_COLOR_BACKGROUND,clrWhite);
      ChartSetInteger(0,CHART_COLOR_ASK,clrWhite);
      ChartSetInteger(0,CHART_COLOR_BID,clrWhite);
      ChartSetInteger(0,CHART_COLOR_CANDLE_BEAR,clrWhite);
      ChartSetInteger(0,CHART_COLOR_CANDLE_BULL,clrWhite);
      ChartSetInteger(0,CHART_COLOR_CHART_DOWN,clrWhite);
      ChartSetInteger(0,CHART_COLOR_CHART_UP,clrWhite);
      ChartSetInteger(0,CHART_COLOR_CHART_LINE,clrWhite);
      ChartSetInteger(0,CHART_SHOW_VOLUMES,false);
      ChartSetInteger(0,CHART_SHOW_OBJECT_DESCR,false);
      ChartSetInteger(0,CHART_SHOW_VOLUMES,false);
      ChartSetInteger(0,CHART_COLOR_GRID,clrWhite);
      ChartSetInteger(0,CHART_SHOW_PERIOD_SEP,false);
      ChartSetInteger(0,CHART_SHOW_OHLC,false);
      ChartSetInteger(0,CHART_MOUSE_SCROLL,false);
      ChartSetInteger(0,CHART_COLOR_FOREGROUND,clrWhite);
      ChartSetInteger(0,CHART_COLOR_STOP_LEVEL,clrWhite);
      ChartSetInteger(0,CHART_SHOW_TRADE_LEVELS,false);      
      ChartSetInteger(0,CHART_DRAG_TRADE_LEVELS,false);   
      ChartSetInteger(0,CHART_SHOW_DATE_SCALE,false);   
      ChartSetInteger(0,CHART_SHOW_PRICE_SCALE,false);   
      ChartSetInteger(0,CHART_FOREGROUND,false); 
   }

   // переходим на н1 таймфрейм всегда
   int hwnd=WindowHandle(Symbol(),Period());
   PostMessageA(hwnd,WM_COMMAND,35400,0);
   // нашли все символы в окне навигации
   int s = find_all_symb();
   check_all_symb();
   
   MakeText("name_site",20,0,"Berk.com");
   Print("Init done");
   return(INIT_SUCCEEDED);

  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()  {
   EventKillTimer() ;
   Comment("");
   delete_objects();
   return(0);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+


void OnTick() {
   string url = StringConcatenate("t=", GetTickCount(),"&date=", (uint)TimeCurrent()); // WebAddress, 
   double lastPrice = 0;
   string smb;
	// runs 1 time after initialization
	// if the number of characters has changed or 1 hour has passed
   if (IsNewBar_d1() || !isinit || total_s != SymbolsTotal(AllSymbols) || NumMissing1 != NumMissing2){
      ArrayResize(symb_arr, SymbolsTotal(AllSymbols), SymbolsTotal(AllSymbols)+5);
      total_s=SymbolsTotal(AllSymbols);
      calculate_d1();
      already_day_calculated = true;
      //Alert("total_s="+total_s+" total="+SymbolsTotal(AllSymbols));
   }
   
   
   // write the last price into an array
   for (int i=0;i<=SymbolsTotal(AllSymbols)-1;i++){
      smb = find_string_symb(i);
      ResetLastError();
      lastPrice = iClose(smb,Period(),0); 
      if(lastPrice > 0) symb_arr[i][4][0] = lastPrice;
      else {
         Print(ERROR, " for SMB=", smb);
         lastPrice = MarketInfo(smb, MODE_BID);
         if(lastPrice > 0) symb_arr[i][4][0] = lastPrice;
      }
   }   
   
   
   
   // check where the price has reached and how the adr has changed relative to PF PFL
   if ((IsNewBar_min() || !isinit) && already_day_calculated){
      
      isinit = true; 
      delete_objects();
      //calculate_d1();
      // + load the last price
       // + update distance from PFH && PFL
       // + display data in the panel
       // counted the maximum characters in height
      int height_row = 20;
      long chart_height = ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
      int max_in_column = (int)MathFloor((chart_height-2*height_row)/height);
      int column = 0;
      int count_in_column = 0;
      
      // count PFH && PFL and display characters in rows and columns
      for (int symbolnumber=0;symbolnumber<=SymbolsTotal(AllSymbols)-1;symbolnumber++){
         string symb = find_string_symb(symbolnumber);// текущий символ по номеру
         Print("Calculating PFH & PFL for: ", symb);
         string distance_from_high = "0.00";
         string distance_from_low = "0.00";
         string status = "X";
         bool find_cycle = false;
         int cycle = 0;
         string dayPF = "0";
         string dayPFL = "0|PFL";
         string dayPFH = "0|PFH";
         int day = 0, dayH = 0, dayL = 0;
         
         datetime dayBarTime, nextDayBarTime, hourBarTime;
         int hourlyBar;
         bool hourBarFound;
            
            // calculated the distance to PFH & PFL by adr
            for (day = 1; day<Days_count;day++){
               // calculated the distance from PFH & PFL to the current price
               double a = NormalizeDouble(calculate_distance(day,symb,symbolnumber,"pfh"),2);
               double b = NormalizeDouble(calculate_distance(day,symb,symbolnumber,"pfl"),2);
               //if(symb=="USDCNH") Print("day="+day+" b="+b);
               // search for the most recent price cycle indicating the day when it happened
               if(a>0 && find_cycle == false) {
                  find_cycle = true;
                  cycle = -1;
                  dayPF = (string)day+"|PFH";
                  dayPFH = (string)day+"|PFH";
                  dayH = day;
               }
               if(b>0 && find_cycle == false) {
                  find_cycle = true;
                  cycle = 1;
                  dayPF = (string)day+"|PFL";
                  dayPFL = (string)day+"|PFL";
                  dayL = day;
               }
               
               if(distance_from_high=="0.00") distance_from_high = DoubleToString(a,2); // send day-day,symb-название символа,symbolnumber-symbolnumber, pfh - from high find distance
               if(distance_from_low=="0.00")  distance_from_low = DoubleToString(b,2); // send day-day,symb-название символа,symbolnumber-symbolnumber, pfh - from high find distance
               // found both distance to PFH & PFL
               if(distance_from_high != "0.00" && distance_from_low != "0.00") break; 
            }
            Print("Making POST");
            url = StringConcatenate(url, "&", symb, "[PFH]=", distance_from_high);
            url = StringConcatenate(url, "&", symb, "[PFL]=", distance_from_low);
            if(cycle < 0) { status = "H"; day = dayH; }
            if(cycle > 0) { status = "L"; day = dayL; }
            url = StringConcatenate(url, "&", symb, "[status]=", status);
            url = StringConcatenate(url, "&", symb, "[difference]=", day);
            hourBarFound = false;
            dayBarTime = iTime(symb, PERIOD_D1, day);
            hourlyBar = -1;
            if(cycle != 0) hourlyBar = iBarShift(symb, PERIOD_H1, dayBarTime, false);
            if(hourlyBar > 0) {
               hourBarTime = iTime(symb, PERIOD_H1, hourlyBar);
               nextDayBarTime =  dayBarTime + 24*3600;
               if(hourBarTime >= dayBarTime && hourBarTime < nextDayBarTime) { // Bar was found in the same day 
                  if(cycle < 0) {
                     hourlyBar = iHighest(symb, PERIOD_H1, MODE_HIGH, hourlyBar, 0);
                     hourBarTime = iTime(symb, PERIOD_H1, hourlyBar); 
                     if(hourBarTime >= dayBarTime && hourBarTime < nextDayBarTime)  hourBarFound = true; // Bar was found in the same day 
                  }
                  if(cycle > 0) {
                     hourlyBar = iLowest(symb, PERIOD_H1, MODE_LOW, hourlyBar, 0);
                     hourBarTime = iTime(symb, PERIOD_H1, hourlyBar); 
                     if(hourBarTime >= dayBarTime && hourBarTime < nextDayBarTime)  hourBarFound = true; // Bar was found in the same day 
                  }
               }
            }
            if(hourBarFound) url = StringConcatenate(url, "&", symb, "[time]=", hourBarTime);
            else url = StringConcatenate(url, "&", symb, "[time]=", dayBarTime);
            
            // url = StringConcatenate(url, "&PFH|", symb, "[", dayPFH, "]=", distance_from_high);
            // url = StringConcatenate(url, "&PFL|", symb, "[", dayPFL, "]=", distance_from_low);
         // рисуем очередной ряд информации
         height_row = height_row + height;
         // верхняя строка - название
         if(count_in_column==0) {
            height_row = 20;
            showlabel("","","",height_row,column,cycle);
            count_in_column++;
            height_row = height_row + height;
         }
         // рисуем значения символа
         if(Show_day_last_PF == true) showlabel(symb+"_"+dayPF,distance_from_high,distance_from_low,height_row,column,cycle);
         else showlabel(symb,distance_from_high,distance_from_low,height_row,column,cycle);
         count_in_column++;
         // рисуем новый столбец
         if(count_in_column==max_in_column) {
            count_in_column = 0;
            column++;
         }
      }  
      // обнулили флаг, чтобы не пересчитывался в течение дня
      already_day_calculated = false;
      // Print(url);
      FilePutContents("test.txt", url);
      // string   webReply =  ReadWebResource(url);
      // Print( webReply, " l=", __LINE__);
      Print(" Sending POST");
      _WebReply webReply = PostTextMy(url, WebAddress);
      Print(" POST was sent");

      check_all_symb();
   }
   MakeText("name_site",20,0,"Berk.com");
   //Comment("symb_arr[2][0][0]="+find_string_symb(symb_arr[2][0][0])+" symb_arr[2][1][1]="+symb_arr[2][1][1]+" symb_arr[2][4][0]="+symb_arr[2][4][0]);
   return;
}  


//+------------------------------------------------------------------+


uint FilePutContents(string fileName, string contents) {
   int h = FileOpen(fileName, FILE_WRITE | FILE_TXT);
   if(h == INVALID_HANDLE) {
      Print(ErrorDescription(GetLastError()), " file = ", __FILE__, " line = ", __LINE__);
      return 0;
   }
   uint bites = FileWriteString(h, contents);
   FileFlush(h);
   FileClose(h);
   return bites;
}
//+------------------------------------------------------------------+



void calculate_d1(){
   double lastPrice;
   string smb;
   ArrayInitialize(symb_arr,EMPTY_VALUE);
      int s_count = find_all_symb();


         
      // We write ADR and PFH && PFL into an array. By levels - 0 - pairs, 1 - days
      for(int symbolnumber = 0;symbolnumber<s_count;symbolnumber++){
         string symb = find_string_symb(symbolnumber);// текущий символ по номеру
         
         for (int day = 1; day<Days_count;day++){
            if(iBars(symb,PERIOD_D1)<30) {
               Alert("There are no history on D1 on "+symb+"! Please open D1 chart on "+symb+" to download near 30 days history");
               break;
            }
            //if ((TimeDayOfWeek(iTime(symb,PERIOD_D1,day))==6 || TimeDayOfWeek(iTime(symb,PERIOD_D1,day))==0) && Correct_sunday==true) continue; // если день недели - суббота или воскресенье - пропускаем  
            
            // put the address in each value of the symb_arr array
            calculate(day,symb,symbolnumber); // send day-day,symb-название символа,symbolnumber-symbolnumber
            // took atr, counted and put it in the pfh && pfl array
            isPFH(day,symb,symbolnumber);
            isPFL(day,symb,symbolnumber);   
         }
      }  
      
      
   // write the last price into an array
   for (int i=0;i<=SymbolsTotal(AllSymbols)-1;i++){
      smb = find_string_symb(i);
      lastPrice = iClose(smb,Period(),0); 
      if(lastPrice > 0) symb_arr[i][4][0] = lastPrice;
      else {
         lastPrice = MarketInfo(smb, MODE_BID);
         if(lastPrice > 0) symb_arr[i][4][0] = lastPrice;
      }
   }  
}


// счет расстояния от текущей цены до PFH&PFL
// input: int day-день старта отсчета,string symb-название символа,int symbolnumber-номер символа , string pfh/pfl - find distance from high|low
double calculate_distance(int day, string symb, int symb_numb, string direction){
   //if(symb=="USDCHF") { 
   double nowadr = symb_arr[symb_numb][1][day];
      if(direction=="pfh"){
         if(symb_arr[symb_numb][2][day]!=EMPTY_VALUE && nowadr!=0){
            // высчитываем отношение разницы хай-текущая цена и делим все на адр - получаем количество адр которая прошла цена
            //Print("pfh="+symb_arr[symb_numb][2][day]+" on bar "+day+" closeprice="+symb_arr[symb_numb][4][0]);
            // если цена прошла больше 1 адр
            if(iHighest(symb,PERIOD_D1,MODE_HIGH,day+1,0)==day){
               if(symb_arr[symb_numb][2][day]>symb_arr[symb_numb][4][0])
               return NormalizeDouble((symb_arr[symb_numb][2][day]-symb_arr[symb_numb][4][0])/nowadr,2); 
            }   
         }
      }
      if(direction=="pfl"){
         if(symb_arr[symb_numb][3][day]!=EMPTY_VALUE && nowadr!=0){
            //if(symb=="NZDUSD") Print("pfl="+NormalizeDouble((symb_arr[symb_numb][4][0]-symb_arr[symb_numb][3][day])/nowadr,2)+" on bar "+day+" closeprice="+symb_arr[symb_numb][4][0]);
            // если цена прошла больше 1 адр
            if(iLowest(symb,PERIOD_D1,MODE_LOW,day+1,0)==day){
               if(symb_arr[symb_numb][4][0]>symb_arr[symb_numb][3][day]) 
               return NormalizeDouble((symb_arr[symb_numb][4][0]-symb_arr[symb_numb][3][day])/nowadr,2);
            }    
         }
      }
   //}
   return 0;
}







// counting and writing adr to an array
void calculate(int day, string symb, int symb_numb){

   //string symb = find_string_symb(symb_numb);
   double point = MarketInfo(symb,MODE_POINT);


   if(Days_period + day > iBars(symb,PERIOD_D1)-1) return; 

   
   double adr = 0;
   double dist = 0;
   int insideholiday = 0;
   
   if(UseADRcalculating && UseATRcalculating==false){
      for(int i=1+day; i<Days_period+1+day; i++){
         if ((TimeDayOfWeek(iTime(symb,PERIOD_D1,i))==6 || TimeDayOfWeek(iTime(symb,PERIOD_D1,i))==0) && Correct_sunday==true) insideholiday++;
      }
   
      for(int i=1+day; i<Days_period+1+day+insideholiday; i++){
         if ((TimeDayOfWeek(iTime(symb,PERIOD_D1,i))==6 || TimeDayOfWeek(iTime(symb,PERIOD_D1,i))==0) && Correct_sunday==true) continue;     
         dist = (iHigh(symb,PERIOD_D1,i) - iLow(symb,PERIOD_D1,i)) + dist; // суммируем все ренжи
      }
      
      adr = dist/Days_period;
      adr = NormalizeDouble(adr, (int)MarketInfo(symb,MODE_DIGITS));
   }
   
   if(UseADRcalculating==false && UseATRcalculating){
      adr = iATR(symb,PERIOD_D1,Days_period,1);
   }   
   // записываем адр в массив
   symb_arr[symb_numb][1][day] = adr;
}





bool IsNewBar_d1()  // проверяет наступил ли новый бар
  {
  static int nBars_day = 0;
  if (nBars_day != iBars(_Symbol,PERIOD_D1))
   {
    nBars_day = iBars(_Symbol,PERIOD_D1);
    return(true);
   }
  return(false);
  
  }      
      
     


bool IsNewBar_min()  // проверяет наступил ли новый бар
  {
  static int nBars_min = 0;
  if (nBars_min != iBars(_Symbol,PERIOD_M1))
   {
    nBars_min = iBars(_Symbol,PERIOD_M1);
    return(true);
   }
  return(false);
  
  }




void showlabel(string symb,string distance_from_high,string distance_from_low,int height_row, int column, int cycle){
    
   color clrBack = clrWhite;
   color clrFontH = clrSteelBlue;
   color clrFontL = clrSteelBlue;
   color clrBorderH = clrSteelBlue;
   color clrBorderL = clrSteelBlue;
   // код смещения столбцов 1 столбец 
   int width_add = 0;
   if(column==1) {
      width_add = (int)(3.5*width);
   }
   // код смещения столбцов 2 столбец
   if(column==2) {
      width_add = 7*width;
   }
   // код смещения столбцов 3 столбец
   if(column==3) {
      width_add = (int)(10.5*width);
   }
   // код смещения столбцов 4 столбец
   if(column==4) {
      width_add = 14*width;
   }
   // код смещения столбцов 5 столбец
   if(column==5) {
      width_add = (int)(17.5*width);
   }
   // код смещения столбцов 6 столбец
   if(column==6) {
      width_add = 21*width;
   }
   
   if(symb=="") {
      clrBack = clrSteelBlue;
      clrFontH = clrWhite;
      clrFontL = clrWhite;
      EditCreate(0,symb+(string)column+"_0",0,20+width*0+width_add,height_row,width,20,0,"","Arial",font_size,ALIGN_CENTER,true,clrWhite,clrSteelBlue,clrSteelBlue,false,false,true,0); 
      EditCreate(0,symb+(string)column+"_1",0,20+width*1+width_add,height_row,width,20,0,"PFH","Arial",font_size,ALIGN_CENTER,true,clrFontH,clrBack,clrBorderH,false,false,true,0); 
      EditCreate(0,symb+(string)column+"_2",0,20+width*2+width_add,height_row,width,20,0,"PFL","Arial",font_size,ALIGN_CENTER,true,clrFontL,clrBack,clrBorderL,false,false,true,0); 
   }
   if(StrToDouble(distance_from_high)>=3 && cycle==-1) {
      clrBorderH = clrRed;
      clrFontH = clrRed;
   }
   if(StrToDouble(distance_from_low)>=3 && cycle==1) {
      clrBorderL = clrRed;
      clrFontL = clrRed;
   }
   EditCreate(0,symb+(string)column+"_0",0,20+width*0+width_add,height_row,width,20,0,symb,"Arial",font_size,ALIGN_CENTER,true,clrWhite,clrSteelBlue,clrSteelBlue,false,false,true,0); 
   EditCreate(0,symb+(string)column+"_1",0,20+width*1+width_add,height_row,width,20,0,distance_from_high+" x ADR","Arial",font_size,ALIGN_CENTER,true,clrFontH,clrBack,clrBorderH,false,false,true,0); 
   EditCreate(0,symb+(string)column+"_2",0,20+width*2+width_add,height_row,width,20,0,distance_from_low+" x ADR","Arial",font_size,ALIGN_CENTER,true,clrFontL,clrBack,clrBorderL,false,false,true,0); 
     
   
}





//+------------------------------------------------------------------+
//| Function create object text                                      |
//+------------------------------------------------------------------+
bool EditCreate(const long             chart_ID=0,
                const string           name="Edit",
                const int              sub_window=0,
                const long             x=0,
                const long             y=0,
                const int              width_=50,
                const int              height_=18,
                const ENUM_BASE_CORNER corner=CORNER_LEFT_UPPER,
                const string           text="Text",
                const string           font="Arial",
                const int              fontSize=10,
                const ENUM_ALIGN_MODE  align=ALIGN_CENTER,
                const bool             read_only=false,
                const color            clr=clrWhite,
                const color            back_clr=clrWhite,
                const color            border_clr=clrSteelBlue,
                const bool             back=false,
                const bool             selection=false,
                const bool             hidden=true,
                const long             z_order=0)
  {

   ResetLastError();

   if(!ObjectCreate(chart_ID,name,OBJ_EDIT,sub_window,0,0))
     {
      return(false);
     }

   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width_);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height_);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(chart_ID,name,OBJPROP_ALIGN,align);
   ObjectSetInteger(chart_ID,name,OBJPROP_READONLY,read_only);
   ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BORDER_COLOR,border_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,false);
   // ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
   //ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
   return(true);
  }


bool MakeText( string n, int xoff, int yoff, string text )
   {
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0 );
      ObjectSetInteger(0, n, OBJPROP_CORNER, 0 );
      ObjectSetInteger(0, n, OBJPROP_XDISTANCE, xoff );
      ObjectSetInteger(0, n, OBJPROP_YDISTANCE, yoff );
      ObjectSetInteger(0, n, OBJPROP_BACK, false );
      ObjectSetString(0,n,OBJPROP_TEXT,text); 
      ObjectSetInteger(0,n,OBJPROP_COLOR,clrSteelBlue);
      return (true);
   } 


// проверка является ли бар pfh - должна цена быть меньше adr на момент данного дня. 2 варианта - пробитие адр 1 свечой или несколько свечей пока не пробьем адр
void isPFH(int day, string symb, int symb_numb){
   double nowadr = symb_arr[symb_numb][1][day];
   double adr_goal = NormalizeDouble(iHigh(symb,PERIOD_D1,day)-nowadr, (int)MarketInfo(symb,MODE_DIGITS));
   // если возврат 1 свечой
   if(iClose(symb,PERIOD_D1,day) < adr_goal && iHigh(symb,PERIOD_D1,day)>iHigh(symb,PERIOD_D1,day+1)  && iHigh(symb,PERIOD_D1,day)>iHigh(symb,PERIOD_D1,day+2)){
      // текущий день - PFH
      //bufferPFH[day] = -1;
      symb_arr[symb_numb][2][day] = iHigh(symb,PERIOD_D1,day);
      return;
   }
   // если возврат несколькими свечами - нужно чтобы это была вершинка на адр больше до и после нее
   if(iClose(symb,PERIOD_D1,day)>adr_goal){
            // сначала отсчитываем назад
            for(int i=day;i<day+5;i++){
               if(iOpen(symb,PERIOD_D1,i)>adr_goal) continue;
               if(iOpen(symb,PERIOD_D1,i)<=adr_goal){
                  // если перебили адр и самая высокая точка - текущий день
                  if(iHighest(symb,PERIOD_D1,MODE_HIGH,i-day+1,day)==day){
                     //bufferPFH[day] = 1;
                     // идем вперед на 5 свечей ожидая пробития адр
                     for(int f = day;f>day-10;f--){
                        if(f<1) return;
                        if(iClose(symb,PERIOD_D1,f)>adr_goal) continue;
                        if(iClose(symb,PERIOD_D1,f)<=adr_goal) {
                           if(iHighest(symb,PERIOD_D1,MODE_HIGH,day-f+1,f)==day){
                              // текущий день - PFH
                              //bufferPFH[day] = -1;
                              symb_arr[symb_numb][2][day] = iHigh(symb,PERIOD_D1,day);
                              return;
                           }
                        }
                     }
                     return;
                  }
                  else return;
               }
            }
   }
}


         
void isPFL(int day, string symb, int symb_numb){
   double nowadr = symb_arr[symb_numb][1][day];
   
   double adr_goal = NormalizeDouble(iLow(symb,PERIOD_D1,day)+nowadr, (int)MarketInfo(symb,MODE_DIGITS));
   
   // если возврат 1 свечой
   if(iClose(symb,PERIOD_D1,day) > adr_goal && iLow(symb,PERIOD_D1,day)<iLow(symb,PERIOD_D1,day+1) && iLow(symb,PERIOD_D1,day)<iLow(symb,PERIOD_D1,day+2)){
      //if(symb=="USDCNH") Print("day="+day+" adr_goal="+adr_goal+" iClose(symb,PERIOD_D1,day)="+iClose(symb,PERIOD_D1,day));
      // текущий день - PFH
      //bufferPFL[day] = 1;
      symb_arr[symb_numb][3][day] = iLow(symb,PERIOD_D1,day);
      return;
   }
   // если возврат несколькими свечами - нужно чтобы это была вершинка на адр больше до и после нее
   if(iClose(symb,PERIOD_D1,day) < adr_goal){
            // сначала отсчитываем назад
            for(int i=day;i<day+5;i++){
               if(iOpen(symb,PERIOD_D1,i)<adr_goal) continue;
               if(iOpen(symb,PERIOD_D1,i)>=adr_goal){
                  // если перебили адр и самая высокая точка - текущий день
                  if(iLowest(symb,PERIOD_D1,MODE_LOW,i-day+1,day)==day){
                     // идем вперед на 5 свечей ожидая пробития адр
                     for(int f = day;f>day-10;f--){
                        if(f<1) return;
                        if(iClose(symb,PERIOD_D1,f)<adr_goal) continue;
                        if(iClose(symb,PERIOD_D1,f)>=adr_goal) {
                           if(iLowest(symb,PERIOD_D1,MODE_LOW,day-f+1,f)==day){
                              // текущий день - PFH
                              //bufferPFL[day] = 1;
                              symb_arr[symb_numb][3][day] = iLow(symb,PERIOD_D1,day);
                              return;
                           }
                        }
                     }
                     return;
                  }
                  else return;
               }
            }
   }

}


// выбор всех объектов и засовывание их в массив symb_arr и возврат их числа
int find_all_symb(){
   int total = SymbolsTotal(AllSymbols);
   ArrayResize(symb_arr,total,total+5);
   // проходим по всем символам
   for (int i=0;i<=total-1;i++){
      symb_arr[i][0][0] = i; 
   }
   return total;
}

void check_all_symb(){
   int total = SymbolsTotal(AllSymbols);
   string smb;
   int h1Bars = 50*24;
   // go through all the symbols
   for (int i=0;i<=total-1;i++){
      smb = find_string_symb(i);
      Print(" Check D1 Symbols: ", smb);
      if(iTime(smb, PERIOD_D1, 50) == 0) Sleep(SLEEP); 
      Print(" Check H1 Symbols: ", smb);
      if(iTime(smb, PERIOD_H1, h1Bars) == 0) Sleep(SLEEP); 
   }
   return;
}


// получить номер символа по его названию
int find_number_symb(string nameSymb){
   int total = SymbolsTotal(AllSymbols);
   int number = -1;
   // проходим по всем символам
   for (int i=0;i<=total-1;i++){
      if(SymbolName(i,AllSymbols)==nameSymb) {
         number = i;
         break;
      } 
   }

   return number;
}


// получить название символа по его номеру
string find_string_symb(int number){
   return SymbolName(number,AllSymbols);
}



// удаление объектов
void delete_objects(){
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, 0);
   for(int i=ObjectsTotal()-1;i>=0;i--){
      string name=ObjectName(i);
      ObjectDelete(name);
   }
   ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, 1);
}






int licensing(string email,int acc_num){ // функция проверки лицензии на советник. Одним запросом скидывается текущий регистрационный email если он не равен "" и номер счета
   string result = SendServer(email,acc_num);
   return (int)StringToInteger(result);
}



string SendServer(string email, int acc_num){  
     string Head="Content-Type: application/x-www-form-urlencoded"; // header
     string Path="/licensing/getsignal.php"; // path to the page
     string str="hash=q123456789&";
      str+="email="+email+"&";
      str+="account="+(string)acc_num;
   
     tagRequest req; // initialization of parameters - т.к. слишком много параметров передается в функцию Request
     req.Init("GET", Path+"?"+str, Head, "",   false, "", false); // инициализировали запрос
     
     
     
     if (!INet.Request(req)) Print("-err Request line=", __LINE__); // отправили запрос на сервер
   
return req.stOut;
}

string SendServerOnline(string email){  
     string Head="Content-Type: application/x-www-form-urlencoded"; // header
     string Path="/licensing/online.php"; // path to the page
     string str="hash=q123456789&";
      str+="email="+email;

     tagRequest req; // initialization of parameters - т.к. слишком много параметров передается в функцию Request
     req.Init("GET", Path+"?"+str, Head, "",   false, "", false); // инициализировали запрос
     
     
     
     if (!INet.Request(req)) Print("-err Request line=", __LINE__); // отправили запрос на сервер
   
return req.stOut;
}





string read_email_from_file(){
   string res = "";
   int file_descriptor = FileOpen(file_key, FILE_TXT|FILE_READ);
   if (file_descriptor > 0) {
      res = FileReadString(file_descriptor); // прочитали строчку
   }
   FileClose(file_descriptor);    
   return res;
}


void record_email_to_file(string text){ // пишем сюда номер счета и email
   int file_descriptor = FileOpen(file_key, FILE_TXT|FILE_WRITE);
   if (file_descriptor > 0) { 
      FileDelete(file_key);      
      if(text!=""){
         FileWrite(file_descriptor,text);
      }
   }
   FileClose(file_descriptor); 
}


void delete_license_file(){ // пишем сюда номер счета и email
   int file_descriptor = FileOpen(file_key, FILE_TXT|FILE_WRITE);
   if (file_descriptor > 0) { 
      FileDelete(file_key);      
   }
   FileClose(file_descriptor); 
}


int CheckMissing() {
   int i;
   string smb;
   int missing1[], numMissing1=0;
   int missing2[], numMissing2=0;
   datetime t, currentDayTime = iTime(_Symbol, PERIOD_D1, 0);
   total_s = SymbolsTotal(AllSymbols);
   for(i=0; i<total_s; i++) {
      smb = SymbolName(i, AllSymbols);
      Print("Initial check up for: ", smb);
      t = iTime(smb, PERIOD_D1, Days_count+1);
      if(t == 0 || MathAbs(iTime(smb, PERIOD_D1, 0)- currentDayTime) > 3600*24) {
         if(ArraySize(missing1) <= numMissing1 + 1) {
            ArrayResize(missing1, numMissing1 + 1);
         }
         missing1[numMissing1] = i;
         numMissing1++;
         Sleep(SLEEP);
      }
   }
   for(i=0; i<numMissing1; i++) {
      smb = SymbolName(i, AllSymbols);
      t = iTime(smb, PERIOD_D1, Days_count+1);
      if(t == 0 || MathAbs(iTime(smb, PERIOD_D1, 0)- currentDayTime) > 3600*24) {
         if(ArraySize(missing2) <= numMissing2 + 1) {
            ArrayResize(missing2, numMissing2 + 1);
         }
         missing2[numMissing2] = i;
         numMissing2++;
         Sleep(SLEEP);
      }
   }   
   return numMissing2;
}

int CheckMissing(const string& inpArray[], string& outArray[], int inpNum) {
   int i, numMissing=0;
   string smb;
   datetime t, currentDayTime = iTime(_Symbol, PERIOD_D1, 0);
   ArrayResize(outArray, 0);
   for(i=0; i<inpNum; i++) {
      smb = inpArray[i];
      t = iTime(smb, PERIOD_D1, Days_count+1);
      if(t == 0 || MathAbs(iTime(smb, PERIOD_D1, 0)- currentDayTime) > 3600*24) {
         if(ArraySize(outArray) <= numMissing + 1) {
            ArrayResize(outArray, numMissing + 1);
         }
         outArray[numMissing] = smb;
         numMissing++;
         Sleep(SLEEP);
      }
   }
   return numMissing;
}

