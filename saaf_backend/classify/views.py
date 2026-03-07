# classify/views.py
import io
import torch
from PIL import Image
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .apps import get_model, get_device, get_transform, get_class_names


@api_view(['POST'])
@permission_classes([AllowAny])
@parser_classes([MultiPartParser])
def classify(request):
    model     = get_model()
    device    = get_device()
    transform = get_transform()
    classes   = get_class_names()

    if model is None:
        return Response({'error': 'Model not loaded'}, status=503)

    image_file = request.FILES.get('image')
    if not image_file:
        return Response({'error': 'No image provided'}, status=400)

    try:
        img_bytes = image_file.read()
        pil_image = Image.open(io.BytesIO(img_bytes)).convert('RGB')
        tensor    = transform(pil_image).unsqueeze(0).to(device)

        with torch.no_grad():
            output = model(tensor)
            probs  = torch.nn.functional.softmax(output[0], dim=0)
            max_prob, pred_idx = torch.max(probs, dim=0)

        return Response({
            'predicted_type':   classes.get(pred_idx.item(), 'Unknown'),
            'confidence_score': round(max_prob.item(), 4),
        })
    except Exception as e:
        return Response({'error': str(e)}, status=500)
