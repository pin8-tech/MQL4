//+------------------------------------------------------------------+
//|                                                     Template.mq4 |
//|                                  Copyright 2023, Pin8 Software   |
//+------------------------------------------------------------------+

#property copyright "Copyright 2023, Pin8 Software"
#property version   "1.00"
#property strict

#include "Posicion.mqh"

//--- Parametros del EA
input double    riesgo      = 1.0;  // Riesgo [Lote = riesgo * MinLot(SYMBOL)]
input ulong     firma       = 1218; // Marca de posicion
input int       RSI_Periodo = 15;   // Horizonte para RSI
input int       EMA_Periodo = 15;   // Horizonte para EMA

//--- Variables globales
datetime    marca   = 0;
Posicion*   p;

//+------------------------------------------------------------------+
//| Al cargar el EA
//+------------------------------------------------------------------+
int OnInit()
{
    int retval = INIT_SUCCEEDED;

    p = new Posicion(firma);

    return retval;
}
  
//+------------------------------------------------------------------+
//| Al cerrar el EA                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    delete p;
}

//+------------------------------------------------------------------+
//| En cada tick
//+------------------------------------------------------------------+
void OnTick()
{
    MqlTick tick;

    // Recuperamos el tick actual
    if(!SymbolInfoTick(Symbol(), tick))
        return;

    // Si no es el 1º tick de la vela ... terminamos, en caso contrario actualizamos y seguimos
    if (TimeCurrent() <= marca)
        return;
    else
        marca = TimeCurrent();
        
    // NOTA : En el 1º tick de la vela ... Open[0] = High[0] = Low[0] y no hay Close[0]
    
    // Si hay una posicion abierta
    if (p.Running())
    {
        // Analisis defensivo
        switch (analisisDefensivo(p))
        {
            case -1:
            {
                break;
            }
            case 0:
            {
                break;
            }
            case 1:
            {
                break;
            }
        };
    }
}

double pendiente(double x1, double y1, double x2, double y2)
{
    double incx = Bars(NULL, PERIOD_CURRENT, x2, x1);
    double incy = (y2 - y1) / _Point;
    
    return incy / incx;
}

//--- -1 para cerrar la posicion, 0 mantener y 1 reforzarla
//-------------------------------------------------
int analisisDefensivo(Posicion& _p)
{
    int retval = 0;
    double rsi_1=iRSI(NULL, PERIOD_CURRENT, RSI_Periodo, PRICE_MEDIAN, 1);
    double rsi_2=iRSI(NULL, PERIOD_CURRENT, RSI_Periodo, PRICE_MEDIAN, 2);
    double rsi_3=iRSI(NULL, PERIOD_CURRENT, RSI_Periodo, PRICE_MEDIAN, 3);
    double ema_h1=iMA(NULL, PERIOD_CURRENT, EMA_Periodo, 0, MODE_EMA, PRICE_HIGH, 1);
    double ema_l1=iMA(NULL, PERIOD_CURRENT, EMA_Periodo, 0, MODE_EMA, PRICE_LOW, 1);
    
    switch (p.type)
    {
        case OP_BUY:
        {
            if ((rsi_1 < 70 && rsi_2>70 && rsi_3>70) || (Open[0] < ema_h1))
                retval = -1;
                
            break;
        }
        
        case OP_SELL:
        {
            if ((rsi_1 > 30 && rsi_2 < 30 && rsi_3 < 30) || (Open[0] > ema_l1))
                retval = -1;

            break;
        }
    };
    
    return retval;
}