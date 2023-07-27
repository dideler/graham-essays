import sys
import csv
import os.path
import time
import urllib.request
from asyncio.log import logger

import feedparser
import html2text
import regex as re
import unidecode
from htmldate import find_date

"""
Download a collection of Paul Graham essays in EPUB & Markdown.
"""

rss = feedparser.parse("http://www.aaronsw.com/2002/feeds/pgessays.rss")
h = html2text.HTML2Text()
h.ignore_images = True
h.ignore_tables = True
h.escape_all = True
h.reference_links = True
h.mark_code = True

ART_NO = 1


def update_links_in_md(joined):
    matches = re.findall(b"\[\d+\]", joined)

    if not matches:
        return joined

    for match in set(matches):

        def update_links(match):
            counter[0] += 1
            note_name = f"{title}_note{note_number}"
            if counter[0] == 1:
                return bytes(f"[{note_number}](#{note_name})", "utf-8")
            elif counter[0] == 2:
                return bytes(f"<a name={note_name}>[{note_number}]</a>", "utf-8")

        counter = [0]

        note_number = int(match.decode().strip("[]"))
        match_regex = match.replace(b"[", b"\[").replace(b"]", b"\]")

        joined = re.sub(match_regex, update_links, joined)

    return joined


# The RSS feed from aaronsw.com gives incorrect links for articles not hosted on paulgraham.com
# e.g.: "http://www.paulgraham.com/https://sep.turbifycdn.com/ty/cdn/paulgraham/acl2.txt?t=1689517705&amp;"
def clean_rss_link(link):
    return link[link.rfind("http") :]


csv_data = [["Article no.", "Title", "Date", "URL"]]
failed_fetches = []

for entry in reversed(rss.entries):
    URL = clean_rss_link(entry["link"])
    TITLE = entry["title"]
    DATE = find_date(URL)

    try:
        with urllib.request.urlopen(URL) as website:
            content_type = website.headers["Content-Type"]
            content = website.read().decode("unicode_escape", "utf-8")

            title = "_".join(TITLE.split(" ")).lower()
            title = re.sub(r"[\W\s]+", "", title)

            with open(f"./essays/{ART_NO:03}_{title}.md", "wb+") as file:
                file.write(f"# {ART_NO:03} {TITLE}\n\n".encode())

                if "text/html" in content_type:
                    content = h.handle(content)
                    content = content.replace("[](index.html)  \n  \n", "")
                    content = [
                        (
                            p.replace("\n", " ")
                            if re.match(
                                r"^[\p{Z}\s]*(?:[^\p{Z}\s][\p{Z}\s]*){5,100}$", p
                            )
                            else "\n" + p + "\n"
                        )
                        for p in content.split("\n")
                    ]
                    content = " ".join(content).encode()
                    content = update_links_in_md(content)
                else:
                    content = content.encode()

                file.write(content)
                csv_data.append([ART_NO, TITLE, DATE, URL])
                print(f"✅ {ART_NO:03} {TITLE}")

    except Exception as e:
        print(f"❌ {ART_NO:03} {TITLE}, ({e})")
        failed_fetches.append((ART_NO, TITLE, URL))

    ART_NO += 1
    time.sleep(0.05)  # half sec/article is ~2min, be nice with servers!

with open("essays.csv", "w", newline="") as csv_file:
    csvwriter = csv.writer(csv_file)
    csvwriter.writerows(csv_data)

if failed_fetches:
    print("Failed to fetch essays:", file=sys.stderr)
    max_widths = [max(len(str(item[i])) for item in failed_fetches) for i in range(3)]
    for no, title, link in failed_fetches:
        print(f"{no:<{max_widths[0]}} {title:<{max_widths[1]}} {link:<{max_widths[2]}}")
    sys.exit(1)
