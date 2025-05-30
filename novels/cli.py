# Entry Point

import os
import sys
from .spiders.webnovel_crawler import WebNovelCrawler
from scrapy.crawler import CrawlerProcess
from scrapy.utils.project import get_project_settings

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

scraped_data = []

class SpiderWithCollector(WebNovelCrawler):
    def parse(self, response):
        for item in super().parse(response):
            scraped_data.append(item)
            yield item

def main():
    process = CrawlerProcess(get_project_settings())
    process.crawl(SpiderWithCollector)
    process.start()

    for item in scraped_data:
        print("Item:", item)
