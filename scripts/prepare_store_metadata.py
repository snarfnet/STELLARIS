import hashlib
import os
import time
from pathlib import Path

import jwt
import requests


KEY_ID = os.environ.get("ASC_KEY_ID", "WDXGY9WX55")
ISSUER_ID = os.environ.get("ASC_ISSUER_ID", "2be0734f-943a-4d61-9dc9-5d9045c46fec")
P8_PATH = Path(os.environ.get("ASC_P8_PATH", r"C:\Users\Windows\.appstoreconnect\private_keys\AuthKey_WDXGY9WX55.p8"))
APP_ID = os.environ.get("APP_ID", "6770211035")
APP_VERSION = os.environ.get("APP_VERSION", "1.0")
SCREENSHOT_DIR = Path("MarketingAssets/Screenshots")

REVIEW_CONTACT = {
    "contactFirstName": "Tokyo",
    "contactLastName": "Nasu",
    "contactEmail": "tokyonasu@yahoo.co.jp",
    "contactPhone": "+81 80-2368-9194",
}

VERSION_META = {
    "description": (
        "STELLARISは、音作り、演奏、シーケンスを1つの画面で扱えるシンセサイザーアプリです。\n\n"
        "波形、フィルター、エンベロープ、LFO、XYパッド、ステップシーケンサーを使い、"
        "すばやく音を作ってそのまま演奏できます。暗いステージのようなUIで、ライブ感のある操作に集中できます。"
    ),
    "keywords": "シンセサイザー,音楽制作,演奏,シーケンサー,音作り,電子音楽,鍵盤,LFO",
    "promotionalText": "音作り、演奏、シーケンスを1つのシンセ空間で。",
    "supportUrl": "https://github.com/snarfnet/STELLARIS",
}

APP_INFO_META = {
    "name": "STELLARIS",
    "subtitle": "音作りと演奏のシンセ",
    "privacyPolicyUrl": "https://github.com/snarfnet/STELLARIS/blob/main/PRIVACY.md",
}

AGE_RATING = {
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gambling": False,
    "gamblingSimulated": "NONE",
    "gunsOrOtherWeapons": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "unrestrictedWebAccess": False,
    "advertising": True,
    "messagingAndChat": False,
    "userGeneratedContent": False,
    "lootBox": False,
    "healthOrWellnessTopics": False,
    "parentalControls": False,
    "ageAssurance": False,
}


private_key = P8_PATH.read_text(encoding="utf-8")


def token():
    now = int(time.time())
    return jwt.encode(
        {"iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": KEY_ID},
    )


def request(method, path, **kwargs):
    for _ in range(6):
        response = requests.request(
            method,
            f"https://api.appstoreconnect.apple.com/v1{path}",
            headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"},
            timeout=120,
            **kwargs,
        )
        if response.status_code not in (401, 429, 500, 502, 503, 504):
            return response
        time.sleep(15)
    return response


def must(response, action):
    if response.status_code not in (200, 201, 202, 204):
        raise RuntimeError(f"{action} failed: {response.status_code} {response.text[:1200]}")
    if response.text:
        return response.json()
    return {}


def list_all(path):
    items = []
    next_path = path
    while next_path:
        body = must(request("GET", next_path), f"GET {next_path}")
        items.extend(body.get("data", []))
        next_url = body.get("links", {}).get("next")
        next_path = next_url.split("/v1", 1)[1] if next_url else None
    return items


def get_version():
    versions = list_all(f"/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=200")
    for version in versions:
        if version.get("attributes", {}).get("versionString") == APP_VERSION:
            return version["id"]
    raise RuntimeError(f"Version {APP_VERSION} was not found")


def patch_app_basics():
    must(
        request(
            "PATCH",
            f"/apps/{APP_ID}",
            json={
                "data": {
                    "type": "apps",
                    "id": APP_ID,
                    "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"},
                }
            },
        ),
        "Content rights",
    )


def patch_app_info():
    app_infos = list_all(f"/apps/{APP_ID}/appInfos?limit=10")
    if not app_infos:
        raise RuntimeError("No app info found")
    app_info_id = app_infos[0]["id"]
    must(
        request(
            "PATCH",
            f"/appInfos/{app_info_id}",
            json={
                "data": {
                    "type": "appInfos",
                    "id": app_info_id,
                    "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": "MUSIC"}}},
                }
            },
        ),
        "Primary category",
    )
    return app_info_id


def patch_app_info_localization(app_info_id):
    localizations = list_all(f"/appInfos/{app_info_id}/appInfoLocalizations?limit=200")
    loc_id = None
    for loc in localizations:
        if loc["attributes"]["locale"] == "ja":
            loc_id = loc["id"]
            break
    if not loc_id:
        body = must(
            request(
                "POST",
                "/appInfoLocalizations",
                json={
                    "data": {
                        "type": "appInfoLocalizations",
                        "attributes": {"locale": "ja", **APP_INFO_META},
                        "relationships": {"appInfo": {"data": {"type": "appInfos", "id": app_info_id}}},
                    }
                },
            ),
            "App info localization create",
        )
        loc_id = body["data"]["id"]
    must(
        request(
            "PATCH",
            f"/appInfoLocalizations/{loc_id}",
            json={
                "data": {
                    "type": "appInfoLocalizations",
                    "id": loc_id,
                    "attributes": APP_INFO_META,
                }
            },
        ),
        "App info localization",
    )


def patch_age_rating(app_info_id):
    body = must(request("GET", f"/appInfos/{app_info_id}/ageRatingDeclaration"), "Age rating lookup")
    if not body.get("data"):
        raise RuntimeError("No age rating declaration found")
    age_id = body["data"]["id"]
    must(
        request(
            "PATCH",
            f"/ageRatingDeclarations/{age_id}",
            json={"data": {"type": "ageRatingDeclarations", "id": age_id, "attributes": AGE_RATING}},
        ),
        "Age rating",
    )


def patch_version(version_id):
    must(
        request(
            "PATCH",
            f"/appStoreVersions/{version_id}",
            json={
                "data": {
                    "type": "appStoreVersions",
                    "id": version_id,
                    "attributes": {"copyright": "2026 Tokyo Nasu", "usesIdfa": True},
                }
            },
        ),
        "Version fields",
    )


def patch_build_encryption():
    builds = list_all(f"/builds?filter[app]={APP_ID}&sort=-uploadedDate&limit=10")
    for build in builds:
        attrs = build.get("attributes", {})
        if attrs.get("processingState") == "VALID":
            build_id = build["id"]
            response = request(
                "PATCH",
                f"/builds/{build_id}",
                json={
                    "data": {
                        "type": "builds",
                        "id": build_id,
                        "attributes": {"usesNonExemptEncryption": False},
                    }
                },
            )
            if response.status_code not in (200, 201, 202, 204, 409):
                raise RuntimeError(f"Build encryption failed: {response.status_code} {response.text[:1200]}")
            return build_id
    raise RuntimeError("No valid build found")


def ensure_free_price():
    body = must(
        request("GET", f"/apps/{APP_ID}/appPricePoints?filter[territory]=USA&limit=1"),
        "Free price point lookup",
    )
    points = body.get("data", [])
    if not points:
        raise RuntimeError("No free price point found")
    local_id = "${manualPrice0}"
    response = request(
        "POST",
        "/appPriceSchedules",
        json={
            "data": {
                "type": "appPriceSchedules",
                "relationships": {
                    "app": {"data": {"type": "apps", "id": APP_ID}},
                    "baseTerritory": {"data": {"type": "territories", "id": "USA"}},
                    "manualPrices": {"data": [{"type": "appPrices", "id": local_id}]},
                },
            },
            "included": [
                {
                    "type": "appPrices",
                    "id": local_id,
                    "attributes": {"startDate": "2026-05-17"},
                    "relationships": {
                        "appPricePoint": {"data": {"type": "appPricePoints", "id": points[0]["id"]}}
                    },
                }
            ],
        },
    )
    if response.status_code not in (200, 201, 202, 409):
        raise RuntimeError(f"Free price failed: {response.status_code} {response.text[:1200]}")


def cancel_open_review_submissions():
    for state in ("READY_FOR_REVIEW", "COMPLETING", "UNRESOLVED_ISSUES", "WAITING_FOR_REVIEW"):
        try:
            submissions = list_all(f"/apps/{APP_ID}/reviewSubmissions?filter[state]={state}&limit=200")
        except RuntimeError:
            continue
        for submission in submissions:
            request(
                "PATCH",
                f"/reviewSubmissions/{submission['id']}",
                json={
                    "data": {
                        "type": "reviewSubmissions",
                        "id": submission["id"],
                        "attributes": {"canceled": True},
                    }
                },
            )


def ensure_localization(version_id):
    localizations = list_all(f"/appStoreVersions/{version_id}/appStoreVersionLocalizations?limit=200")
    for loc in localizations:
        if loc["attributes"]["locale"] == "ja":
            return loc["id"]
    body = must(
        request(
            "POST",
            "/appStoreVersionLocalizations",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "attributes": {"locale": "ja"},
                    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
                }
            },
        ),
        "Create Japanese localization",
    )
    return body["data"]["id"]


def patch_localization(localization_id):
    must(
        request(
            "PATCH",
            f"/appStoreVersionLocalizations/{localization_id}",
            json={
                "data": {
                    "type": "appStoreVersionLocalizations",
                    "id": localization_id,
                    "attributes": VERSION_META,
                }
            },
        ),
        "Version localization",
    )


def patch_review_detail(version_id):
    attrs = {
        **REVIEW_CONTACT,
        "demoAccountRequired": False,
        "demoAccountName": "",
        "demoAccountPassword": "",
        "notes": (
            "STELLARIS is a standalone synthesizer app. No login is required. "
            "The app includes AdMob banner ads and uses the uploaded build for version 1.0."
        ),
    }
    response = request("GET", f"/appStoreVersions/{version_id}/appStoreReviewDetail")
    body = must(response, "Review detail lookup")
    if body.get("data"):
        detail_id = body["data"]["id"]
        must(
            request(
                "PATCH",
                f"/appStoreReviewDetails/{detail_id}",
                json={"data": {"type": "appStoreReviewDetails", "id": detail_id, "attributes": attrs}},
            ),
            "Review detail update",
        )
        return
    must(
        request(
            "POST",
            "/appStoreReviewDetails",
            json={
                "data": {
                    "type": "appStoreReviewDetails",
                    "attributes": attrs,
                    "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
                }
            },
        ),
        "Review detail create",
    )


def screenshot_set(localization_id):
    sets = list_all(f"/appStoreVersionLocalizations/{localization_id}/appScreenshotSets?limit=200")
    for item in sets:
        if item["attributes"]["screenshotDisplayType"] == "APP_IPHONE_65":
            return item["id"]
    body = must(
        request(
            "POST",
            "/appScreenshotSets",
            json={
                "data": {
                    "type": "appScreenshotSets",
                    "attributes": {"screenshotDisplayType": "APP_IPHONE_65"},
                    "relationships": {
                        "appStoreVersionLocalization": {
                            "data": {"type": "appStoreVersionLocalizations", "id": localization_id}
                        }
                    },
                }
            },
        ),
        "Screenshot set create",
    )
    return body["data"]["id"]


def clear_screenshots(set_id):
    for item in list_all(f"/appScreenshotSets/{set_id}/appScreenshots?limit=200"):
        must(request("DELETE", f"/appScreenshots/{item['id']}"), "Screenshot delete")


def upload_screenshot(set_id, path):
    data = path.read_bytes()
    body = must(
        request(
            "POST",
            "/appScreenshots",
            json={
                "data": {
                    "type": "appScreenshots",
                    "attributes": {"fileName": path.name, "fileSize": len(data)},
                    "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}},
                }
            },
        ),
        f"Screenshot create {path.name}",
    )
    screenshot = body["data"]
    for operation in screenshot["attributes"]["uploadOperations"]:
        headers = {item["name"]: item["value"] for item in operation["requestHeaders"]}
        start = operation["offset"]
        end = start + operation["length"]
        requests.put(operation["url"], headers=headers, data=data[start:end], timeout=120)
    checksum = hashlib.md5(data).hexdigest()
    must(
        request(
            "PATCH",
            f"/appScreenshots/{screenshot['id']}",
            json={
                "data": {
                    "type": "appScreenshots",
                    "id": screenshot["id"],
                    "attributes": {"uploaded": True, "sourceFileChecksum": checksum},
                }
            },
        ),
        f"Screenshot finish {path.name}",
    )


def upload_screenshots(localization_id):
    files = sorted(SCREENSHOT_DIR.glob("iphone65_*.png"))
    if not files:
        raise RuntimeError("No APP_IPHONE_65 screenshots found")
    set_id = screenshot_set(localization_id)
    clear_screenshots(set_id)
    for path in files:
        upload_screenshot(set_id, path)
        print(f"Uploaded {path.name}")


def main():
    version_id = get_version()
    patch_app_basics()
    app_info_id = patch_app_info()
    patch_app_info_localization(app_info_id)
    patch_age_rating(app_info_id)
    patch_version(version_id)
    patch_build_encryption()
    ensure_free_price()
    cancel_open_review_submissions()
    loc_id = ensure_localization(version_id)
    patch_localization(loc_id)
    patch_review_detail(version_id)
    upload_screenshots(loc_id)
    print("App Store metadata and 6.5-inch screenshots are ready.")


if __name__ == "__main__":
    main()
