from pathlib import Path

import scrapy
from scrapy.http import headers

class WebNovelCrawler(scrapy.Spider):
    name = "webnovel"

    async def start(self):
        url = "https://www.webnovel.com/"
        headers = {
            "Host": "www.webnovel.com",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:138.0) Gecko/20100101 Firefox/138.0",
        }

        yield scrapy.Request(url=url, callback=self.parse, headers=headers)

    def parse(self, response):
        yield {
            "url": response.url
        }
