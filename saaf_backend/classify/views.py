# classify/views.py
import os
import requests
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

HF_CLASSIFY_URL = os.environ.get(
    "HF_CLASSIFY_URL",
    "https://mutairi1-palmtreeclassifer.hf.space/classify-tree",
)
HF_TIMEOUT_SECONDS = int(os.environ.get("HF_TIMEOUT_SECONDS", "60"))


def _normalize_hf_response(payload: dict) -> dict:
    """
    Normalize Hugging Face response into app contract:
    {predicted_type, confidence_score}
    """
    predicted = (
        payload.get("predicted_type")
        or payload.get("prediction")
        or payload.get("predicted_class")
        or payload.get("class")
        or payload.get("label")
        or "Unknown"
    )

    confidence = (
        payload.get("confidence_score")
        or payload.get("confidence")
        or payload.get("score")
        or 0.0
    )
    try:
        confidence = float(confidence)
    except (TypeError, ValueError):
        confidence = 0.0

    return {
        "predicted_type": str(predicted),
        "confidence_score": round(confidence, 4),
    }


@api_view(['POST'])
@permission_classes([AllowAny])
@parser_classes([MultiPartParser])
def classify(request):
    image_file = request.FILES.get('image')
    if not image_file:
        return Response({'error': 'No image provided'}, status=400)

    try:
        files = {
            "file": (image_file.name, image_file.read(), image_file.content_type or "application/octet-stream"),
        }
        headers = {"accept": "application/json"}
        hf_res = requests.post(
            HF_CLASSIFY_URL,
            headers=headers,
            files=files,
            timeout=HF_TIMEOUT_SECONDS,
        )
        if hf_res.status_code >= 400:
            return Response(
                {
                    "error": "Hugging Face classification failed",
                    "upstream_status": hf_res.status_code,
                    "upstream_body": hf_res.text[:500],
                },
                status=502,
            )

        payload = hf_res.json()
        if isinstance(payload, dict):
            return Response(_normalize_hf_response(payload), status=200)
        return Response({"error": "Invalid response format from Hugging Face"}, status=502)
    except requests.Timeout:
        return Response({'error': 'Classification timed out'}, status=504)
    except requests.RequestException as e:
        return Response({'error': f'Classification request failed: {e}'}, status=502)
    except Exception as e:
        return Response({'error': str(e)}, status=500)
