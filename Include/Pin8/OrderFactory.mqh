#property copyright "Copyright 2023, Pin8 Software Unlimited"
#property strict

enum RISK_MANAGEMENT
{
    FIXED_RISK, DYNAMIC_RISK
};

class OrderFactory
{
private:
    RISK_MANAGEMENT riskManagement;
    double riskUnit;
    int signature;
    double lotMin;

public:
    OrderFactory(int _signature, RISK_MANAGEMENT _riskManagement, double _riskPercent)
    {
        riskManagement = _riskManagement;
        riskUnit = _riskPercent/100;
        signature = _signature;
        lotMin = SymbolInfoDouble(NULL, SYMBOL_VOLUME_MIN);
    }
    
    ~OrderFactory(void)
    {
    }
    
    int Buy(int _risk, int _mark=0)
    {
        double lot = (riskManagement == 0) ? _risk * lotMin : _risk * DynamicVolume();
        int retval = OrderSend(NULL, OP_BUY, lot, Ask, 5, 0, 0, "", signature*100+(_mark%100));

        return retval;
    }

    int Sell(int _risk, int _mark=0)
    {
        double lot = (riskManagement == 0) ? _risk * lotMin : _risk * DynamicVolume();
        int retval = OrderSend(NULL, OP_SELL, lot, Bid, 5, 0, 0, "", signature*100+(_mark%100));

        return retval;
    }
    
    int BuyAt(double _price, int _risk, int _mark=0)
    {
        double lot = (riskManagement == 0) ? _risk * lotMin : _risk * DynamicVolume();
        int typeOfOrder = (_price < Ask) ? OP_BUYLIMIT : OP_BUYSTOP;
        int retval = OrderSend(NULL, typeOfOrder, lot, _price, 5, 0, 0, "", signature*100+(_mark%100));

        return retval;
    }

    int SellAt(double _price, int _risk, int _mark=0)
    {
        double lot = (riskManagement == 0) ? _risk * lotMin : _risk * DynamicVolume();
        int typeOfOrder = (_price > Bid) ? OP_SELLLIMIT : OP_SELLSTOP;
        int retval = OrderSend(NULL, typeOfOrder, lot, _price, 5, 0, 0, "", signature*100+(_mark%100));

        return retval;
    }
    
    bool Close(int index, double _ratio = 1)
    {
        bool retval = false;
        
        if (OrderSelect(index, SELECT_BY_POS, MODE_TRADES))
            retval = OrderClose(OrderTicket(), _ratio * OrderLots(), (OrderType()==OP_BUY ? Bid : Ask), 5);
        
        return retval;
    }
    
    int FirstPosition(ulong _signature)
    {
        int i = 0;
        int retval = -1;
        int orders = OrdersTotal();
        
        do
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber()/100 == _signature)
                retval = i;
        } 
        while(retval < 0 && i < orders);
        
        return retval;
    }
    
    int NextPosition(ulong _signature, int i)
    {
        int retval = -1;
        int orders = OrdersTotal();

        i++;        
        do
        {
            if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber()/100 == _signature)
                retval = i;
        } 
        while(retval < 0 && i < orders);
        
        return retval;
    }
    
    double DynamicVolume()
    {
        double riskedMoney = AccountFreeMargin() * riskUnit;
        double marginRequired = MarketInfo(_Symbol,MODE_MARGINREQUIRED);
        double lot = riskedMoney / marginRequired;
        
        return NormalizeDouble(lot, 2);
    }
};