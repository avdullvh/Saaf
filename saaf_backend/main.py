import io
import torch
import torchvision.transforms as transforms
from PIL import Image
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import timm

# Provide the 3-class index-to-name mapping according to how you trained the ConvNeXt model.
# Modify this dictionary with the exact class names used in your dataset.
CLASS_NAMES = {
    0: "KHALAS",
    1: "RAZEEZ",
    2: "SHISHI" 
}

# The absolute path to your `.pth` model file
MODEL_PATH = "C:\Users\faris\Desktop\graduation project\SaafAPP\Saaf\convnext_tiny_best_on_val_no_kfold_aug_convnext_tiny.pth"

app = FastAPI(title="Palm Classification API")

# Add CORS middleware to allow requests from anywhere during development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables to hold the loaded model and device
model = None
device = None

@app.on_event("startup")
async def load_model():
    global model, device
    print("Loading model...")
    device = torch.device("cuda" if torch.cuda.is_available() else "mps" if torch.backends.mps.is_available() else "cpu")
    print(f"Using device: {device}")
    
    try:
        # Initialize ConvNeXt-Tiny architecture using timm
        # We assume the model was trained with len(CLASS_NAMES) output classes
        model = timm.create_model("convnext_tiny", pretrained=False, num_classes=len(CLASS_NAMES))
        
        # Load the saved checkpiont dictionary
        checkpoint = torch.load(MODEL_PATH, map_location=device)
        
        # Extract the model state specifically
        # (Based on error, keys are: "model_state", "class_to_idx", etc)
        if "model_state" in checkpoint:
            state_dict = checkpoint["model_state"]
        else:
            state_dict = checkpoint
            
        model.load_state_dict(state_dict)
        
        # Set the model to evaluation mode and move to device
        model.to(device)
        model.eval()
        print("Model loaded successfully.")
    except Exception as e:
        print(f"Error loading model: {e}")
        model = None

# Preprocessing transforms based on ImageNet standards (default for ConvNeXt)
transform_pipeline = transforms.Compose([
    transforms.Resize(256),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize(
        mean=[0.485, 0.456, 0.406],
        std=[0.229, 0.224, 0.225]
    ),
])

@app.post("/api/classify/")
async def classify_image(image: UploadFile = File(...)):
    if model is None:
        return {"error": "Model not loaded"}
        
    try:
        # Read image bytes and convert to PIL Image
        image_bytes = await image.read()
        pil_image = Image.open(io.BytesIO(image_bytes)).convert('RGB')
        
        # Apply preprocessing
        input_tensor = transform_pipeline(pil_image)
        # Add batch dimension: [1, 3, 224, 224]
        input_batch = input_tensor.unsqueeze(0).to(device)
        
        # Run inference
        with torch.no_grad():
            output = model(input_batch)
            
            # Apply softmax to get probabilities
            probabilities = torch.nn.functional.softmax(output[0], dim=0)
            
            # Get the predicted class index and score
            max_prob, predicted_idx = torch.max(probabilities, dim=0)
            conf_score = max_prob.item()
            class_idx = predicted_idx.item()
            
            # Map index to class name
            predicted_type = CLASS_NAMES.get(class_idx, f"Unknown Class {class_idx}")
            
            return {
                "predicted_type": predicted_type,
                "confidence_score": conf_score
            }
            
    except Exception as e:
        return {"error": str(e)}

@app.get("/")
def read_root():
    return {"status": "ok", "message": "Palm Classification Backend is running."}
