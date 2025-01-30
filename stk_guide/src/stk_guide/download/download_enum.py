from enum import Enum, StrEnum


class RobinhoodEnum(StrEnum):
    SUMMARY = "summary"
    NEWS = "ratings"
    BUY = "num_buy_ratings"
    HOLD = "num_hold_ratings"
    SELL = "num_sell_ratings"
    PUBLISHED = "ratings_published_at"


class FinhubEnum(StrEnum):
    BUY = "buy"
    STRONG_BUY = "strongBuy"
    HOLD = "hold"
    SELL = "sell"
    STRONG_SELL = "strongSell"
    PUBLISHED = "period"


class TimeZone(StrEnum):
    DEFAULT = "America/New_York"
