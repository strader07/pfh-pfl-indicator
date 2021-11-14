import numpy as np
import pandas as pd

class Instrument:
    def __init__(self, df):
        self.odf = df
        self.df = df
        self._validate_df()

    ohlc = {'open', 'high', 'low', 'close'}

    UPTREND_CONTINUAL = 0
    UPTREND_REVERSAL = 1
    DOWNTREND_CONTINUAL = 2
    DOWNTREND_REVERSAL = 3

    def _validate_df(self):
        if not self.ohlc.issubset(self.df.columns):
            raise ValueError('DataFrame should have OHLC {} columns'.format(self.ohlc))


class PnF(Instrument):
    box_size = 1
    reversal_size = 3

    @property
    def brick_size(self):
        return self.box_size

    def get_state(self, uptrend_p1, bricks):
        state = None
        if uptrend_p1 and bricks > 0:
            state = self.UPTREND_CONTINUAL
        elif uptrend_p1 and bricks * -1 >= self.reversal_size:
            state = self.UPTREND_REVERSAL
        elif not uptrend_p1 and bricks < 0:
            state = self.DOWNTREND_CONTINUAL
        elif not uptrend_p1 and bricks >= self.reversal_size:
            state = self.DOWNTREND_REVERSAL
        return state

    def roundit(self, x, base=5):
        return int(base * round(float(x)/base))

    def get_ohlc_data(self, source='close'):
        source = source.lower()
        box_size = self.box_size
        data = self.df.itertuples()

        uptrend_p1 = True
        if source == 'close':
            open_ = self.df.loc[0]['open']
            close = self.roundit(open_, base=self.box_size)
            pnf_data = [[0, 0, 0, 0, close, True]]
        else:
            low = self.df.loc[0]['low']
            open_ = self.roundit(low, base=self.box_size)
            pnf_data = [[0, 0, open_, open_, open_, True]]

        for row in data:
            date = row.date
            close = row.close

            open_p1 = pnf_data[-1][1]
            high_p1 = pnf_data[-1][2]
            low_p1 = pnf_data[-1][3]
            close_p1 = pnf_data[-1][4]

            if source == 'close':
                bricks = int((close - close_p1) / box_size)
            elif source == 'hl':
                if uptrend_p1:
                    bricks = int((row.high - high_p1) / box_size)
                else:
                    bricks = int((row.low - low_p1) / box_size)
            state = self.get_state(uptrend_p1, bricks)

            if state is None:
                continue

            day_data = []

            if state == self.UPTREND_CONTINUAL:
                for i in range(bricks):
                    r = [date, close_p1, close_p1 + box_size, close_p1, close_p1 + box_size, uptrend_p1]
                    day_data.append(r)
                    close_p1 += box_size
            elif state == self.UPTREND_REVERSAL:
                uptrend_p1 = not uptrend_p1
                bricks += 1
                close_p1 -= box_size
                for i in range(abs(bricks)):
                    r = [date, close_p1, close_p1, close_p1 - box_size, close_p1 - box_size, uptrend_p1]
                    day_data.append(r)
                    close_p1 -= box_size
            elif state == self.DOWNTREND_CONTINUAL:
                for i in range(abs(bricks)):
                    r = [date, close_p1, close_p1, close_p1 - box_size, close_p1 - box_size, uptrend_p1]
                    day_data.append(r)
                    close_p1 -= box_size
            elif state == self.DOWNTREND_REVERSAL:
                uptrend_p1 = not uptrend_p1
                bricks -= 1
                close_p1 += box_size
                for i in range(abs(bricks)):
                    r = [date, close_p1, close_p1 + box_size, close_p1, close_p1 + box_size, uptrend_p1]
                    day_data.append(r)
                    close_p1 += box_size

            pnf_data.extend(day_data)

        self.cdf = pd.DataFrame(pnf_data[1:])
        if self.cdf.shape[0] < 1:
            return self.cdf
        self.cdf.columns = ['date', 'open', 'high', 'low', 'close', 'trend']
        return self.cdf