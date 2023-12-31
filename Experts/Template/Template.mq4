#property description "Template to build your own EA"
#property copyright "Copyright 2023, Pin8 Software Unlimited"
#property version   "1.00"
#property strict

#include <Arrays\ArrayInt.mqh>
#include <Pin8\OrderFactory.mqh>

//--- Parametros del EA
input RISK_MANAGEMENT   riskManagement  = 0;    // 0:FIXED or 1:DYNAMIC
input double            riskMargin      = 0.1;  // Free margin at risk
input int               risk            = 1;    // Order risk
input int               signature       = 1218; // Magic number
input int               periodRSI       = 15;   // Period for RSI
input int               periodEMA       = 15;   // Period for EMA

//--- Globals
datetime        timeMark   = 0;
OrderFactory*   of;

int OnInit()
{
    int retval = INIT_SUCCEEDED;

    of = new OrderFactory(signature, riskManagement, riskMargin);

    return retval;
}
  
void OnDeinit(const int reason)
{
    delete of;
}

void OnTick()
{
    MqlTick tick;

    // Get actual tick
    if(!SymbolInfoTick(Symbol(), tick))
        return;

    // If this is not the first tick of the candle ... OUT
    if (TimeCurrent() <= timeMark)
        return;
    
    // Here is the first tick of the candle
    timeMark = TimeCurrent();

    ///////////////
    // Protection
    ///////////////
    
    // If there is any position opened by this EA .. Evaluate each to maintain or close
    int cont = 0;
    CArrayInt* trade = new CArrayInt();
    trade.Resize(OrdersTotal());
    for (int pos = of.FirstPosition(signature); pos != -1; pos = of.NextPosition(signature, pos))
    {
        if (ShouldBeClosed(pos))
        {
            trade.Add(pos);
            cont++;
        }    
    }
    
    // Close the selected Orders
    for (int i=0; i<cont; i++)
        of.Close(trade.At(i));
    
    delete trade;
    
    ///////////////
    // Action
    ///////////////
    
    // If there is any chance to BUY or SELL ... DO IT
    if (ShouldBuy())
    {
        of.Buy(risk);
    }
    
    if (ShouldSell())
    {
        of.Sell(risk);
    }
}

// Logic for open and close
bool ShouldBeClosed(int _pos)
{
    bool retval = false;
    
    if (OrderSelect(_pos, SELECT_BY_POS, MODE_TRADES))
    {
        double ema1 = iMA(NULL, PERIOD_CURRENT, periodEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
        double ema2 = iMA(NULL, PERIOD_CURRENT, periodEMA, 0, MODE_EMA, PRICE_CLOSE, 2);
        double rsi = iRSI(NULL, PERIOD_CURRENT*2, periodRSI, PRICE_CLOSE, 1);
        
        switch (OrderType())
        {
            case OP_BUY:
            {
                if (Close[1] < ema1 && Close[2] > ema2 && rsi < 50)
                    retval = true;
                    
                break;
            }
            
            case OP_SELL:
            {
                if (Close[1] > ema1 && Close[2] < ema2 && rsi > 50)
                    retval = true;
                    
                break;
            }
        }
    }
    
    return retval;
}

bool ShouldBuy(void)
{
    bool retval = false;
    double rsi1 = iRSI(NULL, PERIOD_CURRENT*2, periodRSI, PRICE_CLOSE, 1);
    double rsi2 = iRSI(NULL, PERIOD_CURRENT*2, periodRSI, PRICE_CLOSE, 2);
    double ema = iMA(NULL, PERIOD_CURRENT, periodEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
    
    if (rsi1>30 && rsi2<30 && Close[1] < ema)
        retval = true;
    
    return retval;
}

bool ShouldSell(void)
{
    bool retval = false;
    double rsi1 = iRSI(NULL, PERIOD_CURRENT*2, periodRSI, PRICE_CLOSE, 1);
    double rsi2 = iRSI(NULL, PERIOD_CURRENT*2, periodRSI, PRICE_CLOSE, 2);
    double ema = iMA(NULL, PERIOD_CURRENT, periodEMA, 0, MODE_EMA, PRICE_CLOSE, 1);
    
    if (rsi1<70 && rsi2>70 && Close[1] > ema)
        retval = true;
    
    return retval;
}