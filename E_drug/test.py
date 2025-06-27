import requests
import ssl
import time
import urllib3
import xml.etree.ElementTree as ET
from urllib3.poolmanager import PoolManager
from requests.adapters import HTTPAdapter

class TLSAdapter(HTTPAdapter):
    def init_poolmanager(self, *args, **kwargs):
        ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        kwargs['ssl_context'] = ctx
        return super().init_poolmanager(*args, **kwargs)

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

session = requests.Session()
session.mount("https://", TLSAdapter())

API_KEY = "RfNTM2YiUbC4lyEg/QIK/EUBTWqhHhH+N1t7WO9ABkkoqflZsKkjUsC48a5WOtVfq2ttOMRb2s5KS838/GTBpQ=="  # 디코딩된 키 사용
BASE_URL = "http://apis.data.go.kr/1471000/DrbEasyDrugInfoService/getDrbEasyDrugList"

all_items = []
page = 1

while True:
    params = {
        "serviceKey": API_KEY,
        "pageNo": page,
        "numOfRows": 100,
        "type": "xml"
    }

    try:
        response = session.get(BASE_URL, params=params, verify=False, timeout=5)
        response.raise_for_status()
        root = ET.fromstring(response.content)
        items = root.findall(".//item")
    except Exception as e:
        print(f"[!] 요청 실패: {e}")
        break

    if not items:
        break

    for item in items:
        name = item.findtext("itemName")
        if name:
            all_items.append(name.strip())

    print(f"✅ Page {page}: {len(items)}개 수집됨")
    page += 1
    time.sleep(0.2)

unique_items = sorted(set(all_items))
with open("item_names.txt", "w", encoding="utf-8") as f:
    for name in unique_items:
        f.write(name + "\n")

print(f"\n🎉 총 {len(unique_items)}개의 약 이름 저장 완료 → item_names.txt")
