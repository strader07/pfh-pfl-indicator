//+------------------------------------------------------------------+
//|                                                       adr x2.mq4 |
//|                         Andrew Malahov, http://blog.in-vesto.ru/ |
//|                                         http://blog.in-vesto.ru/ |
//+------------------------------------------------------------------+
#property copyright "Andrew Malahov, http://blog.in-vesto.ru/"
#property link      "http://x2.in-vesto.ru/"
#property version   "1.13"
#property description "Adr_x2 - shows potential Take Profit levels in intraday trading with\n\ra very high probability that the price will be at there levels\n\r\n\rLast day TP levels could be redrawn so you need to control you current Take Profit"
#property strict
#property indicator_buffers 5
#property indicator_chart_window



extern int Days_count = 10;

extern int Days_period = 5; // для ADR
int Atr_1 = 15;
int Atr_2 = 8;
int Atr_3 = 21;
int Atr_4 = 33;
extern double Delta = 2; // min level width

extern color ADR_clr = clrBlue;
extern color ADR_clr_1 = clrRed;

double ADR[];
double ATR1[];
double ATR2[];
double ATR3[];
double ATR4[];

int count1=0;
int count2=0;
int count3=0;
int count4=0;
int count5=0;
string adr_text;

  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
void start()
{

   if (IsNewBar()==1){
      count1=0;
      count2=0;
      count3=0;
      count4=0;
      count5=0;
      
      //MqlDateTime str1;
      //TimeToStruct(iTime(0,Period(),0),str1);
      //printf("%02d.%02d.%4d",str1.day,str1.mon,str1.year);
      
      ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, 0);
      for(int i=ObjectsTotal()-1;i>=0;i--){ // удаляем все прямоугольники - чтобы переписать их
         string name=ObjectName(i);
         if(StringFind(name,"highadr"+Days_period)!=-1 || StringFind(name,"lowadr"+Days_period)!=-1) ObjectDelete(name);
      }
      ChartSetInteger(0, CHART_EVENT_OBJECT_DELETE, 1);
      
      for (int x = 0; x<Days_count;x++){
         if (TimeDayOfWeek(iTime(0,PERIOD_D1,x))==6 || TimeDayOfWeek(iTime(0,PERIOD_D1,x))==0) {
            continue; // если день недели - суббота или воскресенье - пропускаем  
         }
         adr_calculate(x);
         //count_percent_goals(x);
      }
      
      show_counted_results();
   }
}


void adr_calculate(int day){
/*
Алгоритм работы
+ за каждый день делаем все просчеты и заполняем соответствующие массивы буферов
+ за каждый день рисуем прямоугольники шириной 1 пункт на тех уровнях, где были рассчитаны тейки
- за каждый день, где цена коснулась/была выше/ниже прямоугольника - добавляем +1 к тому или иному значению. В итоге после просчета всех значений должно быть 
количество дней, в скольких цена коснулась уровня и % достижения цели

*/

double atr1=0;
double atr2=0;
double atr3=0;
double atr4=0;
double today=0;

int number_bar_this_timeframe=0;
int number_bar_this_timeframe_next_day=0;





   if(Days_period + day > iBars(0,PERIOD_D1)-1) return;
   //if (TimeDayOfWeek(iTime(0,PERIOD_D1,day))==6 || TimeDayOfWeek(iTime(0,PERIOD_D1,day))==0) return; // если день недели - суббота или воскресенье - пропускаем
   
   double adr = 0;
   double dist = 0;
   today = 0;
   int insideholiday = 0;
   
   
   for(int i=1+day; i<Days_period+1+day; i++){
      if (TimeDayOfWeek(iTime(0,PERIOD_D1,i))==6 || TimeDayOfWeek(iTime(0,PERIOD_D1,i))==0) insideholiday++;   
   }

   for(int i=1+day; i<Days_period+1+day+insideholiday; i++){
      if (TimeDayOfWeek(iTime(0,PERIOD_D1,i))==6 || TimeDayOfWeek(iTime(0,PERIOD_D1,i))==0) continue;
      //Print("По паре "+Symbol()+" на баре "+i+" значение ширины ренжа "+(iHigh(0,PERIOD_D1,i) - iLow(0,PERIOD_D1,i)));     
      dist = (iHigh(0,PERIOD_D1,i) - iLow(0,PERIOD_D1,i)) + dist; // суммируем все ренжи
      
   }

   //Alert("По паре "+Symbol()+" на баре "+day+" значение ширины ренжа суммарно "+dist);

         adr = dist/Days_period;
         adr = NormalizeDouble(adr/Point,0);

   
   //Print("Adr="+adr);
   
   today = iHigh(0,PERIOD_D1,day) - iLow(0,PERIOD_D1,day);
   today = NormalizeDouble(today/Point,0);
   int todaysl = NormalizeDouble(today/3,0);
   if (day==0) adr_text = " ADR= "+adr+" today= "+today+" max SL= "+todaysl;
   
   atr1 = NormalizeDouble(iATR(0,PERIOD_D1,Atr_1,day+1)/Point,0);
   atr2 = NormalizeDouble(iATR(0,PERIOD_D1,Atr_2,day+1)/Point,0);
   atr3 = NormalizeDouble(iATR(0,PERIOD_D1,Atr_3,day+1)/Point,0);
   atr4 = NormalizeDouble(iATR(0,PERIOD_D1,Atr_4,day+1)/Point,0);
   
   
   
   number_bar_this_timeframe = iBarShift(0,Period(),iTime(0,PERIOD_D1,day)); // получили номер бара для дневного бара day
   number_bar_this_timeframe_next_day = iBarShift(0,Period(),iTime(0,PERIOD_D1,day-1)); // получили номер бара для дневного бара day
   if (day==0) number_bar_this_timeframe_next_day = 0;
   
   
   // определили верх/низ текущего дня, от них уже будем дальше плясать
   double high = iHigh(0,PERIOD_D1,day);
   double low = iLow(0,PERIOD_D1,day);
   
   double highadr = low + NormalizeDouble(adr*Point,Digits); 
   double lowadr = high - NormalizeDouble(adr*Point,Digits); 
   
   //paintSellSquare(number_bar_this_timeframe,number_bar_this_timeframe_next_day,highadr,highadr+Delta*Point(),ADR_clr,"highadr"+Days_period);
   //paintBuySquare(number_bar_this_timeframe,number_bar_this_timeframe_next_day,lowadr,lowadr-Delta*Point(),ADR_clr_1,"lowadr"+Days_period);

   //Print("number_bar_this_timeframe="+number_bar_this_timeframe+" number_bar_this_timeframe_next_day="+number_bar_this_timeframe_next_day);
   for (int n = number_bar_this_timeframe; n > number_bar_this_timeframe_next_day; n--){ // до тех пор пока бар начала дня больше текущего бара - присваиваем одинаковые значения
   // проставляем все значения в буфера
      // здесь значения ширины канала
      ADR[n] = adr;
      ATR1[n] = atr1;
      ATR2[n] = atr2;
      ATR3[n] = atr3;  
      ATR4[n] = atr4;            
   }
}


void count_percent_goals(int day){
   if (ADR[day]>0 && ADR[day]!= EMPTY && ADR[day]!= EMPTY_VALUE && ADR[day]>NormalizeDouble(MathAbs(iHigh(0,PERIOD_D1,day)-iLow(0,PERIOD_D1,day))/Point(),0)) count1++;
   if (ATR1[day]>0 && ATR1[day]!= EMPTY && ATR1[day]!= EMPTY_VALUE && ATR1[day]>NormalizeDouble(MathAbs(iHigh(0,PERIOD_D1,day)-iLow(0,PERIOD_D1,day))/Point(),0)) count2++;
   if (ATR2[day]>0 && ATR2[day]!= EMPTY && ATR2[day]!= EMPTY_VALUE && ATR2[day]>NormalizeDouble(MathAbs(iHigh(0,PERIOD_D1,day)-iLow(0,PERIOD_D1,day))/Point(),0)) count3++;
   if (ATR3[day]>0 && ATR3[day]!= EMPTY && ATR3[day]!= EMPTY_VALUE && ATR3[day]>NormalizeDouble(MathAbs(iHigh(0,PERIOD_D1,day)-iLow(0,PERIOD_D1,day))/Point(),0)) count4++;
   if (ATR4[day]>0 && ATR4[day]!= EMPTY && ATR4[day]!= EMPTY_VALUE && ATR4[day]>NormalizeDouble(MathAbs(iHigh(0,PERIOD_D1,day)-iLow(0,PERIOD_D1,day))/Point(),0)) count5++;
}

      
void show_counted_results(){ // показываем посчитанные данные
//Print(" count1"+count1+" count2"+count2+" count3"+count3+" count4"+count4+" count5"+count5);
   double c1 = NormalizeDouble(100*count1/Days_count,0);
   double c2 = NormalizeDouble(100*count2/Days_count,0);
   double c3 = NormalizeDouble(100*count3/Days_count,0);
   double c4 = NormalizeDouble(100*count4/Days_count,0);
   double c5 = NormalizeDouble(100*count5/Days_count,0);


   Comment ("ADR="+c1+adr_text+"\n\r"+
            "ATR5="+c2+"\n\r"+
            "ATR8="+c3+"\n\r"+
            "ATR21="+c4+"\n\r"+
            "ATR33="+c5+"\n\r"
   );

}
