# classify/apps.py
import os
import torch
import torchvision.transforms as transforms
from pathlib import Path
from django.apps import AppConfig


CLASS_NAMES = {0: "KHALAS", 1: "RAZEEZ", 2: "SHISHI"}
DEFAULT_MODEL_FILENAME = "convnext_tiny_best_on_val_no_kfold_aug_convnext_tiny.pth"
# Default to <repo>/Saaf/convnext_tiny_best_on_val_no_kfold_aug_convnext_tiny.pth,
# while still allowing override via MODEL_PATH in environment.
DEFAULT_MODEL_PATH = Path(__file__).resolve().parents[2] / DEFAULT_MODEL_FILENAME
MODEL_PATH = Path(os.environ.get("MODEL_PATH", str(DEFAULT_MODEL_PATH)))

_model  = None
_device = None
_transform = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]),
])


def get_model():
    return _model

def get_device():
    return _device

def get_transform():
    return _transform

def get_class_names():
    return CLASS_NAMES


class ClassifyConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'classify'

    def ready(self):
        global _model, _device
        import timm
        try:
            _device = (
                torch.device("cuda") if torch.cuda.is_available()
                else torch.device("mps") if torch.backends.mps.is_available()
                else torch.device("cpu")
            )
            _model = timm.create_model("convnext_tiny", pretrained=False, num_classes=len(CLASS_NAMES))
            # Use weights_only when available to avoid unpickling arbitrary objects.
            try:
                checkpoint = torch.load(MODEL_PATH, map_location=_device, weights_only=True)
            except TypeError:
                checkpoint = torch.load(MODEL_PATH, map_location=_device)
            state_dict = checkpoint.get("model_state", checkpoint)
            _model.load_state_dict(state_dict)
            _model.to(_device)
            _model.eval()
            print(f"[classify] Model loaded on {_device} from {MODEL_PATH}")
        except Exception as e:
            print(f"[classify] WARNING: Model not loaded — {e}")
            _model = None
