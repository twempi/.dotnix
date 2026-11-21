import html
import json
import re
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

# Facebook answers 400 or an empty page unless the request looks like a browser navigation.
HEADERS = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.9",
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "none",
    "Sec-Fetch-User": "?1",
    "Upgrade-Insecure-Requests": "1",
}
# Search area: Northridge. OfferUp reads it from this cookie, else guesses from the IP.
LATITUDE, LONGITUDE = 34.2283, -118.5368
OFFERUP_LOCATION = urllib.parse.quote(json.dumps({
    "city": "Northridge", "state": "CA", "zipCode": "91324",
    "latitude": LATITUDE, "longitude": LONGITUDE, "source": "manual",
}))
RADIUS_MILES = 15
# Logged out, Facebook ignores the radius and has no Northridge page, so it covers greater LA.
FACEBOOK_CITY = "la"
# Broad terms; the agent filters out the noise they bring in.
QUERIES = ["laptop", "desktop", "gaming pc", "pc parts", "computer parts"]
CRAIGSLIST_CATEGORIES = ["sya", "syp"]  # computers, computer parts
SEEN = Path.home() / ".hermes/deals-seen.json"


def fetch(url, cookie=""):
    request = urllib.request.Request(url, headers={**HEADERS, "Cookie": cookie})
    return urllib.request.urlopen(request, timeout=30).read().decode()


def offerup(query):
    page = fetch("https://offerup.com/search?" + urllib.parse.urlencode({"q": query, "radius": RADIUS_MILES}), "ou.location=" + OFFERUP_LOCATION)
    data = json.loads(re.search(r'<script id="__NEXT_DATA__" type="application/json">(.*?)</script>', page, re.S).group(1))
    for tile in data["props"]["pageProps"]["searchFeedResponse"]["looseTiles"]:
        if listing := tile.get("listing"):
            yield ("https://offerup.com/item/detail/" + listing["listingId"],
                   listing["title"], "$" + str(listing["price"]), listing["locationName"])


def div_text(item, name):
    match = re.search(r'<div class="' + name + r'">\s*(.*?)\s*</div>', item, re.S)
    return html.unescape(match.group(1)) if match else "?"


def craigslist(category):
    params = urllib.parse.urlencode({"cat": category, "lat": LATITUDE, "lon": LONGITUDE, "search_distance": RADIUS_MILES})
    page = fetch("https://www.craigslist.org/search/area/losangeles?" + params)
    for item in page.split('<li class="cl-static-search-result"')[1:]:
        yield (re.search(r'href="([^"]+)"', item).group(1),
               div_text(item, "title"), div_text(item, "price"), div_text(item, "location"))


def find_listings(node, found):
    if isinstance(node, dict):
        if "marketplace_listing_title" in node:
            found[node["id"]] = node
        else:
            for value in node.values():
                find_listings(value, found)
    elif isinstance(node, list):
        for value in node:
            find_listings(value, found)


def facebook(path):
    page = fetch(f"https://www.facebook.com/marketplace/{FACEBOOK_CITY}/{path}")
    found = {}
    for blob in re.findall(r'<script type="application/json"[^>]*>(.*?)</script>', page, re.S):
        find_listings(json.loads(blob), found)
    # A blocked or changed page still returns 200, so an empty result is the only failure signal.
    if not found:
        raise ValueError("no listings on the page")
    for listing_id, listing in found.items():
        if not (listing.get("is_sold") or listing.get("is_pending")):
            place = (listing.get("location") or {}).get("reverse_geocode") or {}
            yield (f"https://www.facebook.com/marketplace/item/{listing_id}/",
                   listing["marketplace_listing_title"].replace("\n", " "),
                   listing["listing_price"]["formatted_amount"], place.get("city", "?"))


def slickdeals(_):
    feed = ET.fromstring(fetch("https://slickdeals.net/newsearch.php?mode=frontpage&searcharea=deals&searchin=first&rss=1"))
    for item in feed.iter("item"):
        # The price is in the title; the link's query string is only RSS tracking.
        yield item.findtext("link").split("?")[0], item.findtext("title"), "in title", "online"


sources = [(f"OfferUp '{q}'", offerup, q) for q in QUERIES]
sources += [(f"Facebook '{q}'", facebook, "search?" + urllib.parse.urlencode({"query": q, "sortBy": "creation_time_descend"})) for q in QUERIES]
# The computers category holds laptops, desktops and parts whatever their titles say.
sources += [("Facebook computers", facebook, "computers?sortBy=creation_time_descend")]
sources += [(f"Craigslist {c}", craigslist, c) for c in CRAIGSLIST_CATEGORIES]
sources += [("Slickdeals", slickdeals, None)]
listings = {}
for name, source, arg in sources:
    try:
        for url, *rest in source(arg):
            listings[url] = rest
    except Exception as error:
        print(f"SOURCE ERROR {name}: {error!r}")

seen = set(json.loads(SEEN.read_text())) if SEEN.exists() else set()
SEEN.write_text(json.dumps(sorted(seen | listings.keys())))
# Printing nothing makes Hermes skip the agent run.
for url, (title, price, location) in listings.items():
    if url not in seen:
        print(f"{price} | {title} | {location} | {url}")
