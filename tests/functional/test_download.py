from stk_guide.download.downloader import FinhubRating, PriceHistory, RobinhoodRatings, StockInfo, StockOptions
from stk_guide.entities.options import Options
from stk_guide.entities.prices import Prices
from stk_guide.entities.rating import Rating


def test_price() -> None:
    test = PriceHistory("INTC", 0.1).download()
    assert isinstance(test, Prices)


def test_info() -> None:
    data = StockInfo("INTC").download()
    assert isinstance(data, dict)


def test_options() -> None:
    data = StockOptions("INTC").download()
    assert isinstance(data, Options)


def test_ratings() -> None:
    data = RobinhoodRatings("AAPL").download()
    assert isinstance(data, list)
    assert isinstance(data[0], Rating)
    data = FinhubRating("AAPL").download()
    assert isinstance(data, list)
    assert isinstance(data[0], Rating)
