
import pandas as pd
import numpy as np
import requests
from datetime import datetime, timedelta

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
    df["high_adr"] = df.high.rolling(nADR).mean()
    df["low_adr"] = df.low.rolling(nADR).mean()

    df = df.reset_index(drop=True)
    return df


def calculate_pfh(row, df):
    adr_goal = row["high"] - row["adr"]

    try:
        if row["close"] < adr_goal and row["high"] > df.iloc[row.name+1]["high"] and row["high"] > df.iloc[row.name+2]["high"]:
            return row["high"]
    except:
        pass

    try:
        if row["close"] > adr_goal:
            for i in range(5):
                if df.iloc[i+row.name]["open"] > adr_goal:
                    continue

                if row["high"] == df.iloc[row.name:row.name+i+1]["high"].max():
                    for j in range(10):
                        f = row.name - j
                        if f<1:
                            return np.nan
                        if df.iloc[f]["close"] > adr_goal:
                            continue
                        if row["high"] == df.iloc[f:row.name+1]["high"].max():
                            return row["high"]
    except:
        pass
    return np.nan


def calculate_pfl(row, df):
    adr_goal = row["low"] + row["adr"]

    try:
        if row["close"] > adr_goal and row["low"] < df.iloc[row.name+1]["low"] and row["low"] < df.iloc[row.name+2]["low"]:
            return row["low"]
    except:
        pass

    try:
        if row["close"] < adr_goal:
            for i in range(5):
                if df.iloc[i+row.name]["open"] < adr_goal:
                    continue

                if row["low"] == df.iloc[row.name:row.name+i+1]["low"].min():
                    for j in range(10):
                        f = row.name - j
                        if f<1:
                            return np.nan
                        if df.iloc[f]["close"] < adr_goal:
                            continue
                        if row["low"] == df.iloc[f:row.name+1]["low"].min():
                            return row["low"]
    except:
        pass

    return np.nan


def calculate_distance(row, df, lastPrice, direction):
    nowadr = row["adr"]
    if direction == "high":
        if str(row["pfh"])!='nan' and nowadr != 0:
            if row["high"] == df.iloc[0:row.name+1]["high"].max():
                if row["pfh"] > lastPrice:
                    return round((row["pfh"]-lastPrice)/nowadr, 2)

    if direction == "low":
        if str(row["pfl"])!='nan' and nowadr != 0:
            if row["low"] == df.iloc[0:row.name+1]["low"].min():
                if row["pfh"] < lastPrice:
                    return round((lastPrice-row["pfl"])/nowadr, 2)

    return 0


def get_pfh_pfl(df):
    symbol = df.iloc[0]["symbol"]
    r = requests.get(f"https://finnhub.io/api/v1/quote?symbol={symbol}&token={config.token}").json()
    lastPrice = r["c"]
    df["adr"] = df["high_adr"] - df["low_adr"]
    df["pfh"] = df.apply(lambda row: calculate_pfh(row, df), axis=1)
    df["pfl"] = df.apply(lambda row: calculate_pfl(row, df), axis=1)
    df["d_high"] = df.apply(lambda row: calculate_distance(row, df, lastPrice, "high"), axis=1)
    df["d_low"] = df.apply(lambda row: calculate_distance(row, df, lastPrice, "low"), axis=1)

    try:
        pfh_idx = list(df[df["d_high"]!=0].index)[0]
    except:
        pfh_idx = -1
    try:
        pfl_idx = list(df[df["d_low"]!=0].index)[0]
    except:
        pfl_idx = -1
    if pfh_idx > pfl_idx and pfl_idx > 0:
        return df, pfl_idx, "PFL"
    if pfh_idx > pfl_idx and pfl_idx < 0:
        return df, pfh_idx, "PFH"
    if pfh_idx > 0 and pfl_idx > pfh_idx:
        return df, pfh_idx, "PFH"
    if pfh_idx < 0 and pfl_idx > pfh_idx:
        return df, pfl_idx, "PFL"
    if pfh_idx == pfl_idx and pfl_idx>0:
        if df.iloc[pfh_idx]["d_high"] >= df.iloc[pfh_idx]["d_low"]:
            return df, pfh_idx, "PFH"
        else:
            return df, pfh_idx, "PFL"
    return df, 0, "None"


def get_minutely_datetime(df, nday, direction):
    from_date = df.iloc[nday]["date"]
    to_date = from_date + timedelta(days = 1)
    _from = int(round(from_date.timestamp()))
    _to = int(round(to_date.timestamp()))
    symbol = df.iloc[0]["symbol"]
    
    df_1min = get_bars(symbol=symbol, resolution='1', _from=_from, _to=_to)

    if direction == "PFH":
        idx = "high"
    elif direction == "PFL":
        idx = "low"
    else:
        return None

    target = df.iloc[nday][idx]
    for i in range(df_1min.shape[0]):
        current = df_1min.iloc[i][idx]
        if current == target:
            return df_1min.iloc[i]["date"]

    return None


def main():
    lookback = config.nDays
    to_date = datetime.now()
    from_date = datetime.now() - timedelta(days = lookback*2)
    nADR = config.nADR

    _to = int(round(to_date.timestamp()))
    _from = int(round(from_date.timestamp()))
    symbol = config.symbol
    resolution = config.resolution

    df = get_bars(symbol=symbol, resolution=resolution, _from=_from, _to=_to)
    df = adr_indicator(df, nADR)
    df = df.dropna().sort_values("date", ascending=False).reset_index(drop=True)
    df, nday, direction = get_pfh_pfl(df)
    _datetime = get_minutely_datetime(df, nday, direction)
    if not _datetime:
        _datetime = df.iloc[nday]["date"]

    pfh = df.iloc[nday]["d_high"]
    pfl = df.iloc[nday]["d_low"]
    _date = df.iloc[0]["date"].date()
    print("\n\n")
    print(f"{symbol}|{_date} - {nday}|{direction} - {pfh}xADR|{pfl}xADR")
    print(f"Exact time: {_datetime}")

main()
