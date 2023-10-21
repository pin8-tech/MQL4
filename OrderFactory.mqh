#property copyright "Copyright 2023, Pin8 Software Unlimited"
#property strict

class OrderFactory
{
private:
    int riskManagement;         // 0 - Fixed risk, 1 - Dynamic risk (Free margin)
    double riskPercent;
    int signature;
    double lotMin;

    double oldcalculateVolume(int _risk, int _opType, double _price)
    {
        double initialFreeMargin = MarketInfo(NULL, MODE_MARGINREQUIRED);
        double marginInit = MarketInfo(NULL, MODE_MARGININIT);
        double riskedMoney = initialFreeMargin * (riskPercent/100);
        double lotSize = MarketInfo(NULL, MODE_LOTSIZE);
        double lotCost = lotSize * (_opType == OP_BUY) ? Ask : (_opType == OP_SELL) ? Bid : _price;
        
        double retval = (riskManagement == 0) ? _risk * lotMin : _risk * riskedMoney / lotCost;
        
        return NormalizeDouble(retval, 2);
    }
    
    double calculateVolume(int _risk)
    {
        double lotSize = MarketInfo(NULL, MODE_LOTSIZE);
        double minLots = MarketInfo(NULL, MODE_MINLOT);
        double money = AccountFreeMargin();
        double leverage = AccountLeverage();
        double riskAmount = money * _risk * riskPercent / 100;
        double tickValue = MarketInfo(NULL, MODE_MARGINREQUIRED) / MarketInfo(NULL, MODE_MARGININIT);
        double pointValue = MarketInfo(NULL, MODE_POINT);

        double pipValue = tickValue / pointValue;
        double lotSizeForRisk = riskAmount / pipValue;
        
        lotSizeForRisk = MathFloor(lotSizeForRisk / minLots) * minLots;
        
        return lotSizeForRisk;
    }

public:
    OrderFactory(int _signature, int _riskManagement, double _riskPercent)
    {
        riskManagement = _riskManagement;
        riskPercent = _riskPercent;
        signature = _signature;
        lotMin = SymbolInfoDouble(NULL, SYMBOL_VOLUME_MIN);
    }
    
    ~OrderFactory(void)
    {
    }
    
    int Buy(int _risk)
    {
        double lot = calculateVolume(_risk);
        
        int retval = OrderSend(NULL, OP_BUY, lot, Ask, 5, 0, 0, "", signature);

        return retval;
    }

    int Sell(int _risk)
    {
        double lot = calculateVolume(_risk);
        
        int retval = OrderSend(NULL, OP_SELL, lot, Bid, 5, 0, 0, "", signature);

        return retval;
    }
    
    int BuyAt(double _price, int _risk)
    {
        double lot = calculateVolume(_risk);
        int typeOfOrder = (_price < Ask) ? OP_BUYLIMIT : OP_BUYSTOP;
        int retval = OrderSend(NULL, typeOfOrder, lot, _price, 5, 0, 0, "", signature);

        return retval;
    }

    int SellAt(double _price, int _risk)
    {
        double lot = calculateVolume(_risk);
        int typeOfOrder = (_price > Bid) ? OP_SELLLIMIT : OP_SELLSTOP;
        int retval = OrderSend(NULL, typeOfOrder, lot, _price, 5, 0, 0, "", signature);

        return retval;
    }
    
    bool Close(int index, double _ratio = 1)
    {
        bool retval = false;
        
        if (OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
            retval = OrderClose(OrderTicket(), _ratio * OrderLots(), (OrderType()==OP_BUY ? Bid : Ask), 5);
        
        return retval;
    }
    
    int FirstPosition(void)
    {
        int i = 0;
        int retval = -1;
        int orders = OrdersTotal();
        
        do
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == signature)
                retval = i;
        } 
        while(retval < 0 && i < orders);
        
        return retval;
    }
    
    int NextPosition(int i)
    {
        int retval = -1;
        int orders = OrdersTotal();

        i++;        
        do
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == signature)
                retval = i;
        } 
        while(retval < 0 && i < orders);
        
        return retval;
    }
    
    void Test(int _risk, int _opType, double _price = 0)
    {
        PrintFormat("Lote : %G", oldcalculateVolume(_risk, _opType, _price));
    }
};