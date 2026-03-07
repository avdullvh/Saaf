import torch
from torchvision.models import convnext_tiny

# Provide the 3-class index-to-name mapping according to how you trained the ConvNeXt model.
CLASS_NAMES = {
    0: "KHALAS",
    1: "RAZEEZ",
    2: "SHISHI" 
}

MODEL_PATH = "/Users/abdullah/Downloads/MarginOfError/convnext_tiny_best_on_val_no_kfold_aug_convnext_tiny.pth"
device = torch.device('cpu')
model = convnext_tiny(weights=None)
num_ftrs = model.classifier[2].in_features
model.classifier[2] = torch.nn.Linear(num_ftrs, len(CLASS_NAMES))

checkpoint = torch.load(MODEL_PATH, map_location=device)
if 'model_state' in checkpoint:
    state_dict = checkpoint['model_state']
else:
    state_dict = checkpoint

# The model was likely trained using timm, which has slightly different keys
# Let's see if we can load it directly via timm
print("Can we load standard dict?", len(state_dict.keys()))
