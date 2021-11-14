
import pandas as pd
import numpy as np
import requests
from datetime import datetime, timedelta
import pnf_ind

import config


def get_bars(symbol="IBM", resolution='D', _from=1605543327, _to=1605629727):
    url = f"https://finnhub.io/api/v1/{config.assetType}/candle?symbol={symbol}&resolution={resolution}&from={_from}&to={_to}&token={config.token}"
    try:
        res = requests.get(url).json()
    except Exception as e:
        print(e)
        return pd.DataFrame()

    closePrices = res["c"]
    highPrices = res["h"]
    lowPrices = res["l"]
    openPrices = res["o"]
    dates = res["t"]
    symbols = [symbol]*len(closePrices)

    columns = ["symbol", "date", "open", "high", "low", "close"]
    df = pd.DataFrame(zip(symbols, dates, openPrices, highPrices, lowPrices, closePrices), columns=columns)
    df["date"] = pd.to_datetime(df["date"], unit="s")
    df = df.sort_values("date", ascending=True)

    return df


def adr_indicator(df, nADR=5):
    df["HighADR"] = df.high.rolling(nADR).mean()
    df["LowADR"] = df.low.rolling(nADR).mean()

    df = df.reset_index(drop=True)
    return df


def main():
    lookback = config.nDays
    to_date = datetime.now()
    from_date = datetime.now() - timedelta(days = lookback)

    _to = int(round(to_date.timestamp()))
    _from = int(round(from_date.timestamp()))
    symbol = config.symbol
    resolution = config.resolution

    df = get_bars(symbol=symbol, resolution=resolution, _from=_from, _to=_to)

    nADR = config.nADR
    df = adr_indicator(df, nADR)
    print("\n\n============= ADR calculations!\n")
    df.to_csv(f"{symbol}_ADR.csv", index=False)
    print(df)

    pnf = pnf_ind.PnF(df)
    pnf.box_size = config.boxSize
    pnf.reversal_size = config.reversalSize

    pnf_df = pnf.get_ohlc_data(source=config.pnfSource)
    print("\n============= PnF calculations!")
    if pnf_df.shape[0] < 1:
        print("\nNo PnF values found for the current configuration!")
        print("Please try to reset box size and make sure you pull enough historical candles.")
        exit()
    pnf_df["trend"] = pnf_df["trend"].apply(lambda row: "PFH" if row else "PFL")
    pnf_df.to_csv(f"{symbol}_PnF.csv", index=False)
    print('\n\nPnF box data - based on close column!')
    print(pnf_df.tail(30))

    print('\n\nLastest PnF values!')
    last_pf = pnf_df.iloc[-1]["trend"]
    pf = {}
    pf[last_pf] = []
    for i in range(pnf_df.shape[0]):
        if pnf_df.iloc[-1-i]["trend"] == last_pf:
            pf[last_pf].append(pnf_df.iloc[-1-i]["close"])
            continue
        break
    pf[last_pf].reverse()
    print(pf)

main()
