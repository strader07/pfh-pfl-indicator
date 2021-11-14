
Days_count = 40 # number of bars
nADR = 5 # ATR lookback

# token = "bs1ijlvrh5r8bqohdl90"
token = "brckmifrh5rap841m69g" # finnhub API key

# PnF configurations
boxSize = 0.01 # this value is going to be the difference between high and low of the pnf bars
               # so please make sure you define so it can meet the minimum variance.
               # for example, in EUR_USD, if we set boxSize = 1, this is not going to work
               # because EUR_USD's "high" is never going to be greater than "low" by 1.
               # this is what we consider when setting configurations for PnF
reversalSize = 3
nDays = 50 # number of days you want to look back to pull candles from finnhub
pnfSource = "close" # 'close' or 'hl' (to use high and low prices as source for pnf calculations)

assetType = "forex" # stock, crypto, forex
symbol = "OANDA:AUD_NZD" # correct symbol depending on exchange and asset type
resolution = "D" # 1, 5, 15, 30, 60, D, W, M

pairsUrl = "https://beta.marketmakersmethod.com/api/pair-pool/"
postUrl = "https://beta.marketmakersmethod.com/api/pair-pool/update"

num_cores = 32
nsleep = 5