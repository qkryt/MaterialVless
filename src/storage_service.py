import os
import sys
import json
from typing import List, Tuple, Optional
from .models import SubscriptionModel, VlessNode, AppSettings

FILE_NAME = "material_vless_data.json"

class StorageService:
    @staticmethod
    def _get_candidate_paths() -> List[str]:
        paths = []
        if sys.platform == "win32":
            appdata = os.environ.get("APPDATA", "")
            if appdata:
                paths.append(os.path.join(appdata, "com.materialvless", "material_vless", FILE_NAME))
        paths.append(os.path.join(os.getcwd(), FILE_NAME))
        exe_dir = os.path.dirname(os.path.abspath(sys.argv[0]))
        paths.append(os.path.join(exe_dir, FILE_NAME))
        return paths

    @classmethod
    def load_data(cls) -> Tuple[List[SubscriptionModel], List[VlessNode], Optional[str], AppSettings]:
        for p in cls._get_candidate_paths():
            if os.path.isfile(p):
                try:
                    with open(p, "r", encoding="utf-8") as f:
                        data = json.load(f)

                    subs = [SubscriptionModel.from_dict(s) for s in data.get("subscriptions", [])]
                    nodes = [VlessNode.from_dict(n) for n in data.get("manualNodes", [])]
                    sel_id = data.get("selectedNodeId")

                    settings_dict = data.get("settings")
                    settings = AppSettings.from_dict(settings_dict) if settings_dict else AppSettings()

                    return subs, nodes, sel_id, settings
                except Exception:
                    pass

        return [], [], None, AppSettings()

    @classmethod
    def save_data(cls, subscriptions: List[SubscriptionModel], manual_nodes: List[VlessNode], selected_node_id: Optional[str], settings: AppSettings):
        data = {
            "version": 2,
            "appName": "MaterialVless",
            "edition": "Qt6",
            "selectedNodeId": selected_node_id,
            "subscriptions": [s.to_dict() for s in subscriptions],
            "manualNodes": [n.to_dict() for n in manual_nodes],
            "settings": settings.to_dict()
        }

        json_str = json.dumps(data, indent=2, ensure_ascii=False)

        for p in cls._get_candidate_paths():
            try:
                os.makedirs(os.path.dirname(p), exist_ok=True)
                with open(p, "w", encoding="utf-8") as f:
                    f.write(json_str)
            except Exception:
                pass
