import os
import requests
from PIL import Image
from io import BytesIO

def download_and_resize():
    output_dir = "lib/src/assets/samples/"
    os.makedirs(output_dir, exist_ok=True)

    # Using more reliable placeholder sources for pet images to avoid 403 Forbidden
    # 128x128 resolution requested by the user
    urls = {
        "beagle.jpg": "https://placedog.net/128/128?id=1",
        "cat.jpg": "https://cataas.com/cat?width=128&height=128",
        "pug.jpg": "https://placedog.net/128/128?id=2",
        "cat2.jpg": "https://cataas.com/cat/says/hello?width=128&height=128",
        "dog2.jpg": "https://placedog.net/128/128?id=3",
        "cat3.jpg": "https://cataas.com/cat/orange?width=128&height=128"
    }

    headers = {'User-Agent': 'Mozilla/5.0'}

    print("Downloading 128x128 pet samples...")
    for name, url in urls.items():
        try:
            print(f"Fetching {name}...")
            response = requests.get(url, headers=headers, timeout=20)
            response.raise_for_status()

            img = Image.open(BytesIO(response.content))
            img = img.convert("RGB")
            img = img.resize((128, 128), Image.Resampling.LANCZOS)

            save_path = os.path.join(output_dir, name)
            img.save(save_path, "JPEG")
            print(f"Success: {name}")
        except Exception as e:
            print(f"Failed {name}: {e}")

if __name__ == "__main__":
    download_and_resize()
